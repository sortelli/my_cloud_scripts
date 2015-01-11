#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"

source=/nfs/HomeCloudTimeMachine
target=/usb_backup_disk/HomeCloudTimeMachine
target_root=/usb_backup_disk
last_week=/usb_backup_disk/last_week
lock_file=./tm_backup.pid
fail_file=./tm_backup.stop
sync_log=./tm_backup.log

if [ -f "$fail_file" ]; then
  exit 1
fi

if [ -e "${lock_file}" ] && kill -0 `cat "${lock_file}"`; then
  exit 3
fi

trap "rm -f "${lock_file}"; exit 0" INT TERM EXIT
echo $$ > "${lock_file}"

if [ ! -d "$target" ]; then
  touch "$fail_file"
  sendAlert.sh 1100 "$target" "no" "good" "backup_timemachine.sh"
  curl -XPOST -d "format=json" 'http://127.0.0.1/api/1.0/rest/alert_notify' > /dev/null 2>&1
  exit 2
fi

rsync -av --delete "$target" "$last_week" > "$sync_log" 2>&1

rsync -av --delete "$source" "$target_root" > "$sync_log" 2>&1

while [ "$(macusers  | grep -v ^PID | grep -v "root.*root")" != "" ]; do
  sleep 100
  rsync -av --delete "$source" "$target_root" > "$sync_log" 2>&1
done

rsync -av --delete "$source" "$target_root" > "$sync_log" 2>&1

while [ "$(macusers  | grep -v ^PID | grep -v "root.*root")" != "" ]; do
  sleep 100
  rsync -av --delete "$source" "$target_root" > "$sync_log" 2>&1
done

rsync -av --delete "$source" "$target_root" > "$sync_log" 2>&1

rm -f "${lock_file}"

exit 0
