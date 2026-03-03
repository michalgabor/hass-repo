#!/bin/bash
set -e

DATA_DIR="/data"
USERDATA_DIR="/opt/domoticz/userdata"

# First run: initialize /data from default userdata content
if [ ! -f "${DATA_DIR}/.initialized" ]; then
    echo "[domoticz] First run: initializing ${DATA_DIR} from default userdata..."
    cp -rn "${USERDATA_DIR}/." "${DATA_DIR}/" 2>/dev/null || true
    touch "${DATA_DIR}/.initialized"
fi

# Restore persisted data from /data to the Docker volume
echo "[domoticz] Restoring data from ${DATA_DIR} to ${USERDATA_DIR}..."
rsync -a "${DATA_DIR}/" "${USERDATA_DIR}/"

# Periodic sync back to /data (every 5 minutes)
periodic_sync() {
    while true; do
        sleep 300
        rsync -a --update "${USERDATA_DIR}/" "${DATA_DIR}/" 2>/dev/null || true
    done
}
periodic_sync &
SYNC_PID=$!

# Handle shutdown: final sync and stop domoticz
cleanup() {
    echo "[domoticz] Shutdown: syncing ${USERDATA_DIR} to ${DATA_DIR}..."
    rsync -a --update "${USERDATA_DIR}/" "${DATA_DIR}/" 2>/dev/null || true
    kill "${SYNC_PID}" 2>/dev/null || true
    if [ -n "${DOMOTICZ_PID}" ]; then
        kill "${DOMOTICZ_PID}" 2>/dev/null || true
        wait "${DOMOTICZ_PID}" 2>/dev/null || true
    fi
}
trap cleanup SIGTERM SIGINT SIGHUP

# Start domoticz via original entrypoint
docker-entrypoint.sh "$@" &
DOMOTICZ_PID=$!
wait "${DOMOTICZ_PID}"
cleanup
