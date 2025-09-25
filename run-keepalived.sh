#!/usr/bin/env bash

# This variable will hold the PID of the background process
child_pid=0

# This function is called when the script receives a SIGTERM signal
function cleanup() {
  echo "Graceful shutdown requested..."

  echo "Removing set VIPs"
  # for vip in $VIP_ADDRESSES; do
  #   /app/vip-down.sh "$HOST_INTERFACE" "$vip"
  # done

  # If a child process is running, send it a SIGTERM
  if [ $child_pid -ne 0 ]; then
    echo "Sending SIGTERM to child process $child_pid"
    # Use 'kill -TERM' to send the signal
    kill -TERM "$child_pid"
    # Wait for the child process to terminate
    wait "$child_pid"
    echo "Child process terminated."
  fi

  echo "Shutdown complete."
  # Exit with a success code
  exit 0
}

# 'trap' sets up a command to be executed when a specific signal is received.
# Here, we are telling the script to call our 'cleanup' function on SIGTERM.
trap 'cleanup' SIGTERM

# --- Main Application Logic ---
echo "Starting main process..."

# Associative array for default parameters
declare -A DEFAULTS
DEFAULTS=(
  [VID]="VI_1"
  [STATE]="MASTER"
  [ROUTER_ID]="51"
  [AUTH_TYPE]="PASS"
  [AUTH_PASS]="1111"
  [PRIORITY]="100"
  [ADVERT_INT]="1"
)

APP_CONFIG=/app/keepalived.conf

# Required parameters - now VIP_ADDRESSES
REQUIRED_PARAMS=("VIP_ADDRESSES" "HOST_INTERFACE")
MISSING_PARAMS=()

# Check for required parameters
for param in "${REQUIRED_PARAMS[@]}"; do
  if [ -z "${!param}" ]; then
    MISSING_PARAMS+=("$param")
  fi
done

if [ ${#MISSING_PARAMS[@]} -gt 0 ]; then
  echo "You must provide the following environment variables: ${MISSING_PARAMS[*]}"
  exit 255
fi

# Override defaults with environment variables if they are set
VID=${VID:-${DEFAULTS[VID]}}
STATE=${STATE:-${DEFAULTS[STATE]}}
ROUTER_ID=${ROUTER_ID:-${DEFAULTS[ROUTER_ID]}}
AUTH_TYPE=${AUTH_TYPE:-${DEFAULTS[AUTH_TYPE]}}
AUTH_PASS=${AUTH_PASS:-${DEFAULTS[AUTH_PASS]}}
PRIORITY=${PRIORITY:-${DEFAULTS[PRIORITY]}}
ADVERT_INT=${ADVERT_INT:-${DEFAULTS[ADVERT_INT]}}

# Generate keepalived.conf
# Start with the main block
cat >"$APP_CONFIG" <<EOF
vrrp_instance ${VID} {
    state ${STATE}
    interface ${HOST_INTERFACE}
    virtual_router_id ${ROUTER_ID}
    priority ${PRIORITY}
    advert_int ${ADVERT_INT}
    authentication {
        auth_type ${AUTH_TYPE}
        auth_pass ${AUTH_PASS}
    }
    virtual_ipaddress {
EOF

# Add VIP addresses from the space-separated VIP_ADDRESSES variable
for vip in $VIP_ADDRESSES; do
  echo "        ${vip} dev ${HOST_INTERFACE}" >>"$APP_CONFIG"
done

# Close the blocks
cat >>"$APP_CONFIG" <<EOF
    }
}
EOF

echo "--- keepalived.conf content ---"
cat "$APP_CONFIG" | sed -e 's/auth_pass .*/auth_pass #REDACTED#/g'
echo "---------------------------------"

# Start keepalived in the background to be able to trap signals
/usr/sbin/keepalived -f "$APP_CONFIG" --dont-fork --dump-conf --log-console --log-detail --log-facility 7 &
child_pid=$!

echo "keepalived process started with PID: $child_pid"

# Wait for the child process to finish
wait "$child_pid"
