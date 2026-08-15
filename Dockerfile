# Default to latest Alpine; overridable via --build-arg ALPINE_VERSION=x.y.z
ARG ALPINE_VERSION=latest

FROM alpine:${ALPINE_VERSION}

# Default to latest NUT package; overridable via --build-arg NUT_VERSION=x.y.z-r0
ARG NUT_VERSION=""

# Install NUT, bash, and timezone data
RUN apk add --no-cache \
    ${NUT_VERSION:+nut=${NUT_VERSION}} \
    ${NUT_VERSION:-nut} \
    bash \
    tzdata

# Explicit runtime environment defaults
ENV UPSTREAM_HOST="192.168.1.100" \
    UPSTREAM_PORT="3493" \
    UPSTREAM_UPS_NAME="ups" \
    UPSTREAM_USER="ups" \
    UPSTREAM_PASS="secret" \
    LOCAL_UPS_NAME="ups" \
    LOCAL_PORT="3493" \
    CLIENT_USER="ups" \
    CLIENT_PASS="clientpass"

# Prepare runtime directories
RUN mkdir -p /etc/nut /var/run/nut && \
    chown -R nut:nut /etc/nut /var/run/nut && \
    chmod 750 /var/run/nut

# Copy script and set execution permissions
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE ${LOCAL_PORT}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]