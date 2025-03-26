#!/bin/sh
set -e

# Try to resolve pihole using Docker DNS
PIHOLE_IP=$(getent hosts pihole | awk '{ print $1 }')

if [ -n "$PIHOLE_IP" ]; then
    echo "Found Pi-hole at IP $PIHOLE_IP"
    PRIMARY_DNS="$PIHOLE_IP"
else
    echo "WARNING: Could not resolve Pi-hole container. Using Cloudflare as primary."
    PRIMARY_DNS="1.1.1.1"
fi

# Secondary DNS servers for failover
SECONDARY_DNS="8.8.8.8"

echo "Starting DNS forwarder..."
echo "Primary DNS: $PRIMARY_DNS"
echo "Backup DNS: $SECONDARY_DNS"

# Test primary DNS
echo "Testing primary DNS at $PRIMARY_DNS..."
if nslookup -timeout=2 google.com $PRIMARY_DNS > /dev/null 2>&1; then
    echo "Primary DNS is working!"
else
    echo "WARNING: Primary DNS failed test. Will try secondary."
    PRIMARY_DNS="$SECONDARY_DNS"
    SECONDARY_DNS="1.0.0.1"
fi

# Start UDP forwarder (primary)
echo "Starting UDP forwarder on port 53 -> $PRIMARY_DNS:53"
socat -d UDP4-LISTEN:53,fork UDP4:$PRIMARY_DNS:53 &

# Start TCP forwarder (primary)
echo "Starting TCP forwarder on port 53 -> $PRIMARY_DNS:53"
socat -d TCP4-LISTEN:53,fork TCP4:$PRIMARY_DNS:53 &

# Keep container running
echo "DNS Forwarder started successfully"
# Wait forever
tail -f /dev/null