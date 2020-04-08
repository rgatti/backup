#!/bin/bash

set -eu

# Configuration
#
BACKUP_ROOT=/media/$USER/backup
FILTER_RULES_FILE="$HOME/.backup-filter"
LOG_FILE="$BACKUP_ROOT/hourly.log"

DRY_RUN=false
RSYNC_ARGS=()

# Print usage and exit.
#
usage() {
	echo "Usage: snapshot_hourly.sh [-n]"
	echo
	echo "-n  dry-run"
	exit 1
}

# Echo a message if dry-run.
#
dry_run_echo() {
	if $DRY_RUN; then
		echo "$@"
	fi
}

# Echo a message if dry-run and return boolean for conditional.
#
# Usage:
# if do_or_echo "doing something"; then
#	echo "actually doing something"
# fi
#
do_or_echo() {
	dry_run_echo "$@"
	$DRY_RUN && return 1
	return 0
}

# Parse script arguments
if [ $# -eq 1 ]; then
	[ "${1:-}" == "-n" ] || usage
	DRY_RUN=true
	RSYNC_ARGS+=(-n)
fi
[ $# -le 1 ] || usage

# Check for filter rules
if [ -f "$FILTER_RULES_FILE" ]; then
	RSYNC_ARGS+=(--filter="merge $FILTER_RULES_FILE")
	if $DRY_RUN; then
		echo "Using filter rules $FILTER_RULES_FILE"
		echo "---"
		cat $FILTER_RULES_FILE
		echo "---"
	fi
fi

# Set log file
if ! [ -z "$LOG_FILE" ]; then
	if do_or_echo "Logging to $LOG_FILE"; then
		RSYNC_ARGS+=(--log-file="$LOG_FILE")
	fi
fi

dry_run_echo "Running backup in $BACKUP_ROOT"

# rotate backups
if [ -d $BACKUP_ROOT/hourly.3 ]; then
	if do_or_echo "rm -rf hourly.3"; then
		rm -rf $BACKUP_ROOT/hourly.3
	fi
fi

if [ -d $BACKUP_ROOT/hourly.2 ]; then
	if do_or_echo "mv hourly.2 hourly.3"; then
		mv $BACKUP_ROOT/hourly.2 $BACKUP_ROOT/hourly.3
	fi
fi
if [ -d $BACKUP_ROOT/hourly.1 ]; then
	if do_or_echo "mv hourly.1 hourly.2"; then
		mv $BACKUP_ROOT/hourly.1 $BACKUP_ROOT/hourly.2
	fi
fi
if [ -d $BACKUP_ROOT/hourly.0 ]; then
	if do_or_echo "mv hourly.0 hourly.1"; then
		mv $BACKUP_ROOT/hourly.0 $BACKUP_ROOT/hourly.1
	fi
fi

rsync "${RSYNC_ARGS[@]}" -av             \
	--delete --delete-excluded           \
	--link-dest=$BACKUP_ROOT/hourly.1    \
	$HOME/ $BACKUP_ROOT/hourly.0

# update mtime
if do_or_echo "touch $BACKUP_ROOT/hourly.0"; then
	touch $BACKUP_ROOT/hourly.0
fi
