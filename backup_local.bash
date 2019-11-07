#!/bin/bash

date=`date "+%Y-%m-%dT%H-%M-%S"`
backup=/mnt/backup
targets="/ /boot /boot/efi"

PUSHOVER_APPTOKEN="..."
PUSHOVER_USERKEY="..."

function pushover {
	curl -s \
	  --form-string "token=$PUSHOVER_APPTOKEN" \
	  --form-string "user=$PUSHOVER_USERKEY" \
	  --form-string "message=$1" \
	  --form-string "priority=$2" \
	  https://api.pushover.net/1/messages.json	
}

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

# Check if target directory is valid
if [ ! -f $backup/valid_backup_disk ]; then
	echo "Backup target does not seem to be a valid destination" 1>&2
	pushover "Invalid backup target" "0"
	exit 2
fi

# Add _longterm for every last sunday
# https://unix.stackexchange.com/questions/330571/how-to-know-last-sunday-of-month
if [[ $(date -d "+ 1week" +%d%a) =~ 0[1-7]Sun ]]; then
    date+="_longterm"
fi

mkdir -p $backup/logs 

pushover "Starting backup process" "-2"

rsync -a \
	--stats \
	--partial \
	-h \
	-H \
	-A \
	-X \
	-x \
	-R \
	--log-file=$backup/logs/$date.log \
	--exclude='/media/**' --exclude='/mnt/**' --exclude='/proc/**' --exclude='/sys/**' --exclude='/tmp/**' --exclude='/run/**' --exclude='/dev/**' \
	$targets \
	--link-dest=$backup/latest \
	$backup/incomplete_$date \
	&& mv $backup/incomplete_$date $backup/$date \
	&& rm -f $backup/latest \
	&& ln -s $backup/$date $backup/latest
exit_code=$?

if (( $exit_code == 0 )); then
	pushover "Backup process ended successfully" "-2"
else
	pushover "Backup process failed with exit code: $exit_code" "0"
fi
