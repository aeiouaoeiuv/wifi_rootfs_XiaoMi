[ "$ACTION" = "DISASSOC" ] && [ -n "$STA" ] && {
	/usr/bin/matool --method reportEvents --params "[ { \"eventID\": 0, \"mac\": \"$STA\", \"ip\": \"\", \"payload\": \"\" } ]"
	logger -p Error -t trafficd '/usr/bin/matool --method reportEvents --params ' "[ { \"eventID\": 0, \"mac\": \"$STA\", \"ip\": \"\", \"payload\": \"\" } ]"
}