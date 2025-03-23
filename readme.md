## How It Works

This system uses a carefully designed DNS forwarding chain:

1. **Unbound** serves as your primary DNS server (exposed on port 53)
2. Unbound forwards DNS requests to **Pi-hole** first
3. Pi-hole provides ad-blocking and forwards clean requests to **Cloudflared** (DNS-over-HTTPS)
4. If Pi-hole becomes unavailable, Unbound automatically fails over to the fallback DNS (default: 1.1.1.1)

This setup ensures:
- Only one DNS server is needed in your router/DHCP configuration
- Transparent fallback if any component fails
- Ad-blocking under normal circumstances
- Internet access continues to work even if Pi-hole crashes# Single-point DNS with Automatic Failover

This repository contains Docker Compose configuration for a home network DNS setup with built-in failover capabilities. It provides a single DNS server address with automatic fallbacks if Pi-hole ever fails.

## Overview

This setup provides:
- **Single DNS entry point**: Only one DNS address needs to be configured in your router
- **Automatic failover**: If Pi-hole fails, DNS requests fall back to public DNS servers
- **Pi-hole**: Network-wide ad blocking with web interface
- **Cloudflared**: DNS-over-HTTPS for enhanced privacy
- **Unbound**: Front-end DNS resolver that manages failover
- **Watchtower**: Automatic container updates during scheduled maintenance windows
- **Healthchecks**: Automatic container restarts if services fail

## Prerequisites

- Docker and Docker Compose installed on your system
- Basic knowledge of Docker and networking
- Port 53 available on your host (or configured to use a different port)

## Directory Structure

```
/container_data/
├── pihole/
│   ├── etc-pihole/         # Pi-hole configuration
│   └── etc-dnsmasq.d/      # Custom DNS configurations
└── unbound/
    └── etc/                # Unbound DNS resolver configuration
```

## Installation

1. Create the data directory structure:

```bash
sudo mkdir -p /container_data/pihole/etc-pihole /container_data/pihole/etc-dnsmasq.d /container_data/unbound/etc
```

2. Clone this repository or create the Docker Compose and .env files:

```bash
# Clone the repository (if available)
# git clone <repository-url>
# OR
# Create a directory for the configuration files
mkdir -p ~/pihole-setup
cd ~/pihole-setup
```

3. Create the `docker-compose.yml` and `.env` files from this repository.

4. Update the volume paths in `docker-compose.yml` to use the `/container_data` directory:

```yaml
volumes:
  - /container_data/pihole/etc-pihole:/etc/pihole
  - /container_data/pihole/etc-dnsmasq.d:/etc/dnsmasq.d
```

5. Modify the `.env` file to set your preferred configuration:
   - Change `PIHOLE_WEBPASSWORD` to a secure password
   - Set `SERVER_IP` to your server's static local IP address
   - Update the timezone to match your location
   - Set `PIHOLE_VERSION` to pin a specific Pi-hole version (recommended for stability)
   - Adjust `WATCHTOWER_SCHEDULE` to set automatic update times (default: 4 AM on Sundays)
   - Configure notification settings if desired (email, Slack, etc.)

6. Start the containers:

```bash
docker-compose up -d
```

## Usage

### Configuring Your Router

1. Set your router's DHCP to distribute **only your server's IP address** as the DNS server
2. Make sure your server has a static IP address

### Accessing Pi-hole

- Web interface: `http://your-server-ip` (port 80)
- Default login: The password you set in the `.env` file

### DNS Resolution Flow

```
Your Devices → Router → Unbound (port 53) → Pi-hole → Cloudflared → Internet
                                  ↓
                         Fallback DNS (if Pi-hole fails)
```

## Maintenance

### Automatic Updates

Watchtower is configured to automatically update all containers according to the schedule in your `.env` file. By default, this happens at 4 AM on Sundays to minimize disruption.

### Manual Updates (if needed)

```bash
docker-compose pull
docker-compose up -d
```

### Viewing Logs

```bash
# View Pi-hole logs
docker-compose logs pihole

# View Cloudflared logs
docker-compose logs cloudflared

# View Watchtower logs (to check update status)
docker-compose logs watchtower
```

### Backup

The important data is stored in the `/container_data` directory. Back up this directory to preserve your configuration:

```bash
# Simple backup script
tar -czf pihole-backup-$(date +%Y%m%d).tar.gz /container_data
```

### Version Pinning

For maximum stability, the `.env` file allows you to pin the Pi-hole version. After a new version has been released and proven stable, you can update the `PIHOLE_VERSION` value.

## Troubleshooting

- **Cannot access Pi-hole web interface**: Check if the container is running with `docker-compose ps`
- **No internet connection**: 
  1. Check if Unbound is running: `docker-compose logs unbound`
  2. Verify the fallback DNS is working: `docker exec -it unbound dig @1.1.1.1 google.com`
- **Testing failover**: You can test the fallback by stopping Pi-hole: `docker-compose stop pihole`
  - Internet should still work through the fallback DNS
  - Start Pi-hole again with: `docker-compose start pihole`
- **Container update issues**: Check Watchtower logs with `docker-compose logs watchtower`

## Family-Friendly Setup Features

- **Zero configuration for family members**: They never need to change DNS settings
- **Completely transparent failover**: Internet keeps working even if Pi-hole fails
- **Scheduled updates**: Updates happen at night during low-usage hours (configurable)
- **Health monitoring**: Services automatically restart if they become unhealthy
- **Version pinning**: Prevents unexpected breaking changes from Pi-hole updates

## Security Considerations

- The default configuration exposes Pi-hole's web interface to your local network
- Consider setting up authentication for additional security
- Regularly update your containers for security patches

## License

This project is shared under the MIT License.