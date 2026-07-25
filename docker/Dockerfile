# syntax=docker/dockerfile:1

FROM debian:trixie-slim AS builder

ARG OPENSIPS_GIT_REF=4.0
ARG RTPPROXY_GIT_REF=v3.2.0
ARG EHWS_BUILD=1
ARG OPENSIPS_VERSION=0.1.0

ENV DEBIAN_FRONTEND=noninteractive

# Trixie dropped libpcre3; OpenSIPS 4.0 builds against libpcre2.
# libsrtp2-dev + autotools are required to build librtpproxy for rtp.io.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git build-essential bison flex pkg-config \
    autoconf automake libtool \
    libssl-dev libncurses-dev libxml2-dev libpcre2-dev \
    libcurl4-openssl-dev libhiredis-dev libmariadb-dev libmariadb-dev-compat \
    default-libmysqlclient-dev libjson-c-dev \
    libevent-dev libxmlrpc-core-c3-dev libperl-dev libmemcached-dev \
    libmicrohttpd-dev libuuid1 uuid-dev libsrtp2-dev \
    && rm -rf /var/lib/apt/lists/*

# rtp.io links librtpproxy.a from RTPProxy >= 3.1 built with --enable-librtpproxy.
# Install under /usr/local so OpenSIPS LOCALBASE (/usr/local) finds headers + archive.
WORKDIR /src
RUN git clone --depth 1 --recurse-submodules --branch "${RTPPROXY_GIT_REF}" \
    https://github.com/sippy/rtpproxy.git rtpproxy \
    && cd rtpproxy \
    && ./configure --prefix=/usr/local --enable-librtpproxy \
    && make -j"$(nproc)" \
    && make install \
    && if [ ! -f /usr/local/lib/librtpproxy.a ]; then \
         found="$(find /usr/local -name 'librtpproxy.a' -print -quit)"; \
         test -n "${found}" && cp -v "${found}" /usr/local/lib/librtpproxy.a; \
       fi \
    && test -f /usr/local/lib/librtpproxy.a \
    && ldconfig

WORKDIR /src
RUN git clone --depth 1 --branch "${OPENSIPS_GIT_REF}" \
    https://github.com/OpenSIPS/opensips.git opensips

WORKDIR /src/opensips
# rtp.io + rtpproxy sit alongside rtpengine so the same image can use either media path.
ARG OPENSIPS_MODULES="signaling proto_udp proto_tcp proto_tls tls_mgm tls_openssl httpd prometheus sl tm rr maxfwd sipmsgops textops dialog rtpengine rtp.io rtpproxy uac uac_auth db_mysql usrloc uac_registrant registrar permissions"

# include_modules= is additive to OpenSIPS's full default module set, not a
# restriction (see upstream INSTALL: "compile all default modules and include
# uri_radius"). Overriding modules= on the command line is the only way to
# limit the build, since command-line variables take precedence over the
# Makefile's own modules= assignment. Without this, `make install` builds and
# ships all ~190 modules in the tree instead of just the ~20 our config loads.
RUN MODULE_PATHS="$(for m in ${OPENSIPS_MODULES}; do printf 'modules/%s ' "$m"; done)" \
    && make -j"$(nproc)" prefix=/usr LIBDIR=lib modules="${MODULE_PATHS}" \
    OPENSIPS_RELEASE="${OPENSIPS_VERSION}" all \
    && make -j"$(nproc)" prefix=/usr LIBDIR=lib modules="${MODULE_PATHS}" \
    OPENSIPS_RELEASE="${OPENSIPS_VERSION}" \
    install \
    && strip --strip-unneeded /usr/sbin/opensips /usr/lib/opensips/modules/*.so \
    && test -f /usr/lib/opensips/modules/rtp.io.so \
    && test -f /usr/lib/opensips/modules/rtpproxy.so

FROM debian:trixie-slim

ARG OPENSIPS_VERSION=0.1.0

LABEL org.opencontainers.image.version="${OPENSIPS_VERSION}"
LABEL org.opencontainers.image.source="https://github.com/denislemire/opensips-helm"
LABEL org.opencontainers.image.authors="Denis Lemire <denis@lemire.name>"
LABEL org.opencontainers.image.vendor="Generic dot Business Ltd"
LABEL org.opencontainers.image.licenses="GPL-2.0-or-later"
LABEL org.opencontainers.image.description="OpenSIPS 4.0 with RTPEngine and embedded rtp.io (librtpproxy)"

ENV DEBIAN_FRONTEND=noninteractive

# Runtime SONAMEs on amd64 Trixie use the t64 ABI transition packages.
# libsrtp2 is required at runtime by the rtp.io module (linked via libsrtp2).
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates libssl3t64 libxml2 libpcre2-8-0 libcurl4t64 libhiredis1.1.0 \
    libmariadb3 libjson-c5 libevent-2.1-7t64 libxmlrpc-core-c3t64 libmemcached11t64 \
    libmicrohttpd12t64 libuuid1 libsrtp2-1 mariadb-client-core \
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
