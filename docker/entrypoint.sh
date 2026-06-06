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

if [[ "${MARIADB_ENABLED:-false}" == "true" ]]; then
  db_user_enc=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$MARIADB_USER")
  db_pass_enc=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$MARIADB_PASSWORD")
  export OPENSIPS_DB_URL="mysql://${db_user_enc}:${db_pass_enc}@${MARIADB_HOST}/${MARIADB_DATABASE}"
fi

apply_sed() {
  local src="$1"
  if [[ -n "${OPENSIPS_DB_URL:-}" ]]; then
    local escaped_url
    escaped_url=$(printf '%s' "$OPENSIPS_DB_URL" | sed 's/[\\&|]/\\&/g')
    sed "s|@@RTPENGINE_SOCKETS@@|${RTPENGINE_SOCKETS}|g; s|@@DB_URL@@|${escaped_url}|g" "$src"
  else
    sed "s|@@RTPENGINE_SOCKETS@@|${RTPENGINE_SOCKETS}|g" "$src"
  fi
}

apply_sed "${template_dir}/opensips.cfg" | sed '/^# Fragment files are concatenated/,$d' > "${run_cfg}"

append_fragment() {
  local f="$1"
  [[ -f "${f}" ]] || return 0
  echo "" >> "${run_cfg}"
  apply_sed "${f}" >> "${run_cfg}"
}

append_fragment "${template_dir}/modules.cfg"
[[ "${TLS_ENABLED:-false}" == "true" ]] && append_fragment "${template_dir}/tls.cfg"
[[ "${PROMETHEUS_ENABLED:-false}" == "true" ]] && append_fragment "${template_dir}/prometheus.cfg"
append_fragment "${template_dir}/db.cfg"
append_fragment "${template_dir}/registrar.cfg"
append_fragment "${template_dir}/carrier.cfg"
append_fragment "${template_dir}/carrier-auth.cfg"
append_fragment "${template_dir}/rtpengine.cfg"
append_fragment "${template_dir}/routing.cfg"
append_fragment "${template_dir}/peers-asterisk.cfg"
append_fragment "${template_dir}/registration.cfg"
append_fragment "${template_dir}/extra-routes.cfg"

if [[ "${MARIADB_ENABLED:-false}" == "true" ]]; then
  /usr/local/bin/seed-db.sh
fi

if [[ "${REGISTRATION_ENABLED:-false}" == "true" && -n "${REGISTRATION_USERNAME:-}" && -n "${REGISTRATION_PASSWORD:-}" ]]; then
  reg_domain="${REGISTRATION_DOMAIN:-${REGISTRATION_REGISTRAR}}"
  uac_cred="${REGISTRATION_USERNAME}:${reg_domain}:${REGISTRATION_PASSWORD}"
  escaped_uac_cred=$(printf '%s' "$uac_cred" | sed 's/[\\&|"]/\\&/g')
  sed -i "s|@@UAC_AUTH_CREDENTIAL@@|modparam(\"uac_auth\", \"credential\", \"${escaped_uac_cred}\")|" "${run_cfg}"
else
  sed -i '/@@UAC_AUTH_CREDENTIAL@@/d' "${run_cfg}"
fi

exec /usr/local/sbin/opensips -f "${run_cfg}" -F
