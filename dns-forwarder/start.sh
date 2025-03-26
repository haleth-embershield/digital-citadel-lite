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
echo "Full nslookup output to debug connection:"
nslookup -timeout=5 google.com $PRIMARY_DNS || true

# Try again with details
echo "Trying to ping Pi-hole..."
ping -c 2 $PRIMARY_DNS || true

echo "Checking Pi-hole port 53 with nc..."
nc -zv $PRIMARY_DNS 53 -w 2 || true

# Still use Pi-hole as primary, even if tests fail
# This way we can see actual errors in the forwarder logs
echo "Using Pi-hole as primary DNS regardless of test results"

# Start UDP forwarder (primary)
echo "Starting UDP forwarder on port 53 -> $PRIMARY_DNS:53"
socat -d UDP4-LISTEN:53,fork UDP4:$PRIMARY_DNS:53 &

# Start TCP forwarder (primary)
echo "Starting TCP forwarder on port 53 -> $PRIMARY_DNS:53"
socat -d TCP4-LISTEN:53,fork TCP4:$PRIMARY_DNS:53 &

# Keep container running
echo "DNS Forwarder started successfully"
# Create a background process to monitor and restart forwarders if needed
(
  while true; do
    # Sleep for 30 seconds before checking
    sleep 30
    
    # Test if Pi-hole is responding
    if nslookup -timeout=1 google.com $PRIMARY_DNS > /dev/null 2>&1; then
      echo "$(date): Pi-hole check successful"
    else
      echo "$(date): Primary DNS ($PRIMARY_DNS) not responding, restarting forwarders..."
      
      # Kill existing forwarders
      pkill -f "socat.*UDP4-LISTEN:53" || true
      pkill -f "socat.*TCP4-LISTEN:53" || true
      
      # Sleep briefly
      sleep 2
      
      # Start UDP forwarder
      echo "Restarting UDP forwarder with Primary DNS: $PRIMARY_DNS"
      socat -d UDP4-LISTEN:53,fork UDP4:$PRIMARY_DNS:53 &
      
      # Start TCP forwarder
      echo "Restarting TCP forwarder with Primary DNS: $PRIMARY_DNS"
      socat -d TCP4-LISTEN:53,fork TCP4:$PRIMARY_DNS:53 &
    fi
  done
) &

# Wait forever
wait