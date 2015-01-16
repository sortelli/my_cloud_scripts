#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"

if [ "$#" != "2" ]; then
  echo "usage: backup_timemachine.sh source_dir target_dir"
  exit 1
fi

source=$1                                    #/nfs/HomeCloudTimeMachine
target_root=$2                               #/usb_backup_disk
target="${target_root}/$(basename $source)"  #/usb_backup_disk/HomeCloudTimeMachine"
last_week="${target_root}/last_week"

sleep_time=100
lock_file=./tm_backup.pid
fail_file=./tm_backup.stop
sync_log=./tm_backup.log

function sync_dir() {
  src=$1
  dst=$2

  echo "[$(date)]: Starting sync of $src -> $dst" >> "$sync_log"
  rsync -av --delete "$src" "$dst"                >> "$sync_log" 2>&1
  echo "[$(date)]: Finished sync of $src -> $dst" >> "$sync_log"
  echo ""                                         >> "$sync_log"
}

function safe_sync() {
  src=$1
  dst=$2

  # Wait until all current TimeMachine backups are finished
  while [ "$(macusers  | grep -v ^PID | grep -v "root.*root")" != "" ]; do
    sleep $sleep_time
  done

  sync_dir "$source" "$target_root"
}

function send_error_alert() {
  wd_alert="/usr/local/sbin/sendAlert.sh"

  if [ -x "$wd_alert" ]; then
    # Publish error about missing backup disk using existing
    # WD My Cloud alert facility.
    "$wd_alert" 1100 "$target" "no" "good" "backup_timemachine.sh"

    # For some reason, that doesn't seem to actually send an email.
    # The above script will hit /rest/alert_notify which returns:
    #   "alert_notify_status": "NO_ALERT_EMAIL_HAS_BEEN_SENT"
    # Maybe I need to try different alert codes above.  I don't feel
    # like digging through their stupid php code to debug. Will just
    # send a test email instead.
    curl -XPOST -d "format=json" 'http://127.0.0.1/api/2.1/rest/alert_test_email' > /dev/null 2>&1
  else
    echo "Error: ${target} does not exist"
  fi
}

if [ -f "$fail_file" ]; then
  exit 2
fi

if [ -e "${lock_file}" ] && kill -0 `cat "${lock_file}"`; then
  exit 3
fi

if [ ! -d "$target" ]; then
  touch "$fail_file"
  send_error_alert
  exit 4
fi

trap "rm -f "${lock_file}"; exit 0" INT TERM EXIT
echo $$ > "${lock_file}"

sync_dir  "$target" "$last_week"

safe_sync "$source" "$target_root"
sleep $sleep_time
safe_sync "$source" "$target_root"

cat "$sync_log" >> "${target_root}/$(basename "$sync_log")"
rm "$sync_log"

rm -f "${lock_file}"

exit 0
