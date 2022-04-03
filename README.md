# net_container.sh
### Create a new network namespace and move specified interface there
### Usage: net_container.sh \<interface name\>

Assume you have several network interfaces on your computer. You may want some programs (e.g. browser) to use one of them, while others use remaining interfaces.
This script launches shell in isolated network environment. Internet will be available through the interface you choose.
To check your external IP address use something like 'curl -4 ifconfig.me'.
After starting a new shell you can simply run any programs there ,e.g. execute 'firefox'.
Make sure browser is not already running.
Otherwise it will just open a new window instead of be newborn.

