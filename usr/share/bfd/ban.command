#!/bin/sh

attack_ip="$1"
# ban two hours by default
BAN_SECONDS=${2:-7200}
# first create firewall rule chain if it is not exist
rule_chain='bfd_admin'
iptables -L "$rule_chain" &> /dev/null || {
    iptables -N "$rule_chain"
    iptables -A input_lan_rule -j "$rule_chain"
}

# get mac address from ip
attack_mac=$(ip neigh | grep "$attack_ip" | awk '{print$5}')
if [ -z "$attack_mac" ]; then
    echo "bfd.ban: not found $attack_ip in neighber"
    exit 1
fi
# get ban stop time
now_timestamp=$(date +"%s")
let stop_timestamp="$now_timestamp + $BAN_SECONDS"
stop_time=$(date -u -D "%s" -d "$stop_timestamp" +"%Y-%m-%dT%H:%M:%S")
# TODO: clean out of date rule
iptables -A $rule_chain -p tcp --dport 80 -m mac --mac-source "$attack_mac" -m time --datestop $stop_time -j DROP
