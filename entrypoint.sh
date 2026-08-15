#!/bin/bash
set -e

# Default Variable Values
UPSTREAM_HOST="${UPSTREAM_HOST:-192.168.1.100}"
UPSTREAM_PORT="${UPSTREAM_PORT:-3493}"
UPSTREAM_UPS_NAME="${UPSTREAM_UPS_NAME:-ups}"
UPSTREAM_USER="${UPSTREAM_USER:-monuser}"
UPSTREAM_PASS="${UPSTREAM_PASS:-secret}"

LOCAL_UPS_NAME="${LOCAL_UPS_NAME:-ups}"
CLIENT_USER="${CLIENT_USER:-clientuser}"
CLIENT_PASS="${CLIENT_PASS:-clientpass}"

# Suppress "sh: wall: not found" warning in Alpine
if ! command -v wall &> /dev/null; then
    echo '#!/bin/sh' > /usr/bin/wall
    echo 'exit 0' >> /usr/bin/wall
    chmod +x /usr/bin/wall
fi

cat <<EOF > /etc/nut/nut.conf
MODE=netclient
EOF

# Local upsd daemon advertises LOCAL_UPS_NAME using dummy-ups driver
cat <<EOF > /etc/nut/ups.conf
[${LOCAL_UPS_NAME}]
    driver = dummy-ups
    port = ${UPSTREAM_UPS_NAME}@${UPSTREAM_HOST}:${UPSTREAM_PORT}
    desc = "Proxy for ${UPSTREAM_UPS_NAME}"
EOF

# Local upsmon monitors UPSTREAM_UPS_NAME on the upstream master
cat <<EOF > /etc/nut/upsmon.conf
MONITOR ${UPSTREAM_UPS_NAME}@${UPSTREAM_HOST}:${UPSTREAM_PORT} 1 ${UPSTREAM_USER} ${UPSTREAM_PASS} secondary
MINSUPPLIES 1
SHUTDOWNCMD "/sbin/shutdown -h now"
POLLFREQ 5
POLLFREQALERT 2
HOSTSYNC 15
DEADTIME 15
POWERDOWNFLAG /etc/killpower
EOF

# Listen on port 3493 for local clients
cat <<EOF > /etc/nut/upsd.conf
LISTEN 0.0.0.0 3493
EOF

# Client authentication settings
cat <<EOF > /etc/nut/upsd.users
[${CLIENT_USER}]
    password = ${CLIENT_PASS}
    upsmon secondary
    actions = SET
    instcmds = ALL
EOF

# Set file permissions
chown -R nut:nut /etc/nut /var/run/nut
chmod 640 /etc/nut/*.conf /etc/nut/upsd.users

echo "Starting NUT drivers..."
upsdrvctl -u nut start || true

echo "Starting NUT daemon..."
upsd -u nut

echo "Monitoring upstream: ${UPSTREAM_UPS_NAME}@${UPSTREAM_HOST}:${UPSTREAM_PORT}"
exec upsmon -F