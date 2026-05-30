#!/usr/bin/env bash
# opensips-helm — wait for MariaDB and seed VoIP.ms uac_registrant row.
set -euo pipefail

db_host="${MARIADB_HOST:-}"
db_name="${MARIADB_DATABASE:-opensips}"
db_user="${MARIADB_USER:-opensips}"
db_pass="${MARIADB_PASSWORD:-}"
root_pass="${MARIADB_ROOT_PASSWORD:-${db_pass}}"

wait_for_mysql() {
  local attempt=0
  while [[ $attempt -lt 60 ]]; do
    if mariadb-admin ping -h "$db_host" -u root -p"$root_pass" --silent 2>/dev/null; then
      return 0
    fi
    attempt=$((attempt + 1))
    sleep 2
  done
  echo "MariaDB at ${db_host} not ready" >&2
  return 1
}

seed_registrant() {
  local registrar="${REGISTRATION_REGISTRAR:-}"
  local username="${REGISTRATION_USERNAME:-}"
  local domain="${REGISTRATION_DOMAIN:-${registrar}}"
  local password="${REGISTRATION_PASSWORD:-}"
  local binding="${REGISTRATION_BINDING_URI:-}"
  local expiry="${REGISTRATION_INTERVAL:-300}"

  if [[ -z "${registrar}" || -z "${username}" || -z "${password}" || -z "${binding}" ]]; then
    echo "registration enabled but REGISTRATION_REGISTRAR/USERNAME/PASSWORD/BINDING_URI not set" >&2
    return 1
  fi

  local aor="sip:${username}@${domain}"
  local reg_uri="sip:${registrar}:5060"
  local password_sql="${password//\'/\\\'}"
  local binding_sql="${binding//\'/\\\'}"

  mariadb -h "$db_host" -u "$db_user" -p"$db_pass" "$db_name" <<EOF
DELETE FROM registrant WHERE aor = '${aor}';
INSERT INTO registrant (
  registrar, proxy, aor, username, password, binding_URI, expiry, state
) VALUES (
  '${reg_uri}', NULL, '${aor}', '${username}', '${password_sql}', '${binding_sql}', ${expiry}, 0
);
EOF
  echo "seeded uac_registrant row for ${username}@${domain}"
}

if [[ "${MARIADB_ENABLED:-false}" != "true" ]]; then
  exit 0
fi

wait_for_mysql

if [[ "${REGISTRATION_ENABLED:-false}" == "true" ]]; then
  seed_registrant
fi
