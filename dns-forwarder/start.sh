#!/bin/sh
set -e

# Configure DNS servers
PIHOLE_IP=$(getent hosts pihole | awk '{ print $1 }')
if [ -n "$PIHOLE_IP" ]; then
    echo "Found Pi-hole at IP $PIHOLE_IP"
    PRIMARY_DNS="$PIHOLE_IP"
else
    echo "WARNING: Could not resolve Pi-hole container. Using Cloudflare as primary."
    PRIMARY_DNS="1.1.1.1"
fi

# Secondary DNS for failover
SECONDARY_DNS="8.8.8.8"
TERTIARY_DNS="1.0.0.1"

echo "Starting DNS forwarder..."
echo "Primary DNS: $PRIMARY_DNS"
echo "Secondary DNS: $SECONDARY_DNS"
echo "Tertiary DNS: $TERTIARY_DNS"

# Test connection at startup
echo "Testing DNS servers..."
for DNS in "$PRIMARY_DNS" "$SECONDARY_DNS" "$TERTIARY_DNS"; do
    echo "Testing $DNS..."
    if nslookup -timeout=2 google.com $DNS > /dev/null 2>&1; then
        echo "✓ $DNS is working"
    else
        echo "✗ $DNS failed test"
    fi
done

# Function to start forwarders
start_forwarders() {
    local dns_server="$1"
    echo "$(date): Starting forwarders using DNS server: $dns_server"
    
    # Kill any existing forwarders
    pkill -f "socat.*UDP4-LISTEN:53" 2>/dev/null || true
    pkill -f "socat.*TCP4-LISTEN:53" 2>/dev/null || true
    
    # Start UDP forwarder
    socat -d UDP4-LISTEN:53,fork UDP4:$dns_server:53 &
    UDP_PID=$!
    
    # Start TCP forwarder
    socat -d TCP4-LISTEN:53,fork TCP4:$dns_server:53 &
    TCP_PID=$!
    
    echo "Forwarders started. UDP PID: $UDP_PID, TCP PID: $TCP_PID"
}

# Start with primary
ACTIVE_DNS="$PRIMARY_DNS"
start_forwarders "$ACTIVE_DNS"

# Variables for health check state tracking
FAILURE_COUNT=0
MAX_FAILURES=3
CHECK_INTERVAL=30
RECOVERY_COUNT=0
RECOVERY_THRESHOLD=3

# Monitor DNS health and manage failover
(
    while true; do
        sleep $CHECK_INTERVAL
        
        # Check memory usage and restart if needed to prevent leaks
        MEM_USAGE=$(ps -o rss= -p 1 | awk '{print $1}')
        if [ "$MEM_USAGE" -gt 100000 ]; then  # If over ~100MB
            echo "$(date): High memory usage detected ($MEM_USAGE KB), restarting forwarders"
            start_forwarders "$ACTIVE_DNS"
            continue
        fi
        
        # Test current DNS server
        if nslookup -timeout=1 google.com $ACTIVE_DNS > /dev/null 2>&1; then
            # Current DNS is working
            if [ "$ACTIVE_DNS" != "$PRIMARY_DNS" ]; then
                # We're on a backup server, check if primary is back
                RECOVERY_COUNT=$((RECOVERY_COUNT + 1))
                echo "$(date): Backup DNS working. Recovery count: $RECOVERY_COUNT/$RECOVERY_THRESHOLD"
                
                if [ $RECOVERY_COUNT -ge $RECOVERY_THRESHOLD ]; then
                    # Try primary again
                    if nslookup -timeout=1 google.com $PRIMARY_DNS > /dev/null 2>&1; then
                        echo "$(date): Primary DNS recovered! Switching back."
                        ACTIVE_DNS="$PRIMARY_DNS"
                        start_forwarders "$ACTIVE_DNS"
                        RECOVERY_COUNT=0
                    else
                        echo "$(date): Primary DNS still down."
                    fi
                fi
            else
                # Reset failure count, primary is working
                FAILURE_COUNT=0
                if [ $((CHECK_INTERVAL % 300)) -eq 0 ]; then
                    echo "$(date): Primary DNS check successful"
                fi
            fi
        else
            # Current DNS is failing
            FAILURE_COUNT=$((FAILURE_COUNT + 1))
            echo "$(date): DNS check failed! Failure count: $FAILURE_COUNT/$MAX_FAILURES"
            
            if [ $FAILURE_COUNT -ge $MAX_FAILURES ]; then
                echo "$(date): Too many failures, switching DNS servers"
                
                # Determine next DNS server
                if [ "$ACTIVE_DNS" = "$PRIMARY_DNS" ]; then
                    ACTIVE_DNS="$SECONDARY_DNS"
                    echo "$(date): Switching to secondary DNS: $ACTIVE_DNS"
                elif [ "$ACTIVE_DNS" = "$SECONDARY_DNS" ]; then
                    ACTIVE_DNS="$TERTIARY_DNS"
                    echo "$(date): Switching to tertiary DNS: $ACTIVE_DNS"
                else
                    # Try primary again as a last resort
                    ACTIVE_DNS="$PRIMARY_DNS"
                    echo "$(date): Trying primary DNS again: $ACTIVE_DNS"
                fi
                
                start_forwarders "$ACTIVE_DNS"
                FAILURE_COUNT=0
                RECOVERY_COUNT=0
            fi
        fi
    done
) &

# Watch for zombie processes and clean up
(
    while true; do
        sleep 300  # Every 5 minutes
        echo "$(date): Checking for zombie processes"
        
        # Count zombies and restart if needed
        ZOMBIES=$(ps axo stat | grep -c Z)
        if [ "$ZOMBIES" -gt 5 ]; then
            echo "$(date): Detected $ZOMBIES zombie processes, restarting forwarders"
            start_forwarders "$ACTIVE_DNS"
        fi
    done
) &

# Wait for all background processes
wait