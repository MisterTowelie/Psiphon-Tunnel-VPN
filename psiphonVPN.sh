#!/usr/bin/env bash

## Troubleshooting
# set -e -u -x

#
# Psiphon Labs 
# https://github.com/Psiphon-Labs/psiphon-labs.github.io
#
#
# Script auto install Psiphon Tunnel VPN (Only linux version) version Release Candidate binaries
#
# System Required: Debian9+, Ubuntu20+, Trisquel9+
#
# https://github.com/MisterTowelie/Psiphon-Tunnel-VPN
#
# Author scripts: MisterTowelie

############################################################################
#   VERSION HISTORY   ######################################################
############################################################################

# v1.0
# - Initial version.

# v1.1
# - add colors
# - add check linux OS
# - add check new version psiphon
# - code optimization

# v1.2
# - a directory is installed in which permanent files will be stored, in the same place as the program itself
# - add improving the reliability of obfuscation (-obfs4-distBias)

# v1.3
# - add check architecture x86/amd64
# - checking ports when entering for correctness, busy
# - checking whether VPN is running and running in the background
# - added the ability to stop the program (process)
# - code optimization

## Add alias to file .bashrc
# echo "alias psiphon='./psiphonVPN.sh'" >> ~/.bashrc
# source ~/.bashrc

readonly script_version="1.3"

readonly RED="\033[0;31m"
readonly GREEN="\033[0;32m"
readonly YELLOW="\033[0;33m"
readonly BOLD="\033[1m"
readonly NORM="\033[0m"
readonly INFO="${BOLD}${GREEN}[INFO]: $NORM"
readonly ERROR="${BOLD}${RED}[ERROR]: $NORM"
readonly WARNING="${BOLD}${YELLOW}[WARNING]: $NORM"
readonly HELP="${BOLD}${GREEN}[HELP]: $NORM"

readonly os="$(uname)"
readonly arch="$(uname -m)"
readonly supported_archs=("x86_64")
readonly supported_os=("Linux")
readonly psiphon_name="Psiphon Tunnel VPN"
readonly psiphon_dir="$HOME/PsiphonVPN"
readonly psiphon_name_file="psiphon-tunnel-core-x86_64"
readonly psiphon_path="$psiphon_dir/$psiphon_name_file"
readonly psiphon_config="$psiphon_dir/config.json"
readonly psiphon_log="$psiphon_dir/psiphon-tunnel.log"
readonly psiphon_url="https://github.com/Psiphon-Labs/psiphon-tunnel-core-binaries/raw/master/linux/psiphon-tunnel-core-x86_64"
readonly psiphon_url_commit="https://api.github.com/repos/Psiphon-Labs/psiphon-tunnel-core-binaries/commits"
readonly level_msg=("$ERROR" "$WARNING" "$INFO" "$HELP")
readonly msg_DB=("The file $psiphon_name or its configuration file was not found."
        "Usage: ./$(basename "$0") install | uninstall | update | start | stop | port | help")
psiphon_local_commit=''
psiphon_remove_commit=''
action=''
pid=''

if [[ ! " ${supported_os[*]} " =~ $os ]]; then
    echo -e "${level_msg[0]}""This ($os) operating system is not supported." >&2
    exit 1
fi

if [[ ! " ${supported_archs[*]} " =~ $arch ]]; then
    echo -e "${level_msg[0]}""This ($arch) CPU architecture is not supported." >&2
    exit 1
fi

function check_update_psiphon(){
    psiphon_local_commit="$("${psiphon_path}" --version | grep "Revision:" | head -1 | cut -d : -f 2 | tr -d " ")"
    psiphon_remove_commit="$(curl -sL "$psiphon_url_commit" | grep "linux" | head -1 | cut -d \" -f 4 | tr -d "linux ")"
    echo -e "$INFO Check update Psiphon Tunnel VPN" >&2

    if [ "$psiphon_local_commit" != "$psiphon_remove_commit" ]; then
        echo -e "$INFO LOCAL VERSION Psiphon Tunnel VPN is not synced with REMOTE VERSION, initiating update..." >&2
    else
        echo -e "$INFO No new version available for Psiphon Tunnel VPN." >&2
        exit 1
    fi
}

function check_psiphon(){
    if [ -f "${psiphon_path}" ] && [ -f "${psiphon_config}" ]; then
        return 0
    else
        return 1
    fi
}

function check_free_port(){
    local port="$1"

    if lsof -i :"$port" >/dev/null 2>&1; then
        echo -e "${level_msg[1]}""Port [$port] is already busy, try another one." >&2
        return 1
    else
        echo -e "${level_msg[2]}""Port [$port] installed." >&2
        return 0
    fi
}

