```bash
mkdir -p ./container_data/dnsmasq/
sudo nano ./container_data/dnsmasq/dnsmasq.conf
```

```conf
# Forward to Pi-hole first
server=pihole:53
# Fallback to Cloudflare and Google if Pi-hole chain fails
server=1.1.1.1
server=8.8.8.8
# Use servers in order, only fall back if upstream fails
strict-order
# Don’t resolve locally, just forward
no-resolv
# Listen on all interfaces in the container
listen-address=0.0.0.0
```