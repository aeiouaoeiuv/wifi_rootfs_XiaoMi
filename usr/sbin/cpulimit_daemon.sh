#!/bin/sh
# ==============================================================
# CPU limit daemon - set PID's max. percentage CPU consumptions
# ==============================================================

# Maximum percentage CPU consumption all processes
llmt=10
rlmt=80

# Daemon check interval in seconds
interval=1

# Search and limit violating PIDs
> /tmp/_clmts
> /tmp/_ctops

cnt=0
while sleep $interval
do
	# cpu 0 consumption/idle
	idle=$(/bin/mpstat 4 1 -P 0 | awk 'NR>6 {print $11}' | awk -F. '{print $1}')

	if [ $idle -lt $llmt ]; then
		cnt=0

		# top cpu consumption
		/usr/bin/top -b -n1 -c | awk 'NR>7&&NR<=12 {print $1,$9}' > /tmp/_ctops
		read pid1 cpu1 < /tmp/_ctops
		cpu1=`echo $cpu1 | awk -F. '{print $1}'`

		# cpulimit daemon pids
		plmts=$(/usr/bin/ps -eo args | awk '$1=="cpulimit" {print $3}')

		if [ $cpu1 -gt 30 ]; then
			if [ $cpu1 -gt 90 ]; then
				let cpuz=90
			else
				let cpuz=$cpu1-5
			fi

			cat /tmp/_clmts | grep $pid1 > /dev/null
			if [ $? -ne 0 ]; then
				cpulimit -p $pid1 -l $cpuz -z &
				echo "$pid1 $cpuz" >> /tmp/_clmts
			#else
			#	hcpu=$(cat /tmp/_clmts | grep $pid1 | awk '{print $2}')
			#	let hl=$cpu1+10
			#	let l1=$cpu1-10
			#	if [ $hcpu -lt $l1 -o $hcpu -gt $h1 ]; then
			#		cat /tmp/_clmts | grep -v $pid1 > /tmp/__clmts
			#		echo "$pid1 $hcpu" >> /tmp/__clmts
			#		mv /tmp/__clmts /tmp/_clms
			#
			#		cpulimit -p $hcpu -l $pid1 -z &
			#	fi
			fi
		fi
	fi

	# cpu in idle state, we will clear all cpulimit
	if [ $idle -gt $rlmt ]; then
		let cnt=$cnt+1

		# if cpu consumption < 5 after 10s, we need
		# clear all older cpulimit control
		if [ $cnt -gt 2 ]; then
			cnt=0

			old=$(cat /tmp/_clmts)
			[ -n "$old" ] && {
				> /tmp/_clmts
				killall -q cpulimit
			}
		fi
	else
		cnt=0
	fi
done
