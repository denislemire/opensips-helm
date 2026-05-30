#!/usr/bin/env bash
# opensips-helm — Copyright (C) 2026 Denis Lemire <denis@lemire.name>
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail

template_dir="${OPENSIPS_TEMPLATE_DIR:-/etc/opensips/template}"
run_dir="${OPENSIPS_RUN_DIR:-/etc/opensips/run}"
frag_dir="${run_dir}/opensips.d"

mkdir -p "${frag_dir}"

if [[ ! -f "${template_dir}/opensips.cfg" ]]; then
  echo "missing ${template_dir}/opensips.cfg" >&2
  exit 1
fi

RTPENGINE_SOCKETS="$(/usr/local/bin/discover-rtpengine.sh)"
export RTPENGINE_SOCKETS

for src in "${template_dir}"/*.cfg; do
  base="$(basename "${src}")"
  if [[ "${base}" == "opensips.cfg" ]]; then
    sed "s|@@RTPENGINE_SOCKETS@@|${RTPENGINE_SOCKETS}|g" "${src}" > "${run_dir}/opensips.cfg"
  else
    sed "s|@@RTPENGINE_SOCKETS@@|${RTPENGINE_SOCKETS}|g" "${src}" > "${frag_dir}/${base}"
  fi
done

if [[ "${REGISTRATION_ENABLED:-false}" == "true" ]]; then
  /usr/local/bin/register-carrier.sh || echo "warning: carrier registration script failed" >&2
fi

exec /usr/local/sbin/opensips -f "${run_dir}/opensips.cfg" -F
