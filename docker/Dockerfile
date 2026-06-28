# syntax=docker/dockerfile:1

FROM debian:bookworm-slim AS builder

ARG OPENSIPS_GIT_REF=4.0
ARG OPENSIPS_VERSION=0.1.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git build-essential bison flex pkg-config \
    libssl-dev libncurses-dev libxml2-dev libpcre3-dev \
    libcurl4-openssl-dev libhiredis-dev libmariadb-dev libmariadb-dev-compat \
    default-libmysqlclient-dev libjson-c-dev \
    libevent-dev libxmlrpc-core-c3-dev libperl-dev libmemcached-dev \
    libmicrohttpd-dev libuuid1 uuid-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 --branch "${OPENSIPS_GIT_REF}" --recurse-submodules \
    https://github.com/OpenSIPS/opensips.git opensips

WORKDIR /src/opensips
ARG OPENSIPS_MODULES="signaling proto_udp proto_tcp proto_tls tls_mgm tls_openssl httpd prometheus sl tm rr maxfwd sipmsgops textops dialog rtpengine uac uac_auth db_mysql usrloc uac_registrant registrar permissions"
RUN make -j"$(nproc)" prefix=/usr LIBDIR=lib include_modules="${OPENSIPS_MODULES}" \
    all && make -j"$(nproc)" prefix=/usr LIBDIR=lib include_modules="${OPENSIPS_MODULES}" \
    install

FROM debian:bookworm-slim

ARG OPENSIPS_VERSION=0.1.0

LABEL org.opencontainers.image.version="${OPENSIPS_VERSION}"
LABEL org.opencontainers.image.source="https://github.com/denislemire/opensips-helm"
LABEL org.opencontainers.image.authors="Denis Lemire <denis@lemire.name>"
LABEL org.opencontainers.image.licenses="GPL-2.0-or-later"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates libssl3 libxml2 libpcre3 libcurl4 libhiredis0.14 \
    libmariadb3 libjson-c5 libevent-2.1-7 libxmlrpc-core-c3 libmemcached11 \
    libmicrohttpd12 libuuid1 dnsutils iputils-ping mariadb-client python3-minimal \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/sbin/opensips /usr/sbin/opensips
COPY --from=builder /usr/lib/opensips /usr/lib/opensips
COPY --from=builder /usr/share/opensips /usr/share/opensips
COPY docker/discover-rtpengine.sh /usr/local/bin/discover-rtpengine.sh
COPY docker/seed-db.sh /usr/local/bin/seed-db.sh
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
# Bake config templates into the image as a default; K8s ConfigMap mount overlays
# this path at runtime. Allows opensips -C -f self-validation in CI without a mount.
COPY config/fragments/ /etc/opensips/template/

RUN chmod +x /usr/local/bin/discover-rtpengine.sh \
    /usr/local/bin/seed-db.sh /usr/local/bin/entrypoint.sh

EXPOSE 5060/udp 5060/tcp
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
