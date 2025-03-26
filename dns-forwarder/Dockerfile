FROM alpine:latest

RUN apk add --no-cache socat bind-tools

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 53/udp 53/tcp

CMD ["/start.sh"]