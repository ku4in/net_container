#!/bin/bash

## Script creates a new net namespace and moves specified interface there

ns_name='ns1'
if_name="$1"
user=`whoami`

if [ "$user" != "root" ]; then
	echo "Must be root!"
	exit 1
fi

# We will exec bash from normal user	
user=$SUDO_USER

if [ ! "$if_name" ]; then
	echo "Usage: $0 <interface name>"
	exit 1
fi

ns_old=`ip netns list | grep -o $ns_name`

# Delete nerwork namespace if already exists
if [ "$ns_old" ]; then
	echo "Namespace '$ns_name' already exists. Trying to delet it ..."
	ip netns del $ns_name
	if [ ! $? -eq 0 ]; then echo "Error: can't delete existing namespace '$ns_old'!"; exit 1; fi
	sleep 2
fi

router_ip=`ip route | grep "default" | grep $if_name | cut -f 3 -d ' '`
ip_mask_brd=`ip a | grep $if_name | grep -v inet6 | grep inet | tr -s ' ' | cut -f 3-5 -d ' '`

# Make scrip verbose, exit on any fail
set -e
set -x


# Add new network namespace
ip netns add $ns_name

# Send interface $if_name to namespace $ns_name
ip link set $if_name netns $ns_name

# Bring interfaces up
ip -n $ns_name link set $if_name up

# Set ip address on interface
ip -n $ns_name addr add $ip_mask_brd dev $if_name 

# Set routes
ip -n $ns_name route add default via $router_ip

# Set DNS
mkdir -p /etc/netns/$ns_name
echo "nameserver 1.1.1.1" > /etc/netns/$ns_name/resolv.conf 2>/dev/null

set +x
# Execute program (i.e. bash) in new namespace $ns_name as user $user
echo -n "Starting shell in namespace '$ns_name'. "
ip=`ip netns exec $ns_name curl -s -4 ifconfig.me`
echo "IP in this shell = $ip"
ip netns exec $ns_name su - $user

set -x
# Delet namespace
ip netns del $ns_name

exit 0
