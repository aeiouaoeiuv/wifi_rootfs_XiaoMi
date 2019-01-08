#!/bin/sh
while read line; do
	echo  $line >> /tmp/cordump.log
	if [ -z "$line" ]; then
		tmpfile=cordump.$(cut -d ' ' -f 1 /proc/uptime).log
		(
			mv /tmp/cordump.log /tmp/$tmpfile
			/usr/sbin/mtd_crash_log -a /tmp/$tmpfile
			rm -f /tmp/$tmpfile
			sleep 100
		) &
	fi
done
