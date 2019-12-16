Backup script using rsync to create hard-linked incremental backups on Linux machines. Result looks similar to Apple's Time Machine backup mechanism:

    root@server:/mnt/backup# ll
    total 96K
    drwxr-xr-x 18 root root 4.0K 2019-01-07 13:38 ./
    drwxr-xr-x  4 root root 4.0K 2016-12-08 14:33 ../
    drwxr-xr-x 25 root root 4.0K 2015-12-02 08:11 2015-12-12T00-07-51_longterm/
    drwxr-xr-x 25 root root 4.0K 2016-11-30 07:37 2016-11-30T12-45-48_longterm/
    drwxr-xr-x 24 root root 4.0K 2018-02-22 06:49 2018-02-25T01-00-01_longterm/
    drwxr-xr-x 23 root root 4.0K 2018-11-15 07:10 2018-11-25T03-00-01_longterm/
    drwxr-xr-x 24 root root 4.0K 2018-12-22 07:23 2018-12-30T03-00-01_longterm/
    drwxr-xr-x 24 root root 4.0K 2018-12-22 07:23 2019-01-01T03-00-01/
    drwxr-xr-x 24 root root 4.0K 2018-12-22 07:23 2019-01-02T03-00-01/
    drwxr-xr-x 24 root root 4.0K 2018-12-22 07:23 2019-01-03T03-00-01/
    drwxr-xr-x 24 root root 4.0K 2018-12-22 07:23 2019-01-04T03-00-01/
    drwxr-xr-x 24 root root 4.0K 2018-12-22 07:23 2019-01-05T03-00-01/
    drwxr-xr-x 24 root root 4.0K 2018-12-22 07:23 2019-01-06T03-00-01/
    drwxr-xr-x 24 root root 4.0K 2018-12-22 07:23 2019-01-07T03-00-01/
    lrwxrwxrwx  1 root root   19 2019-01-07 04:07 latest -> 2019-01-07T03-00-01/
    drwxr-xr-x  2 root root  16K 2019-01-07 04:07 logs/
    drwx------  2 root root  16K 2015-12-12 00:04 lost+found/
    -rw-r--r--  1 root root    0 2018-11-07 11:43 valid_backup_disk
    root@server:/mnt/backup#

## Backup to local destination

    sudo su
    cd /opt
    git clone https://github.com/dersimn/linux-incremental-backup

Edit the variables in the upper part of the script according to your needs, then

    crontab -e

and add a line like

    0 3 * * * bash /opt/timemachine/backup_local.bash

to your cron list.

## Backup to remote destination (rsync daemon)

### Setup rsyncd on the remote machine using Docker

Start a Docker Container and give the destination for the backups (for e.g. a USB drive). In this example backups will go to `/mnt/backup`:

	docker run -d --restart=always --name=rsyncd -p 873:873 -v /mnt/backup:/data -e USERNAME=test -e PASSWORD=test -e ALLOW="10.30.51.0/24 127.0.0.1/32" axiom/rsync-server

### Setup a cron job on your local machine

    sudo su
    cd /opt
    git clone https://github.com/dersimn/linux-incremental-backup

Edit the variables in the upper part of the script according to your needs, then

    crontab -e

and add a line like

    0 3 * * * bash /opt/timemachine/backup_remote.bash

to your cron list.

## Clean old backups

The script attaches a `_longterm` suffix for backups created on the last Sunday of the month. Use a command similar to

	ls -1 | grep "^2017-08-[0-9T-]*$" | xargs rm -r
    ls -1 | grep -E "^2019-(09|10)-[0-9T-]*$" | xargs rm -r

to remove folders not ending with `_longterm`.  
You may want to check with `... | xargs echo` which folders are going to be removed.

## See also

<https://github.com/laurent22/rsync-time-backup>