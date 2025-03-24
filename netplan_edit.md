Context: I am on ubuntu 24.04 lts

Claude:
You're on the right track. Since systemd-resolved is disabled and not running, your system will need an alternative DNS configuration. The instructions you followed for resolving port 53 conflicts are correct, but there's a catch - you disabled systemd-resolved but you're still pointing to its configuration file, which isn't being updated anymore.

Here's what's happening:

1. You disabled systemd-resolved (good for running Pi-hole on port 53)
2. Your `/etc/resolv.conf` is a symlink to `/run/systemd/resolve/resolv.conf`
3. But since systemd-resolved isn't running, that file isn't being maintained properly

Let's fix this:

1. First, set up a static resolv.conf file:

```bash
# Remove the symlink
sudo rm /etc/resolv.conf

# Create a new resolv.conf with Google DNS temporarily
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

2. Test if you now have DNS resolution:

```bash
ping -c 3 google.com
```

3. If that works, your host now has DNS resolution. Next, let's update your netplan configuration for a more permanent solution:

```bash
# Find your netplan configuration file
ls /etc/netplan/

# Edit the file (replace with your actual filename)
sudo nano /etc/netplan/*.yaml
```

4. Make sure the file includes DNS nameservers. It should look something like this:

```yaml
network:
  version: 2
  ethernets:
    # Your network interface name (might be different)
    ens18:
      dhcp4: true
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
```

5. Apply the netplan changes:

```bash
sudo netplan apply
```

6. Now restart your Pi-hole container and update gravity:

```bash
docker restart pihole
docker exec pihole pihole -g
```

Your Pi-hole should now have working DNS resolution and be able to update its gravity database correctly. Once Pi-hole is fully working, you can consider changing your host's DNS to use Pi-hole itself (loopback address 127.0.0.1), creating a self-contained setup.

Note: Make sure your `/etc/resolv.conf` isn't automatically reset by other processes. You might want to add the "immutable" attribute to prevent changes:

```bash
sudo chattr +i /etc/resolv.conf
```

This will lock the file so it can't be changed without first removing the attribute.