function check_dependencies(){
	if ! hash curl 2>/dev/null; then
        echo
		echo -e "${level_msg[0]}""[Curl] is required to use this installer." >&2
        echo
	    IFS= read -n1 -rp "Press any key to install Curl and continue..."
		sudo apt update || (echo -e "${level_msg[0]}""Failed to update repositories, check your internet connection." && exit)
		sudo apt install -y curl || (echo -e "${level_msg[0]}""Failed to install missing packages [wget] and [curl]." && exit)
	fi
}

function is_running_psiphon(){
    pid=$(pgrep -f -- "$psiphon_name_file")

    if [[ -n "$pid" ]]; then
        return 0
    else
        return 1
    fi
}

function stop_pid_psiphon(){
    is_running_psiphon

    if [[ -z "$pid" ]]; then
        echo -e "${level_msg[2]}""[$psiphon_name] is not running." >&2
        return 1
    fi

    echo -e "${level_msg[2]}""Stopping [$psiphon_name] (PID: $pid)..." >&2
    kill "$pid"
    sleep 3

    if is_running_psiphon; then
        echo -e "${level_msg[1]}""$psiphon_name did not complete, forced stop..." >&2
        kill -9 "$pid"
    fi

    echo -e "${level_msg[2]}""[$psiphon_name] stopped." >&2
    return 0
}

