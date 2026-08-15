#!/bin/bash
set -e

# Generate nut.conf (Set operational mode to netclient)
cat <<EOF > /etc/nut/nut.conf
MODE=netclient
EOF

# Generate upsmon.conf (Monitor upstream server)
cat <<EOF > /etc/nut/upsmon.conf
MONITOR ${UPS_NAME}@${UPSTREAM_HOST}:${UPSTREAM_PORT} 1 ${UPSTREAM_USER} ${UPSTREAM_PASS} slave
MINSUPPLIES 1
SHUTDOWNCMD "/sbin/shutdown -h now"
POLLFREQ 5
POLLFREQALERT 2
HOSTSYNC 15
DEADTIME 15
POWERDOWNFLAG /etc/killpower
EOF

# Generate upsd.conf (Listen on all interfaces for local clients)
cat <<EOF > /etc/nut/upsd.conf
LISTEN 0.0.0.0 3493
EOF

# Generate upsd.users (Allow downstream client access)
cat <<EOF > /etc/nut/upsd.users
[${CLIENT_USER}]
    password = ${CLIENT_PASS}
    upsmon slave
    actions = SET
    instcmds = ALL
EOF

# Set secure permissions on configuration files
chown -R nut:nut /etc/nut
chmod 640 /etc/nut/*.conf /etc/nut/upsd.users

echo "Starting NUT service in netclient mode..."
echo "Monitoring upstream: ${UPS_NAME}@${UPSTREAM_HOST}:${UPSTREAM_PORT}"

# Start upsd daemon to serve downstream connections
upsd -u nut

# Run upsmon in foreground to maintain container process
exec upsmon -F