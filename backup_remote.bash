#!/bin/bash

date=`date "+%Y-%m-%dT%H-%M-%S"`
targets="/ /boot /boot/efi"

remote_ip="10.30.51.11"
rsyncaddr="rsync://test@10.30.51.11/volume"
export RSYNC_PASSWORD="test"
sshaddr="root@10.30.51.11"
remote_backput_dest="/mnt/backup"

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
    pushover "This script must be run as root" "0"
    exit 1
fi

if nc -z ${remote_ip} 22 2>/dev/null; then
    echo "SSH ok"
else
    echo "SSH port not reachable" 1>&2
    pushover "SSH port not reachable" "0"
    exit 2
fi

if nc -z ${remote_ip} 873 2>/dev/null; then
    echo "Rsync ok"
else
    echo "Rsync port not reachable" 1>&2
    pushover "Rsync port not reachable" "0"
    exit 3
fi

if ssh -q ${sshaddr} "[[ -f ${remote_backput_dest}/valid_backup_disk ]]"; then
    echo "Backup destination ok"
else
    echo "Backup target invalid" 1>&2
    pushover "Backup target invalid" "0"
    exit 4
fi

# Add _longterm for every last sunday
# https://unix.stackexchange.com/questions/330571/how-to-know-last-sunday-of-month
if [[ $(date -d "+ 1week" +%d%a) =~ 0[1-7]Sun ]]; then
    date+="_longterm"
fi

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
    --log-file=${tmp_logdir}/${date}.log \
    --exclude='/media/**' --exclude='/mnt/**' --exclude='/proc/**' --exclude='/sys/**' --exclude='/tmp/**' --exclude='/run/**' --exclude='/dev/**' \
    --link-dest=../latest \
    ${targets} ${rsyncaddr}/incomplete_${date} \
    && ssh ${sshaddr} \
        "cd ${remote_backput_dest} \
         && mv incomplete_${date} ${date} \
         && rm -f latest \
         && ln -s ${date} latest" \
    && scp ${tmp_logdir}/${date}.log ${sshaddr}:${remote_backput_dest}/logs
exit_code=$?

if (( $exit_code == 0 )); then
    pushover "Backup process ended successfully" "-2"
else
    pushover "Backup process failed with exit code: ${exit_code}" "0"
fi

rm ${tmp_pwfile}
rm ${tmp_logdir}/${date}.log # avoid using rm -r
rmdir ${tmp_logdir}          # avoid using rm -r
