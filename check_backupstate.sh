#!/bin/bash
#read file from /root/check-backup
#echo output and exit with status

output=$(cat /root/check-backup/check-backup.out)
status=0
if [ $( cat /root/check-backup/check-backup.out | grep WARN | wc -l) -gt 0 ]; then
	status=1
elif [ $( cat /root/check-backup/check-backup.out | grep CRITICAL | wc -l) -gt 0 ]; then
	status=2
else
	status=0
fi

echo -e "$output"
exit $status