function set_port_psiphon(){
    local message="$1"
    local default_port="$2"
    local httpport="$3"
    local port

    while true; do
        IFS= read -rp "$message [$default_port]:" port
        [[ -z "$port" ]] && port="$default_port"

        if ! [[ "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]] || [[ "$port" -gt 65535 ]]; then
            echo -e "${level_msg[1]}""$port: invalid port (must be 1-65535)." >&2
            continue
        fi

        if [[ -n "$httpport" && "$port" == "$httpport" ]]; then
            echo -e "${level_msg[1]}""$port: cannot be the same as previous port ($httpport)." >&2
            continue
        fi

        if ! check_free_port "$port"; then
            continue
        fi

        echo "$port"
        return
    done
}

function download_files(){
    if ! $(type -P curl) --progress-bar --request GET -SLq --retry 5 --retry-delay 10 --retry-max-time 60 --url "${psiphon_url}" --output "${psiphon_path}"; then
        echo -e "${level_msg[0]}""Download $psiphon_name failed." >&2
        rm -Rf "${psiphon_path}"
        exit 1
    fi

    chmod +x "${psiphon_path}"
}

function download_psiphon(){
    [[ ! -d "$psiphon_dir" ]] && mkdir -p "$psiphon_dir"
    download_files
}

function conf_psiphon(){
    echo
    echo -e "${level_msg[2]}""What port (HttpProxy) should $psiphon_name listen to?" >&2
    httpport=$(set_port_psiphon "Port default:" 1080)
    echo
    echo -e "${level_msg[2]}""What port (SocksProxy) should $psiphon_name listen to?" >&2
    socksport=$(set_port_psiphon "Port default:" 1081 "$httpport")
    echo
    echo -e "${level_msg[2]}""Selected ports for $psiphon_name:" >&2
    echo -e "${level_msg[2]}""HttpProxy: Port: $httpport" >&2
    echo -e "${level_msg[2]}""SocksProxy: Port: $socksport" >&2
    #"UpstreamProxyURL":"socks5://192.168.1.2:9050",    -- config socks5 port (for tor)
    cat > "${psiphon_config}"<<-EOF
{
 "LocalHttpProxyPort":$httpport,
 "LocalSocksProxyPort":$socksport,
 "PropagationChannelId":"FFFFFFFFFFFFFFFF",
 "RemoteServerListDownloadFilename":"remote_server_list",
 "RemoteServerListSignaturePublicKey":"MIICIDANBgkqhkiG9w0BAQEFAAOCAg0AMIICCAKCAgEAt7Ls+/39r+T6zNW7GiVpJfzq/xvL9SBH5rIFnk0RXYEYavax3WS6HOD35eTAqn8AniOwiH+DOkvgSKF2caqk/y1dfq47Pdymtwzp9ikpB1C5OfAysXzBiwVJlCdajBKvBZDerV1cMvRzCKvKwRmvDmHgphQQ7WfXIGbRbmmk6opMBh3roE42KcotLFtqp0RRwLtcBRNtCdsrVsjiI1Lqz/lH+T61sGjSjQ3CHMuZYSQJZo/KrvzgQXpkaCTdbObxHqb6/+i1qaVOfEsvjoiyzTxJADvSytVtcTjijhPEV6XskJVHE1Zgl+7rATr/pDQkw6DPCNBS1+Y6fy7GstZALQXwEDN/qhQI9kWkHijT8ns+i1vGg00Mk/6J75arLhqcodWsdeG/M/moWgqQAnlZAGVtJI1OgeF5fsPpXu4kctOfuZlGjVZXQNW34aOzm8r8S0eVZitPlbhcPiR4gT/aSMz/wd8lZlzZYsje/Jr8u/YtlwjjreZrGRmG8KMOzukV3lLmMppXFMvl4bxv6YFEmIuTsOhbLTwFgh7KYNjodLj/LsqRVfwz31PgWQFTEPICV7GCvgVlPRxnofqKSjgTWI4mxDhBpVcATvaoBl1L/6WLbFvBsoAUBItWwctO2xalKxF5szhGm8lccoc5MZr8kfE0uxMgsxz4er68iCID+rsCAQM=",
 "RemoteServerListUrl":"https://s3.amazonaws.com//psiphon/web/mjr4-p23r-puwl/server_list_compressed",
 "SponsorId":"FFFFFFFFFFFFFFFF",
 "UseIndistinguishableTLS":true
}
EOF
}

function run_psiphon(){
    echo
    echo -e "${level_msg[2]}""$psiphon_name [run]." 2>"$psiphon_log"
    "$psiphon_path" -formatNotices -obfs4-distBias -dataRootDirectory "$psiphon_dir" -config "$psiphon_config" 2>>"$psiphon_log" &
    psiphon_pid=$!
    echo -e "${level_msg[2]}""Started with PID: $psiphon_pid" | tee -a "$psiphon_log"
}

function install_psiphon(){
    if check_psiphon; then
        echo
        echo -e "${level_msg[2]}""Download the latest version of the $psiphon_name binary file from github." >&2
        check_update_psiphon
        download_files
    else
        echo
        echo -e "${level_msg[2]}""Installation and configuration of $psiphon_name has begun. Wait..." >&2
        echo
        check_dependencies
        download_psiphon
        touch "${psiphon_config}"
        conf_psiphon
        echo
        echo -e "${level_msg[2]}""Installation and configuration of $psiphon_name [$psiphon_dir] completed successfully." >&2
        echo
    fi
}

function uninstall_psiphon(){
    if check_psiphon; then
        stop_pid_psiphon
        echo
        echo -e "${level_msg[2]}""Deleting all $psiphon_name files successfully." >&2
        rm -Rf "${psiphon_dir}"
    else
        echo
        echo -e "${level_msg[1]}""${msg_DB[0]}" >&2
        echo
    fi
}

function update_psiphon(){
    if check_psiphon; then
        check_update_psiphon
        download_files
        if is_running_psiphon; then
            stop_pid_psiphon
            run_psiphon
        fi
    else
        echo
        echo -e "${level_msg[1]}""${msg_DB[0]}" >&2
        echo
    fi
}

function start_psiphon(){
    if is_running_psiphon; then
        echo -e "${level_msg[1]}""[$psiphon_name] is already running (PID $pid)." >&2
    else 
        if check_psiphon; then
            if [ "$(wc -l < "${psiphon_config}")" -ge 10  ]; then
                echo -e "Start $psiphon_name." >&2
                run_psiphon
            else
                echo
                echo -e "${level_msg[0]}""The configuration file is probably incorrect. Trying to fix." >&2
                echo
                conf_psiphon
            fi
        else
            echo
            echo -e "${level_msg[1]}""${msg_DB[0]}" >&2
            echo
        fi
    fi
}

function stop_psiphon(){
    if is_running_psiphon; then
        stop_pid_psiphon
    else
        echo
    fi
}

function port_psiphon(){
    if check_psiphon; then
        conf_psiphon
        if is_running_psiphon; then
            echo
            echo -e "${level_msg[2]}""Restart $psiphon_name" >&2
            stop_pid_psiphon
            run_psiphon
        fi
    else
        echo
        echo -e "${level_msg[1]}""${msg_DB[0]}" >&2
        echo
    fi
}

function help_psiphon(){
    echo
    echo -e "${level_msg[3]}""Auto install $psiphon_name (Linux version). Script ver.$script_version" >&2
    echo -e "${level_msg[3]}""${msg_DB[1]}" >&2
    echo
}

action="$1"
[ -z "$1" ] && action="start"
case "$action" in
    install|uninstall|update|start|stop|port|help)
        "${action}"_psiphon
        ;;
    *)
        echo
        echo -e "${level_msg[0]}""Invalid argument: [${action}]" >&2
        echo -e "${level_msg[3]}""${msg_DB[1]}" >&2
        echo
        ;;
esac
