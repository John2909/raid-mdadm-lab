#!/bin/bash
# raid-alert.sh : appelé par mdadm --monitor à chaque événement RAID
# Arguments passés par mdadm :
#   $1 = nom de l'événement (Fail, DegradedArray, RebuildFinished...)
#   $2 = périphérique RAID concerné (/dev/md0)
#   $3 = disque concerné (peut être absent)

LOG="/var/log/raid-alerts.log"
EVENT="$1"
RAID="$2"
DISK="${3:-aucun}"

MESSAGE="$(date '+%F %T') evenement=${EVENT} raid=${RAID} disque=${DISK}"

echo "${MESSAGE}" >> "${LOG}"
logger -t raid-alert -p daemon.warning "${MESSAGE}"