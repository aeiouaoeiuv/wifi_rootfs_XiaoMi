#!/bin/sh
#
#FILE_TARGET: /lib/config_post_ota/dnsmasq_config_post_ota.sh
#

/sbin/uci -q batch <<-EOF >/dev/null
set dhcp.@dnsmasq[0].cachesize=1000
set dhcp.@dnsmasq[0].negttl=300
set dhcp.@dnsmasq[0].maxttl=300
set dhcp.@dnsmasq[0].maxcachettl=1800
set dhcp.@dnsmasq[0].dnsforwardmax=300
set dhcp.@dnsmasq[0].leasefile=/tmp/dhcp.leases
set dhcp.@dnsmasq[0].allservers=1
delete dhcp.@dnsmasq[0].intercept
delete dhcp.@dnsmasq[0].domain
delete dhcp.@dnsmasq[0].filterwin2k
delete dhcp.@dnsmasq[0].readethers
commit dhcp
EOF

echo "INFO: update dnsmasq config ok."
exit 0
