#!/bin/bash
set -e

# Copy the template config to the actual config
cp /etc/dnsmasq.conf.template /etc/dnsmasq.conf

# Display the contents of the config file
echo "Contents of dnsmasq.conf:"
cat /etc/dnsmasq.conf

# Try to resolve pihole using Docker DNS first
PIHOLE_IP=$(getent hosts pihole | awk '{ print $1 }')

if [ -n "$PIHOLE_IP" ]; then
    echo "# Pi-hole IP resolved to $PIHOLE_IP" >> /etc/dnsmasq.conf
    echo "server=$PIHOLE_IP" >> /etc/dnsmasq.conf
    echo "Using Pi-hole at $PIHOLE_IP as primary DNS server"
else
    echo "WARNING: Could not resolve Pi-hole container. Using fallback DNS servers only."
fi

# Start dnsmasq in foreground mode
exec dnsmasq -k