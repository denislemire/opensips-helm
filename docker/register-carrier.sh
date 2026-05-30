#!/usr/bin/env bash
# opensips-helm — Copyright (C) 2026 Denis Lemire <denis@lemire.name>
# SPDX-License-Identifier: GPL-2.0-or-later
# Optional outbound REGISTER to a SIP carrier (credentials from env / Secret).
set -euo pipefail

registrar="${REGISTRATION_REGISTRAR:-}"
username="${REGISTRATION_USERNAME:-}"
domain="${REGISTRATION_DOMAIN:-${REGISTRATION_REGISTRAR}}"
password="${REGISTRATION_PASSWORD:-}"

if [[ -z "${registrar}" || -z "${username}" || -z "${password}" ]]; then
  echo "registration enabled but REGISTRATION_REGISTRAR/USERNAME/PASSWORD not set" >&2
  exit 1
fi

# Placeholder: consumers extend with opensips-cli or MI uac when wiring a carrier.
# The chart documents required Secret keys; site-specific uac logic belongs in extraRoutes or a fork.
echo "registration configured for ${username}@${domain} via ${registrar} (apply uac in opensipsCfg.extraRoutes or custom fragment)"
