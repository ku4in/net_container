#!/bin/bash -i

## Script starts new shell in isolated network namespace and passes traffic from this shell through Wireguard

user=`whoami`

# Check root
if [ "$user" != "root" ]; then
	echo "Must be root!"
	exit 1
fi

# We will exec bash from normal user	
user=$SUDO_USER


ns_name='ns2'  # no mater
wg_name='wg0'  # no mater
wg_priv_key="/home/$user/wg.key"  # path to client privat key
wg_endpoint_ip='93.184.216.34'    # wg server public ip
wg_endpoint_port='51820'          # wg server public port
wg_peer='GFseg/tjnH0WNfLI69W1EOh/Yf8cb4deDvDxVLho/X0='  # wg server pub key
wg_ip='10.0.1.4/24'               # client ip on wg interface
wg_def='10.0.1.1'                 # server ip on wg interface
virt1='virt1'          # no mater
virt2='virt2'          # no mater
virt1_ip='10.10.10.1'  # no mater
virt2_ip='10.10.10.2'  # no mater
DNS='1.1.1.1'          # you preferred dns 

ns_old=`ip netns list | grep -o $ns_name`
virt_old=`ip a | grep -o $virt1`

# Delete network namespace if already exists
if [ "$ns_old" ]; then
	echo "Namespace '$ns_name' already exists. Trying to delete it ..."
	ip netns del $ns_name
	if [ ! $? -eq 0 ]; then echo "Error: can't delete existing namespace '$ns_old'!"; exit 1; fi
	sleep 2
fi

if [ "$virt_old" ]; then
	echo "Interface '$virt_old' already exists. Trying to delete it ..."
	ip link del dev $virt1
	if [ ! $? -eq 0 ]; then echo "Error: can't delete existing interface '$virt_old'!"; exit 1; fi
fi

# Get default gateway interface name
if_def=`ip r | grep default | head -1 | cut -f 5 -d ' '`
if [ ! "$if_def" ]; then
        echo "Error: no default gateway found!"
        exit 1
fi


# Make verbose and exit on any fail
set -e
set -x

# Add new network namespace
ip netns add $ns_name

# Add new virtual interfaces
ip link add dev $virt1 type veth peer name $virt2

# Send interface '$virt2' to namespace '$ns_name'
ip link set $virt2 netns $ns_name

# Add addresses for interfaces
ip addr add $virt1_ip/24 dev $virt1
ip -n $ns_name addr add $virt2_ip/24 dev $virt2

# Bring interfaces up
ip link set $virt1 up
ip -n $ns_name link set $virt2 up

# Add new Wireguard interface and set ip adders
ip -n $ns_name link add dev $wg_name type wireguard
ip -n $ns_name addr add dev $wg_name $wg_ip

# Set '$wg_name' interface. File with private key should exits and contains client key
ip netns exec $ns_name wg set $wg_name private-key $wg_priv_key peer $wg_peer allowed-ips 0.0.0.0/0 endpoint $wg_endpoint_ip:$wg_endpoint_port
ip -n $ns_name link set up dev $wg_name

# Allow forwarding and setup MASQUERADE on main interface
echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null
iptables -t nat -A POSTROUTING -o $if_def -j MASQUERADE

# Set route to Wireguard server and default
ip -n $ns_name route add $wg_endpoint_ip/32 via $virt1_ip
ip -n $ns_name route add default via $wg_def

# Create separate DNS
mkdir -p /etc/netns/$ns_name
echo "nameserver $DNS" > /etc/netns/$ns_name/resolv.conf 2>/dev/null

set +x
# Execute program (i.e. bash) in new namespace $ns_name as user $user
ip=`ip netns exec $ns_name curl -s -4 ifconfig.me`
ip netns exec $ns_name sudo -u $user PS1="($ip) $PS1" bash --norc
# ip netns exec $ns_name su - $user  # prompt will not change

set -x
# Delete namespace
ip netns del $ns_name

exit 0
