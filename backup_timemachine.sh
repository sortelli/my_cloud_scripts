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

  while [ "$(macusers  | grep -v ^PID | grep -v "root.*root")" != "" ]; do
    sleep 100
  done

  sync_dir "$source" "$target_root"
}

function send_error_alert() {
  wd_alert="/usr/local/sbin/sendAlert.sh"
  if [ -x "$wd_alert" ]; then
    "$wd_alert" 1100 "$target" "no" "good" "backup_timemachine.sh"
    curl -XPOST -d "format=json" 'http://127.0.0.1/api/1.0/rest/alert_notify' > /dev/null 2>&1
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
sleep 100
safe_sync "$source" "$target_root"

rm -f "${lock_file}"

exit 0
