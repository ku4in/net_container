## net_container
### Create a new network namespace and move specified interface there
### Usage: sudo ./net_container.sh \<interface name\>
### Usage: sudo ./wg_container.sh

Assume you have several network interfaces on your computer. For example, you have Ethernet cable and USB-tethering phone. You may want some programs (e.g. browser) use your phone to access the internet, while others use Ethernet.
***net_container.sh*** script launches shell in isolated network namespace. Internet will be available through the interface you choose.
To get list of all network interfaces use 'ip link' or 'ifconfig' comands.
To check your external IP address use something like 'curl -4 ifconfig.me'.
After starting a new shell you can simply run any programs there ,e.g. execute 'firefox'.
Make sure browser is not already running.
Otherwise it will just open a new window instead of be newborn.

If you have Wireguard VPN, then you can use ***wg_container.sh*** to start new shell in isolated network namespace environment. All traffic in this shell will go through Wireguard server.

Probably, you may want combine two scripts, e.g. first use ***net_container.sh*** to pass your traffic through particular interface and then execute ***wg_container.sh*** in a shell created by ***net_container.sh***. As a result you will have shell with traffic goes through chosen interface to Wireguard server.
