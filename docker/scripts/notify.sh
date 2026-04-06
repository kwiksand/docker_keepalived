#!/usr/bin/env bash
# Keepalived VRRP state-change notify script template
#
# Called by keepalived when an instance changes state.
# Arguments:
#   $1 = type   (GROUP | INSTANCE)
#   $2 = name   (the vrrp_instance or vrrp_group name)
#   $3 = state  (MASTER | BACKUP | FAULT)
#
# Reference in keepalived.conf:
#   vrrp_instance VI_1 {
#       ...
#       notify /etc/keepalived/scripts/notify.sh
#   }

TYPE="$1"
NAME="$2"
STATE="$3"

LOGFILE="/var/log/keepalived-notify.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') [${TYPE}] ${NAME} -> ${STATE}" >> "${LOGFILE}"

case "${STATE}" in
    MASTER)
        # Actions to perform when becoming MASTER
        # e.g. start a service, send an alert, update DNS
        echo "$(date '+%Y-%m-%d %H:%M:%S') Became MASTER for ${NAME}" >> "${LOGFILE}"
        ;;
    BACKUP)
        # Actions to perform when transitioning to BACKUP
        echo "$(date '+%Y-%m-%d %H:%M:%S') Became BACKUP for ${NAME}" >> "${LOGFILE}"
        ;;
    FAULT)
        # Actions to perform on FAULT (health check failed)
        echo "$(date '+%Y-%m-%d %H:%M:%S') FAULT detected for ${NAME}" >> "${LOGFILE}"
        ;;
    *)
        echo "$(date '+%Y-%m-%d %H:%M:%S') Unknown state '${STATE}' for ${NAME}" >> "${LOGFILE}"
        ;;
esac

exit 0
