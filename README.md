# my_cloud_scripts

This repo is a collection of scripts that run on a Western Digital
My Cloud NAS storage device.

I am currently running these against Firmware version ```v04.01.02-417```.

## Scripts

### backup_timemachine.sh

I primarily use my WD My Cloud for Timemachine backups of my Macs.
Since Timemachine over WiFi can occasionally result in corrupted
backups, I wanted to have a few weekly snapshots of the Timemachine
backups.  If the live backups get corrupted, I could replace them
with one of the recent snapshots.

I'm keeping the snapshots on an external USB disk plugged into the
NAS, which also protects against disk failure on the NAS device.
The ```backup_timemachine.sh``` script will send an email through
the My Cloud alert infrastructure if the backup disk is not found.

#### Usage

Optionally mount a USB disk to the NAS (using the built-in My Cloud
USB disk automount, or manually into a specific location) and setup
a weekly cronjob to call ```backup_timemachine.sh```.

Example:

```bash
0 4 * * 0 /root/my_cloud_scripts/backup_timemachine.sh /nfs/TimeMachineBackup /path/to/my/backup/directory
```
