# Auto install psiphon VPN (Release candidate binaries)
[![Download](https://img.shields.io/badge/download-Bash-brightgreen.svg)](https://raw.githubusercontent.com/MisterTowelie/Psiphon-Tunnel-VPN/main/psiphonVPN.sh)
[![License](https://img.shields.io/github/license/Shabinder/SpotiFlyer?style=flat-square)](https://www.gnu.org/licenses/gpl-3.0.html)

[Psiphon Labs](https://github.com/Psiphon-Labs/psiphon-labs.github.io)

## System Required:
* Debian9+, Ubuntu20+, Trisquel9+
* Curl

## PsiphonVPN.sh
[Wikipedia](https://en.wikipedia.org/wiki/Psiphon)  
* Psiphon is a free and open-source Internet censorship circumvention tool that uses a combination of secure communication and obfuscation technologies, such as a VPN, SSH, and a Web proxy. Psiphon is a centrally managed and geographically diverse network of thousands of proxy servers, using a performance-oriented, single- and multi-hop routing architecture.

[Jon Watson](https://www.comparitech.com/blog/vpn-privacy/using-psiphon-guide/) 
Specifically, Psiphon:
*  Uses (injects) ads to support the service which use cookies and web beacons
* Occasionally records additional usage data which will be disclosed on its Privacy Bulletin
* Shares access data with its partners so they can see how often their sites are visited and from where
* Runs all of the Psiphon servers itself, although the code is open source and available on GitHub

## Uses
How to configure your browser to connect to a Psiphon VPN, see the example of Firefox and Google Chrome:  
[Firefox](https://support.mozilla.org/en-US/kb/connection-settings-firefox)  
[Google Chrome](https://thesafety.us/proxy-setup-chrome-windows)

## Installing
```sh
curl -O https://raw.githubusercontent.com/MisterTowelie/Psiphon-Tunnel-VPN/main/psiphonVPN.sh && chmod +x psiphonVPN.sh
./psiphonVPN.sh install
```

## Launching
```sh
./psiphonVPN.sh
# or
./psiphonVPN.sh start
```

## Stop the program (process)
```sh
./psiphonVPN.sh stop
```

## Removing
```sh
./psiphonVPN.sh uninstall
```

## Help
```sh
./psiphonVPN.sh help
```

## Changing ports for connecting to VPN
```sh
./psiphonVPN.sh port
```

## Updating the binary file
```sh
./psiphonVPN.sh update
```










