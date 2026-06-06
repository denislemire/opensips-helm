#!/usr/bin/env bash
# opensips-helm — wait for MariaDB and seed VoIP.ms uac_registrant row.
set -euo pipefail

db_host="${MARIADB_HOST:-}"
db_name="${MARIADB_DATABASE:-opensips}"
db_user="${MARIADB_USER:-opensips}"
db_pass="${MARIADB_PASSWORD:-}"

wait_for_mysql() {
  local attempt=0
  while [[ $attempt -lt 60 ]]; do
    if mariadb -h "$db_host" -u "$db_user" -p"$db_pass" "$db_name" -e "SELECT 1" >/dev/null 2>&1; then
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

seed_address_group() {
  local group_id="$1"
  local cidrs_csv="$2"
  [[ -n "$cidrs_csv" ]] || return 0
  mariadb -h "$db_host" -u "$db_user" -p"$db_pass" "$db_name" -e "DELETE FROM address WHERE grp = ${group_id};"
  local IFS=','
  for cidr in $cidrs_csv; do
    cidr="${cidr// /}"
    [[ -n "$cidr" ]] || continue
    local ip="${cidr%%/*}"
    local mask="${cidr##*/}"
    [[ "$mask" == "$ip" ]] && mask=32
    mariadb -h "$db_host" -u "$db_user" -p"$db_pass" "$db_name" -e \
      "INSERT INTO address (grp, ip, mask, port, proto) VALUES (${group_id}, '${ip}', ${mask}, 0, 'any');"
  done
  echo "seeded address group ${group_id}"
}

if [[ "${MARIADB_ENABLED:-false}" != "true" ]]; then
  exit 0
fi

wait_for_mysql

mariadb -h "$db_host" -u "$db_user" -p"$db_pass" "$db_name" <<'EOF'
CREATE TABLE IF NOT EXISTS address (
    id INT(10) UNSIGNED AUTO_INCREMENT PRIMARY KEY NOT NULL,
    grp SMALLINT(5) UNSIGNED DEFAULT 0 NOT NULL,
    ip CHAR(50) NOT NULL,
    mask SMALLINT UNSIGNED DEFAULT 32 NOT NULL,
    port SMALLINT(5) UNSIGNED DEFAULT 0 NOT NULL,
    proto CHAR(4) DEFAULT 'any' NOT NULL,
    pattern CHAR(64) DEFAULT NULL,
    context_info CHAR(32) DEFAULT NULL
) ENGINE=InnoDB;
EOF

seed_address_group 1 "${PEERS_ASTERISK_CIDRS:-}"
seed_address_group 2 "${CARRIER_SOURCE_CIDRS:-}"

if [[ "${REGISTRATION_ENABLED:-false}" == "true" ]]; then
  seed_registrant
fi
