#!/bin/sh
# Copyright (C) 2014 Xiaomi

#
# $1 = opt. open/close
# usage:
#      ap_mode.sh open/close
#

. /lib/functions.sh
config_load misc &>/dev/null
config_get cmd_bridgeap_connect switchop bridgeap_connect &>/dev/null;
config_get cmd_bridgeap_open switchop bridgeap_open &>/dev/null;
config_get cmd_bridgeap_close switchop bridgeap_close &>/dev/null;

usage() {
    echo "usage:"
    echo "    ap_mode.sh opt=open/close/check_gw"
    echo "    example1:  ap_mode.sh open"
    echo "    example2:  ap_mode.sh close"
    echo "    example2:  ap_mode.sh check_gw"
}

#$1 : log message
bridgeap_logger()
{
    logger -t bridgeap "$1"
}

bridgeap_open_r1cm() {

uci -q batch <<-EOF >/dev/null
    #we don't to delete network.ap_mode when xq change to ap mode, backup file would cover it.
    set network.ap_mode="bridgeap"
    set network.lan.ifname='eth0.1 eth0.2 wl0 wl1'
    set network.lan.type='bridge'
    set dhcp.lan.ignore=1;
    commit network
    commit dhcp
EOF

}

bridgeap_close_r1cm_default() {
    echo "#######################bridgeap_close_r1cm_default###############"
uci -q batch <<-EOF >/dev/null
    delete network
    set network.loopback=interface
    set network.loopback.ifname=lo
    set network.loopback.proto=static
    set network.loopback.ipaddr=127.0.0.1
    set network.loopback.netmask=255.0.0.0
    set network.lan=interface
    set network.lan.ifname=eth0.1
    set network.lan.type=bridge
    set network.lan.proto=static
    set network.lan.ipaddr=192.168.31.1
    set network.lan.netmask=255.255.255.0
    set network.wan=interface
    set network.wan.ifname=eth0.2
    set network.wan.proto=dhcp
    commit network
    delete dhcp.lan.ignore;
    commit dhcp
EOF

}

#
#config backupfile /etc/config/.network.mode.router is create by dhcp_apclient.sh:router_config_backup()
#
bridgeap_close_r1cm() {
    local router_backup_file="/etc/config/.network.mode.router"
    
    [ ! -f "$router_backup_file" ] &&  bridgeap_close_r1cm_default && return;
    
    mv $router_backup_file "/etc/config/network"
    
uci -q batch <<-EOF >/dev/null
    delete dhcp.lan.ignore;
    commit dhcp
EOF
  
}

bridgeap_open_r1d() {
    echo "#######################bridgeap_open_r1d###############"
uci -q batch <<-EOF >/dev/null
    set network.eth0_1.ports='0 2 4 5*'
    set network.eth0_2.ports='5'
    commit network
EOF

    nvram set vlan1ports='0 2 4 5*'
    nvram set vlan2ports='5'
    nvram set mode=AP
    nvram commit

    rmmod et
    insmod et
}

#
#config backupfile /etc/config/.network.mode.router is create by dhcp_apclient.sh:router_config_backup()
#
bridgeap_close_r1d(){

    echo "#######################bridgeap_close_r1d###############"

    local router_backup_file="/etc/config/.network.mode.router"
    
    [ ! -f "$router_backup_file" ] &&  bridgeap_close_r1d_default && return;
    
    mv $router_backup_file "/etc/config/network"

    nvram set vlan1ports='0 2 5*'
    nvram set vlan2ports='4 5'
    nvram set mode=Router
    nvram commit
    
    rmmod et
    insmod et
}

bridgeap_close_r1d_default() {
    echo "#######################bridgeap_close_r1d_default###############"
uci -q batch <<-EOF >/dev/null
    delete network
    set network.eth0=switch
    set network.eth0.enable=1
    set network.eth0_1=switch_vlan
    set network.eth0_1.device=eth0
    set network.eth0_1.vlan=1
    set network.eth0_1.ports=0 2 5*
    set network.eth0_2=switch_vlan
    set network.eth0_2.device=eth0
    set network.eth0_2.vlan=2
    set network.eth0_2.ports=4 5
    set network.loopback=interface
    set network.loopback.ifname=lo
    set network.loopback.proto=static
    set network.loopback.ipaddr=127.0.0.1
    set network.loopback.netmask=255.0.0.0
    set network.lan=interface
    set network.lan.type=bridge
    set network.lan.ifname=eth0.1
    set network.lan.proto=static
    set network.lan.ipaddr=192.168.31.1
    set network.lan.netmask=255.255.255.0
    set network.wan=interface
    set network.wan.proto=dhcp
    set network.wan.ifname=eth0.2
    commit network

    delete dhcp.lan.ignore;
    commit dhcp
EOF

}

