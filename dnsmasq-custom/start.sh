#!/bin/bash
set -e

# Copy the template config to the actual config
cp /etc/dnsmasq.conf.template /etc/dnsmasq.conf

# Try to resolve pihole using Docker DNS first
PIHOLE_IP=$(getent hosts pihole | awk '{ print $1 }')

if [ -n "$PIHOLE_IP" ]; then
    echo "# Pi-hole IP resolved to $PIHOLE_IP" >> /etc/dnsmasq.conf
    echo "server=$PIHOLE_IP#53" >> /etc/dnsmasq.conf
    echo "Using Pi-hole at $PIHOLE_IP as primary DNS server"
else
    echo "WARNING: Could not resolve Pi-hole container. Using fallback DNS servers only."
fi

# Print the final config for debugging
echo "============================================="
echo "Contents of dnsmasq.conf:"
echo "============================================="
cat /etc/dnsmasq.conf
echo
echo "============================================="

# Test DNS resolution to ensure connectivity
echo "Testing DNS connectivity to Pi-hole..."
nslookup -timeout=3 google.com $PIHOLE_IP || echo "Warning: Direct DNS test to Pi-hole failed"
echo "Testing DNS connectivity to Cloudflare..."
nslookup -timeout=3 google.com 1.1.1.1 || echo "Warning: Direct DNS test to Cloudflare failed"

# Start dnsmasq in foreground mode with verbose logging
exec dnsmasq -k -d