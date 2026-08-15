# Default to latest Alpine; overridable via --build-arg ALPINE_VERSION=x.y.z
ARG ALPINE_VERSION=latest

FROM alpine:${ALPINE_VERSION}

# Default to latest NUT package; overridable via --build-arg NUT_VERSION=x.y.z-r0
ARG NUT_VERSION=""

# Install NUT, bash, timezone data, and dos2unix to sanitize line endings
RUN apk add --no-cache \
    ${NUT_VERSION:+nut=${NUT_VERSION}} \
    ${NUT_VERSION:-nut} \
    bash \
    tzdata \
    dos2unix

# Default runtime environment variables (overridable via `docker run -e` or .env)
ENV UPS_NAME="myups" \
    UPSTREAM_HOST="192.168.1.100" \
    UPSTREAM_PORT="3493" \
    UPSTREAM_USER="monuser" \
    UPSTREAM_PASS="secret" \
    CLIENT_USER="clientuser" \
    CLIENT_PASS="clientpass"

# Prepare configuration and runtime directories
RUN mkdir -p /etc/nut /var/run/nut && \
    chown -R nut:nut /etc/nut /var/run/nut && \
    chmod 750 /var/run/nut

# Copy entrypoint script into image
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Ensure script has Unix (LF) line endings and executable permissions
RUN dos2unix /usr/local/bin/entrypoint.sh && chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3493

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]