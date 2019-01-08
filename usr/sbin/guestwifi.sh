#!/bin/sh
# Copyright (C) 2015 Xiaomi

network_name="guest"
ip_range="192.168.32.1"
netmask="255.255.255.0"

#r1cm
#misc.wireless.guest_2G
#network_ifname="wl2"
#
#network_device="mt7620"

#r1d 
#misc.wireless.guest_2G
#network_ifname="wl1.2"
#misc.wireless.if_2G
#network_device="wl1"
#start->on<->off->stop

#plantfrom related. 
network_ifname=`uci get misc.wireless.guest_2G`
network_device=`uci get misc.wireless.if_2G`

guest_usage()
{
    echo "$0:"
    echo "    open|start: start guest wifi, delete all config"
    echo "         $0  open guest_ssid encryption_type password ip mask"              
    echo "    close|stop: stop guest wifi, delete all config"
    echo "    on|enable:  enable guest wifi, need start first"
    echo "    off|disable: disable guest wifi, need start first"
    echo "    other: usage"
    return;
}

guest_ipnet_make()
{
    local guest_lan=""
    . /lib/functions/network.sh                                                                             
    network_get_subnet subnet lan
   
    guest_lan=`echo "$subnet" |awk -F "[./]" '{mask=$5; 
        if(mask<16 && $2<254) 
        {
            print $1"."$2+1".0.1 255.255.0.0"; 
        }
        if(mask>=16 && $3<254) 
        {
            print $1"."$2"."$3+1".1 255.255.255.0"
        }
        if(mask<16 && $2>=254) 
        {
            print $1"."$2-1".0.1 255.255.0.0"; 
        }
        if(mask>=16 && $3>=254) 
        {
            print $1"."$2"."$3-1".1 255.255.255.0"
        }
    }'`
    
    ip_range=`echo $guest_lan |awk '{print $1}'`
    netmask=`echo $guest_lan |awk '{print $2}'`
     
    echo "subnet $subnet"
    echo "$guest_lan"
    echo "range $ip_range"
    echo "mask $netmask"
    return;
}

guest_add()
{
    local ssid=$1
    local encryption=$2  #mixed-psk
    local key=$3  #12345678

    [ "$2" == "" ] && { encryption="none"; key=""; }
    [ "$1" == "" ] && ssid="xiaomi_guest_2G"

    guest_ipnet_make

#wifi
uci -q batch <<-EOF >/dev/null
    set wireless.${network_name}_2G=wifi-iface
    set wireless.${network_name}_2G.ifname=$network_ifname
    set wireless.${network_name}_2G.network=${network_name}
    set wireless.${network_name}_2G.encryption=$encryption
    set wireless.${network_name}_2G.device=${network_device}
    set wireless.${network_name}_2G.key=$key
    set wireless.${network_name}_2G.mode=ap
    set wireless.${network_name}_2G.ssid=$ssid
    set wireless.${network_name}_2G.enabled=1
    set wireless.${network_name}_2G.open=1
    commit wireless
EOF

#network
uci -q batch <<-EOF >/dev/null
    set network.${network_name}=interface
    set network.${network_name}.ifname=eth0.3
    set network.${network_name}.type=bridge
    set network.${network_name}.proto=static
    set network.${network_name}.ipaddr=$ip_range
    set network.${network_name}.netmask=$netmask
    commit network
EOF

#dhcp
uci -q batch <<-EOF >/dev/null
    set dhcp.${network_name}=dhcp
    set dhcp.${network_name}.interface=${network_name}
    set dhcp.${network_name}.start=100
    set dhcp.${network_name}.limit=150
    set dhcp.${network_name}.leasetime=12h
    set dhcp.${network_name}.force=1
    set dhcp.${network_name}.dhcp_option_force=43,XIAOMI_ROUTER
    commit dhcp
EOF

#firewall
uci -q batch <<-EOF >/dev/null
    set firewall.${network_name}_forward=forwarding
    set firewall.${network_name}_forward.src=guest
    set firewall.${network_name}_forward.dest=wan

    set firewall.${network_name}_zone=zone
    set firewall.${network_name}_zone.name=${network_name}
    set firewall.${network_name}_zone.network=${network_name}
    set firewall.${network_name}_zone.input=REJECT
    set firewall.${network_name}_zone.forward=REJECT
    set firewall.${network_name}_zone.output=ACCEPT


    set firewall.${network_name}_dns=rule
    set firewall.${network_name}_dns.name=Allow Guest DNS Queries
    set firewall.${network_name}_dns.src=guest
    set firewall.${network_name}_dns.dest_port=53
    set firewall.${network_name}_dns.proto=tcpudp
    set firewall.${network_name}_dns.target=ACCEPT

    set firewall.${network_name}_dhcp=rule
    set firewall.${network_name}_dhcp.name=Allow Guest DHCP request
    set firewall.${network_name}_dhcp.src=guest
    set firewall.${network_name}_dhcp.src_port=67-68
    set firewall.${network_name}_dhcp.dest_port=67-68
    set firewall.${network_name}_dhcp.proto=udp
    set firewall.${network_name}_dhcp.target=ACCEPT

    commit firewall
EOF
   
    return
}

guest_delete()
{
    #firewall.@rule[5].src=guest
    #local rule_id=`uci show firewall | awk -F '[][]' '{if($1~/^firewall.@rule/ && $3~/\.name=Guest-DNS-Queries$/) print $2}'`
    #firewall.@zone[2].name=guest
    #local zone_id=`uci show firewall | awk -F '[][]' '{if($1~/^firewall.@zone/ && $3~/\.name=guest$/) print $2}'`

uci -q batch <<-EOF >/dev/null
    delete firewall.${network_name}_dhcp
    delete firewall.${network_name}_dns
    delete firewall.${network_name}_zone
    delete firewall.${network_name}_forward

    delete wireless.${network_name}_2G
    delete network.${network_name}
    delete dhcp.${network_name}

    commit
EOF
    
    return 0
}

guest_enable()
{
    uci set wireless.${network_name}_2G.enabled=1;
    uci set wireless.guest_2G.open=1;
    uci commit
    
    wifi
    return 0
}

guest_disable()
{
    uci set wireless.${network_name}_2G.enabled=0;
    uci set wireless.guest_2G.open=0
    uci commit
    
    wifi
    return 0   
}

guest_start()
{
    guest_add $1 $2 $3

    wifi
    /etc/init.d/network restart
    /etc/init.d/dnsmasq restart
    /etc/init.d/firewall restart
   
    return 0
}

guest_stop()
{
    guest_delete
     
    wifi
    /etc/init.d/network restart
    /etc/init.d/dnsmasq restart
    /etc/init.d/firewall restart
    
    return 0
}

OPT=$1

[ "$network_ifname" == "" ] && exit 1

[ "$network_device" == "" ] && exit 1

#main
case $OPT in 
    open|start) 
        guest_start $2 $3 $4
        return $?
    ;;

    close|stop) 
        guest_stop
        return $?
    ;;

    on|enable)
        guest_enable
        return $?
    ;;

    off|disable)
        guest_disable
        return $?     
    ;;
    * ) 
        guest_usage
        return 0
    ;;
esac



