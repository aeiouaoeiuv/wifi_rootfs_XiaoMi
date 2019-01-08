#!/bin/sh
CMD="/etc/init.d/rule_mgr"
LIP=`uci get network.lan.ipaddr 2>/dev/null`
LMASK=`uci get network.lan.netmask 2>/dev/null`
L_WARNING_PORT=8192
L_CACHED_PORT=8193
L_AD_FILTER_PORT=8196
L_CONTENT_FILTER_PORT=8197

FLAG=$1

model=`nvram get model`
if [ -z "$model" ]; then
    model=`cat /proc/xiaoqiang/model`
fi

if [ $FLAG == "start" ]; then

    $CMD status

    if [ $? -eq 0 ]; then

        echo "open and set actions to kernel"
        echo "ADD 1 $LIP $L_WARNING_PORT" >/proc/sys/net/ipv4/tcp_proxy_action
        echo "ADD 2 $LIP $L_CACHED_PORT" >/proc/sys/net/ipv4/tcp_proxy_action
        echo "ADD 3 $LIP $L_AD_FILTER_PORT" >/proc/sys/net/ipv4/tcp_proxy_action
        echo "ADD 4 $LIP $L_CONTENT_FILTER_PORT" >/proc/sys/net/ipv4/tcp_proxy_action

        #start switch
        echo "1" > /proc/sys/net/ipv4/tcp_proxy_switch

        if [ "$model" == "R1D" ]; then
            ctf_manger.sh rule_mgr http on
        elif [ "$model" == "R1CM" ]; then
            #config_load "hwnat"
            uci set hwnat.switch.rule_mgr=1
            uci commit hwnat
            /etc/init.d/hwnat stop &>/dev/null
        else
            echo "rule_mgr: unknown model type!"
        fi

        if [ $? -ne "0" ]; then
            echo "iptables insert SKIPCTF or remove hw_nat error."
            return $?
        fi
    else
        echo "rule_mgr service is not running"
    fi

else
    echo "close and reset actions to kernel"
    echo "0" > /proc/sys/net/ipv4/tcp_proxy_switch

    if [ "$model" == "R1D" ]; then
        ctf_manger.sh rule_mgr http off
    elif [ "$model" == "R1CM" ]; then
        #config_load "hwnat"
        uci set hwnat.switch.rule_mgr=0
        uci commit hwnat
        /etc/init.d/hwnat start &>/dev/null
    else
        echo "rule_mgr: unknown model type!"
    fi

    if [ $? -ne "0" ]; then
        echo "iptables remove SKIPCTF or insert hw_nat error."
        return $?
    fi
fi

