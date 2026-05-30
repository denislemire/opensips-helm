#!/usr/bin/env bash
# opensips-helm — Copyright (C) 2026 Denis Lemire <denis@lemire.name>
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail

mode="${RTPENGINE_MODE:-distributed}"
discovery="${RTPENGINE_DISCOVERY:-dns}"
control_port="${RTPENGINE_CONTROL_PORT:-2223}"
headless_host="${RTPENGINE_HEADLESS_HOST:-}"
statefulset_name="${RTPENGINE_STATEFULSET_NAME:-}"
replica_count="${RTPENGINE_REPLICA_COUNT:-1}"

if [[ "${mode}" == "sidecar" ]]; then
  echo "udp:127.0.0.1:${control_port}"
  exit 0
fi

if [[ "${discovery}" == "static" ]]; then
  echo "${RTPENGINE_STATIC_SOCKETS:?RTPENGINE_STATIC_SOCKETS required for static discovery}"
  exit 0
fi

sockets=()

if [[ -n "${statefulset_name}" && -n "${headless_host}" ]]; then
  for ((i = 0; i < replica_count; i++)); do
    host="${statefulset_name}-${i}.${headless_host}"
    sockets+=("udp:${host}:${control_port}")
  done
fi

if [[ ${#sockets[@]} -eq 0 && -n "${headless_host}" ]]; then
  while IFS= read -r host; do
    [[ -z "${host}" ]] && continue
    sockets+=("udp:${host}:${control_port}")
  done < <(getent ahostsv4 "${headless_host}" 2>/dev/null | awk '{print $1}' | sort -u || true)
fi

if [[ ${#sockets[@]} -eq 0 ]]; then
  echo "no RTPEngine endpoints discovered (headless=${headless_host})" >&2
  exit 1
fi

echo "${sockets[*]}"
