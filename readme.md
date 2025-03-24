# Pi-hole Docker Compose with Cloudflared DNS-over-HTTPS

This repository contains a simple Docker Compose configuration to run Pi-hole v6 with Cloudflared DNS-over-HTTPS for encrypted DNS resolution. This setup is perfect for home networks wanting to block ads and enhance privacy.

## Overview

This setup provides:
- **Pi-hole v6**: Network-wide ad blocking with easy-to-use web interface
- **Cloudflared**: DNS-over-HTTPS for enhanced privacy and security
- **Simple configuration**: Easy to set up and maintain
- **Persistent storage**: Your configurations are saved between container restarts

## Quick Start

1. Create a directory for your Pi-hole setup:
```bash
git clone https://github.com/haleth-embershield/digital-citadel-lite
cd digital-citadel-lite
mkdir container_data/pihole/etc-pihole
```

2. Create a `docker-compose.yml` file with the following content:
```yaml
services:
  cloudflared:
    container_name: cloudflared
    image: cloudflare/cloudflared:latest
    restart: unless-stopped
    command: 'proxy-dns --port 5053 --upstream https://dns.cloudflare.com/dns-query --upstream https://dns.google/dns-query'
    networks:
      - dns_network
    
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    restart: unless-stopped
    ports:
      # DNS Ports
      - "53:53/tcp"
      - "53:53/udp"
      # Default HTTP Port
      - "80:80/tcp"
      # Default HTTPS Port. FTL will generate a self-signed certificate
      - "443:443/tcp"
      # Uncomment the line below if you want Pi-hole as your DHCP server
      #- "67:67/udp"
    environment:
      # Set your timezone
      TZ: ${TIMEZONE:-America/New_York}
      # Web interface password (use a strong password)
      FTLCONF_webserver_api_password: ${PIHOLE_WEBPASSWORD:-admin}
      # Configure Pi-hole to use cloudflared for DNS
      FTLCONF_dns_upstreams: cloudflared#5053
      # Listen on all interfaces
      FTLCONF_dns_listeningMode: all
      # Enable DNSSEC
      FTLCONF_dns_dnssec: true
      # Enable query logging
      FTLCONF_webserver_query_logging: true
      # Set web theme
      FTLCONF_gui_theme: ${WEB_THEME:-default-dark}
    volumes:
      # For persisting Pi-hole's databases and configuration
      - './container_data/pihole/etc-pihole:/etc/pihole'
    depends_on:
      - cloudflared
    networks:
      - dns_network
    cap_add:
      # Required if you are using Pi-hole as your DHCP server
      - NET_ADMIN
      # Optional, gives Pi-hole more processing priority
      - SYS_NICE

networks:
  dns_network:
    driver: bridge
```

3. Create a `.env` file (optional) to configure environment variables:
```
TIMEZONE=America/New_York
PIHOLE_WEBPASSWORD=your_secure_password
WEB_THEME=default-dark
```

4. Start the containers:
```bash
docker compose up -d
```

5. Access the Pi-hole admin interface at `http://your-server-ip/admin`

## Configuring Your Router

1. Set your router's DHCP to distribute your server's IP address as the DNS server
2. Make sure your server has a static IP address

## Troubleshooting

- **Port 53 already in use**: Some systems (like Ubuntu) use systemd-resolved which binds to port 53. To fix:
```bash
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
```

- **Checking logs**:
```bash
# Pi-hole logs
docker logs pihole

# Cloudflared logs
docker logs cloudflared
```

## Updating

To update your containers:
```bash
docker compose pull
docker compose up -d
```

## Advanced Setup

For a more advanced setup with automatic failover using Unbound, refer to the `later_readme.md` file in this repository. That setup provides:
- Automatic DNS failover if Pi-hole becomes unavailable
- More complex but more resilient infrastructure
- Single DNS entry point with built-in redundancy

## Additional Resources

- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [Pi-hole Docker Documentation](https://github.com/pi-hole/docker-pi-hole)