#!/bin/sh

QOS_FORWARD="miqos_fw"   # for XiaoQiang forward
QOS_INOUT="miqos_io"   # for XiaoQiang input/output
QOS_IP="miqos_id"	# for IP mark
QOS_FLOW="miqos_cg"   # for package flow recognization

IPT="/usr/sbin/iptables -t mangle"
SIP=`uci get network.lan.ipaddr 2>/dev/null`
SMASK=`uci get network.lan.netmask 2>/dev/null`
SIPMASK="$SIP/$SMASK"

guest_SIP=`uci get network.guest.ipaddr 2>/dev/null`
guest_SMASK=`uci get network.guest.netmask 2>/dev/null`
guest_SIPMASK="$guest_SIP/$guest_SMASK"

#清除ipt规则
$IPT -D FORWARD -j $QOS_FORWARD &>/dev/null
$IPT -D INPUT -j $QOS_INOUT &>/dev/null
$IPT -D OUTPUT -j $QOS_INOUT &>/dev/null

#清除QOS规则链
$IPT -F $QOS_FORWARD &>/dev/null
$IPT -X $QOS_FORWARD &>/dev/null

$IPT -F $QOS_INOUT &>/dev/null
$IPT -X $QOS_INOUT &>/dev/null

$IPT -F $QOS_FLOW &>/dev/null
$IPT -X $QOS_FLOW &>/dev/null

$IPT -F $QOS_IP &>/dev/null
$IPT -X $QOS_IP &>/dev/null

#新建QOS规则链
$IPT -N $QOS_FORWARD &>/dev/null
$IPT -N $QOS_FLOW &>/dev/null
$IPT -N $QOS_IP &>/dev/null
$IPT -N $QOS_INOUT &>/dev/null

#连接QOS的几条规则链
$IPT -A FORWARD -j $QOS_FORWARD &>/dev/null
$IPT -A INPUT -j $QOS_INOUT
$IPT -A OUTPUT -j $QOS_INOUT

#构建INOUT的规则框架 {}
if [[ 1 ]]; then
    $IPT -A $QOS_INOUT -j CONNMARK --restore-mark --nfmask 0xffff0000 --ctmask 0xffff0000
    $IPT -A $QOS_INOUT -m connmark ! --mark 0/0x000f0000 -j RETURN
    #------------------------------
    #INOUT特定规则
    #APP<->XQ数据流
    $IPT -A $QOS_INOUT -p tcp -m multiport --dports 1880:1890 -j MARK --set-mark 0x00010000/0x000f0000
    #XQ默认数据类型
    $IPT -A $QOS_INOUT -m mark --mark 0/0x000f0000 -j MARK --set-mark 0x00050000/0x000f0000
    #------------------------------
    $IPT -A $QOS_INOUT -j CONNMARK --save-mark --nfmask 0xffff0000 --ctmask 0xffff0000
fi

#构建FORWARD的规则框架 {}
if [[ 1 ]]; then
    $IPT -A $QOS_FORWARD -j CONNMARK --restore-mark --nfmask 0xffff0000 --ctmask 0xffff0000
    $IPT -A $QOS_FORWARD -m connmark ! --mark 0/0xff000000 -m connmark ! --mark 0/0x00f00000 ! --mark 0/000f0000 -j RETURN
    #------------------------------
    #FORWARD特定规则
    $IPT -A $QOS_FORWARD -m connmark --mark 0/0xff000000 -j $QOS_IP
    $IPT -A $QOS_FORWARD -m mark --mark 0/0x000f0000 -j flowMARK --ip $SIP --mask $SMASK
    $IPT -A $QOS_FORWARD -m mark --mark 0/0x00f00000 -j $QOS_FLOW
    $IPT -A $QOS_FORWARD -m mark --mark 0/0x000f0000 -j MARK --set-mark 0x00030000/0x000f0000
    #------------------------------
    $IPT -A $QOS_FORWARD -j CONNMARK --save-mark --nfmask 0xffff0000 --ctmask 0xffff0000
fi

#构建IP规则链
if [[ 1 ]]; then
    #构建GUEST网络的IP规则
    if [ -n "$guest_SIP" -a -n "$guest_SMASK" ]; then
        $IPT -A $QOS_IP -d $guest_SIPMASK -j MARK --set-mark-return 0x00f40000/0x00ff0000
        $IPT -A $QOS_IP -s $guest_SIPMASK -j MARK --set-mark-return 0x00f40000/0x00ff0000
    fi

    $IPT -A $QOS_IP -s $SIPMASK -j IP4MARK --addr src
    $IPT -A $QOS_IP -d $SIPMASK -j IP4MARK --addr dst
fi

#构建数据流FLOW规则链
#TODO

