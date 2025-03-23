# Autostarting Pi-hole DNS with systemd

This guide explains how to set up your Pi-hole DNS stack to automatically start when your system boots using systemd.

## Why Use systemd?

systemd is the init system used by most modern Linux distributions, including Ubuntu. Using systemd to manage your Docker Compose services provides several benefits:

1. **Automatic startup** when your system boots
2. **Proper dependency management** (ensuring Docker is running first)
3. **Better logging** through the systemd journal
4. **Easier management** using standard systemctl commands
5. **Failure handling** and automatic restart capabilities

## Setting Up the systemd Service

Follow these steps to configure your Pi-hole DNS stack to start automatically:

### 1. Create the service file

```bash
sudo nano /etc/systemd/system/pihole-dns.service
```

### 2. Add the following configuration

```ini
[Unit]
Description=Pi-hole DNS with Failover
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/YOUR_USERNAME/digital-citadel-lite
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
```

Make sure to replace `/home/YOUR_USERNAME/digital-citadel-lite` with the actual path where your docker-compose.yml file is located. (use ```pwd``` to find the path)

### 3. Save the file and exit the editor

Press `Ctrl+X`, then `Y`, then `Enter` to save and exit if you're using nano.

### 4. Reload systemd to recognize the new service

```bash
sudo systemctl daemon-reload
```

### 5. Enable the service to start on boot

```bash
sudo systemctl enable pihole-dns.service
```

### 6. Start the service immediately

```bash
sudo systemctl start pihole-dns.service
```

### 7. Verify the service is running properly

```bash
sudo systemctl status pihole-dns.service
```

You should see output indicating the service is active and running.

## Understanding the Service Configuration

The systemd service file has several important components:

- **[Unit] Section:**
  - `Description`: A human-readable description of the service
  - `Requires`: Specifies that this service needs docker.service to run
  - `After`: Ensures this service starts only after docker.service is running

- **[Service] Section:**
  - `Type=oneshot`: Indicates this service runs a single command and exits
  - `RemainAfterExit=yes`: Keeps the service "active" even after the command completes
  - `WorkingDirectory`: The absolute path where your docker-compose.yml is located
  - `ExecStart`: The command to start your containers
  - `ExecStop`: The command to stop your containers

- **[Install] Section:**
  - `WantedBy=multi-user.target`: Makes the service start when the system reaches multi-user mode

## Managing the Service

### Checking service status

```bash
sudo systemctl status pihole-dns.service
```

### Stopping the service

```bash
sudo systemctl stop pihole-dns.service
```

### Starting the service

```bash
sudo systemctl start pihole-dns.service
```

### Disabling autostart

```bash
sudo systemctl disable pihole-dns.service
```

### Viewing service logs

```bash
sudo journalctl -u pihole-dns.service
```