#!/bin/bash

set -eu

cd /media/rgatti/backup

TODAY=$(date +"%Y-%m-%d")

# stop a backup already exists for today
if [ -d daily.0 ]; then
	LAST_BACKUP=$(stat --format=%y daily.0 | cut -f1 -d\  )
	if [ "$TODAY" == "$LAST_BACKUP" ]; then
		exit
	fi
fi

# rotate backups
if [ -d daily.3 ]; then
	rm -rf daily.3
fi
if [ -d daily.2 ]; then
	mv daily.2 daily.3
fi
if [ -d daily.1 ]; then
	mv daily.1 daily.2
fi
if [ -d daily.0 ]; then
	mv daily.0 daily.1
fi

cp -al hourly.0 daily.0

echo $TODAY > daily.log
