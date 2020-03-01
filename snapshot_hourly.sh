#!/bin/bash

set -eu

BACKUP_ROOT=/media/rgatti/backup
EXCLUDE=exclude.txt

cd $BACKUP_ROOT

# rotate backups
if [ -d hourly.3 ]; then
	rm -rf hourly.3
fi
if [ -d hourly.2 ]; then
	mv hourly.2 hourly.3
fi
if [ -d hourly.1 ]; then
	mv hourly.1 hourly.2
fi
if [ -d hourly.0 ]; then
	mv hourly.0 hourly.1
fi

# make empty excludes file if needed
if ! [ -f $EXCLUDE ]; then
	touch $EXCLUDE
fi

rsync -av --delete                               \
	--delete-excluded                        \
	--exclude-from=$BACKUP_ROOT/$EXCLUDE     \
	--link-dest=$BACKUP_ROOT/hourly.1        \
	--log-file=$BACKUP_ROOT/hourly.log       \
	/home/rgatti/ $BACKUP_ROOT/hourly.0

# update mtime
touch $BACKUP_ROOT/hourly.0
