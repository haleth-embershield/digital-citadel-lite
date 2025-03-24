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
mkdir -p container_data/pihole/etc-pihole
```

3. Create a `.env` file to configure environment variables:

```bash
cp .env.example .env
sudo nano .env
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

**Installing on Ubuntu or Fedora**
From https://github.com/pi-hole/docker-pi-hole/blob/master/README.md
Modern releases of Ubuntu (17.10+) and Fedora (33+) include systemd-resolved which is configured by default to implement a caching DNS stub resolver. This will prevent pi-hole from listening on port 53. The stub resolver should be disabled with: ```sudo sed -r -i.orig 's/#?DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf```

This will not change the nameserver settings, which point to the stub resolver thus preventing DNS resolution. Change the /etc/resolv.conf symlink to point to /run/systemd/resolve/resolv.conf, which is automatically updated to follow the system's netplan: ```sudo sh -c 'rm /etc/resolv.conf && ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf'``` After making these changes, you should restart systemd-resolved using ```systemctl restart systemd-resolved```

**I updated my netplan per Claude: see netplan_edit.md**
If you want to explicitly set your docker host's nameservers you can edit the netplan(s) found at /etc/netplan, then run sudo netplan apply.

Example netplan:

network:
    ethernets:
        ens160:
            dhcp4: true
            dhcp4-overrides:
                use-dns: false
            nameservers:
                addresses: [127.0.0.1]
    version: 2
Note that it is also possible to disable systemd-resolved entirely. However, this can cause problems with name resolution in vpns (see bug report).
It also disables the functionality of netplan since systemd-resolved is used as the default renderer (see man netplan).
If you choose to disable the service, you will need to manually set the nameservers, for example by creating a new /etc/resolv.conf.

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