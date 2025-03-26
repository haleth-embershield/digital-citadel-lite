FROM alpine:latest

RUN apk add --no-cache dnsmasq bash

COPY dnsmasq.conf /etc/dnsmasq.conf.template
COPY start.sh /start.sh

RUN chmod +x /start.sh

EXPOSE 53/tcp 53/udp

ENTRYPOINT ["/start.sh"]