#return value 1: gw ip unreachable;
#return value 0: gw ip exists
bridgeap_check_gw()
{
    local bridgeap_gw_ip=`uci get network.lan.gateway`

    bridgeap_logger "current gateway ip $bridgeap_gw_ip"
    [ -z $bridgeap_gw_ip ] && return 0;

    bridgeap_gw_ip_noexist=`arping $bridgeap_gw_ip -I br-lan -c 3 &>/dev/null; echo $?`;
    bridgeap_logger "current gateway ip $bridgeap_gw_ip exist $bridgeap_gw_ip_noexist(1:gw ip unreachable)."
    return $bridgeap_gw_ip_noexist;
}

# return value 1: not ap mode
# return value 0: ap mode;
bridgeap_check_apmode()
{
    local network_apmode=`uci get network.ap_mode`

    bridgeap_logger "network apmode $network_apmode."
    [ "$network_apmode" = "bridgeap" ] && return 0;
    
    bridgeap_logger "network apmode $network_apmode false."
    return 1;
}

bridgeap_open() 
{
    [ -z "$cmd_bridgeap_open" ] && exit 1
    eval ${cmd_bridgeap_open}
}

bridgeap_close() 
{
    [ -z "$cmd_bridgeap_close" ] && exit 1
    eval ${cmd_bridgeap_close}
}

bridgeap_lan_restart()
{
    bridgeap_logger "try restart lan."
    for i in `seq 1 10`
    do
       /usr/sbin/dhcp_apclient.sh restart
       [ $? = '0' ] && return 0; 

       bridgeap_logger "restart lan fail, try again in $i seconds."
       sleep $i
    done
    
    return 1;
}


# add timer task to crontab
# eg.
# bridgeap mode gateway check
# */1 * * * * /usr/sbin/ap_mode.sh check_gw
bridgeap_check_gw_stop()
{
   grep -v "/usr/sbin/ap_mode.sh check_gw" /etc/crontabs/root > /etc/crontabs/root.new;
   mv /etc/crontabs/root.new /etc/crontabs/root
   /etc/init.d/cron restart 	
}

bridgeap_check_gw_start()
{
   grep -v "/usr/sbin/ap_mode.sh check_gw" /etc/crontabs/root > /etc/crontabs/root.new; 
   echo "*/1 * * * * /usr/sbin/ap_mode.sh check_gw" >> /etc/crontabs/root.new
   mv /etc/crontabs/root.new /etc/crontabs/root
   /etc/init.d/cron restart
}


OPT=$1


if [ $# -ne 1 ];
then
    usage
    exit 1
fi

case $OPT in 
    connect)
        /usr/sbin/dhcp_apclient.sh start eth0.2
        return $?
    ;;

    open)
        bridgeap_open;
        /etc/init.d/network restart
        /etc/init.d/dnsmasq stop
        /etc/init.d/dnsmasq disable
        /usr/sbin/dhcp_apclient.sh restart
        /etc/init.d/trafficd restart; 
        /etc/init.d/xqbc restart
        bridgeap_check_gw_start
        return $?
    ;;

    close) 
        bridgeap_check_gw_stop
        bridgeap_close;
        /etc/init.d/network restart
        /etc/init.d/dnsmasq enable
        /etc/init.d/dnsmasq restart
        /usr/sbin/dhcp_apclient.sh restart
        /etc/init.d/trafficd restart; 
        /etc/init.d/xqbc restart
        return $?
    ;;

    check_gw)
        #this part is used for "link up/down" "root ap change" check, in those situation 
        # gateway/lan/sta ip must be "dhcp renew"
        bridgeap_logger "check apmode."
        bridgeap_check_apmode
        [ $? = '1' ] && exit 0;

        bridgeap_logger "check gateway."
        bridgeap_check_gw
        [ $? = '0' ] && exit 0;

        # in bridge ap mode and gateway unreachable, we had to run dhcp renew issue;
        # if can't renew ipaddr, script should  exit. otherwise, restart network && lan
        bridgeap_logger "gateway changed, try dhcp renew."
        local lan_ipaddr_ori=`uci get network.lan.ipaddr 2>/dev/null`

        /usr/sbin/dhcp_apclient.sh start br-lan;
        local lan_ipaddr_now=`uci get network.lan.ipaddr 2>/dev/null`
        [ "$lan_ipaddr_ori" = "$lan_ipaddr_now" ] && exit 0;

        bridgeap_logger "gateway changed, lan ip changed from $lan_ipaddr_ori to $lan_ipaddr_now."
        /etc/init.d/network restart
        bridgeap_logger "gateway changed, try lan restart"
        bridgeap_lan_restart
        exit 0;
     ;;

     * ) 
        echo "usage:" >&2
  ;;
esac

