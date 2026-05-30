#!/usr/bin/env bash
# opensips-helm — Copyright (C) 2026 Denis Lemire <denis@lemire.name>
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail

template_dir="${OPENSIPS_TEMPLATE_DIR:-/etc/opensips/template}"
run_dir="${OPENSIPS_RUN_DIR:-/etc/opensips/run}"
run_cfg="${run_dir}/opensips.cfg"

mkdir -p "${run_dir}"

if [[ ! -f "${template_dir}/opensips.cfg" ]]; then
  echo "missing ${template_dir}/opensips.cfg" >&2
  exit 1
fi

RTPENGINE_SOCKETS="$(/usr/local/bin/discover-rtpengine.sh)"
export RTPENGINE_SOCKETS

apply_sed() {
  sed "s|@@RTPENGINE_SOCKETS@@|${RTPENGINE_SOCKETS}|g" "$1"
}

# Global section (opensips.cfg template) then inline fragments — OpenSIPS 4.0 single-file config.
apply_sed "${template_dir}/opensips.cfg" | sed '/^# Fragment files are concatenated/,$d' > "${run_cfg}"

append_fragment() {
  local f="$1"
  [[ -f "${f}" ]] || return 0
  echo "" >> "${run_cfg}"
  apply_sed "${f}" >> "${run_cfg}"
}

append_fragment "${template_dir}/modules.cfg"
[[ "${TLS_ENABLED:-false}" == "true" ]] && append_fragment "${template_dir}/tls.cfg"
append_fragment "${template_dir}/rtpengine.cfg"
append_fragment "${template_dir}/routing.cfg"
append_fragment "${template_dir}/peers-asterisk.cfg"
append_fragment "${template_dir}/registration.cfg"
append_fragment "${template_dir}/extra-routes.cfg"

if [[ "${REGISTRATION_ENABLED:-false}" == "true" ]]; then
  /usr/local/bin/register-carrier.sh || echo "warning: carrier registration script failed" >&2
fi

exec /usr/local/sbin/opensips -f "${run_cfg}" -F
