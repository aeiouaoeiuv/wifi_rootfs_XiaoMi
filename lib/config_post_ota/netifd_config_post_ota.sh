#!/bin/sh

# add troubleshoot netowrk
/sbin/uci -q batch <<-EOF >/dev/null
delete network.diagnose
commit network
EOF
