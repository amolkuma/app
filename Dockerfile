FROM golang:1.16.2-alpine3.13 as builder
WORKDIR /app
COPY . ./
# This is where one could build the application code as well.


FROM alpine:latest as tailscale
WORKDIR /app
ENV TSFILE=tailscale_1.34.1_amd64.tgz
RUN wget https://pkgs.tailscale.com/stable/${TSFILE} && \
  tar xzf ${TSFILE} --strip-components=1


FROM alpine:latest
RUN apk update && apk add ca-certificates bash sudo && rm -rf /var/cache/apk/*

# Azure allows SSH access to the container. This isn't needed for Tailscale to
# operate, but is really useful for debugging the application.
RUN apk add openssh openssh-keygen && echo "root:Docker!" | chpasswd
RUN apk add netcat-openbsd
RUN mkdir -p /etc/ssh
COPY sshd_config /etc/ssh/
EXPOSE 80 2222

# Copy binary to production image
COPY --from=builder /app/start.sh /app/start.sh
COPY --from=tailscale /app/tailscaled /app/tailscaled
COPY --from=tailscale /app/tailscale /app/tailscale
RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale

# Run on container startup.
CMD ["/app/start.sh"]
