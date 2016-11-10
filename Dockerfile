FROM alpine:3.4

COPY hang.sh /hang.sh
COPY derive-and-hang.sh /derive-and-hang.sh
CMD ["hang.sh"]
