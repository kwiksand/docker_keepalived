#!/usr/bin/env bash
# Keepalived VRRP health check script template
#
# Return codes:
#   0  = healthy  (keepalived stays in current state)
#   1+ = unhealthy (keepalived transitions to FAULT state)
#
# Reference in keepalived.conf:
#   vrrp_script chk_service {
#       script "/etc/keepalived/scripts/check_script.sh"
#       interval 2    # check every 2 seconds
#       weight -20    # reduce priority by 20 on failure
#       fall 3        # require 3 failures before FAULT
#       rise 2        # require 2 successes before recovering
#   }
#
#   vrrp_instance VI_1 {
#       ...
#       track_script {
#           chk_service
#       }
#   }

# Example: check that a service is running
# SERVICE="haproxy"
# if ! pgrep -x "${SERVICE}" > /dev/null; then
#     exit 1
# fi

# Example: check HTTP endpoint
# if ! curl -sf http://127.0.0.1/health > /dev/null; then
#     exit 1
# fi

# Default: always healthy
exit 0
