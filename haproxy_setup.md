mkdir -p ~/digital-citadel-lite/container_data/haproxy
cat > ~/digital-citadel-lite/container_data/haproxy/haproxy.cfg << EOL
defaults
    mode udp
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend dns_in
    bind *:53
    default_backend dns_backend

backend dns_backend
    server pihole 172.18.0.3:53 check inter 2000ms fall 3
    server cloudflare 1.1.1.1:53 backup
    server google 8.8.8.8:53 backup
EOL



```cfg
global
    log stdout format raw local0

defaults
    mode udp
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend dns_in
    bind *:53
    default_backend dns_backend
    stick-table type ip size 1m expire 10m store gpc0
    udp-request rate-limit 1000 drop

backend dns_backend
    server pihole 172.18.0.3:53 check inter 2000ms fall 3
    server cloudflare 1.1.1.1:53 backup
    server google 8.8.8.8:53 backup
```