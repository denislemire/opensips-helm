# Global parameters — OpenSIPS 4.0 syntax
# opensips-helm — Copyright (C) 2026 Denis Lemire <denis@lemire.name>
# SPDX-License-Identifier: GPL-2.0-or-later
log_level=3
stderror_enabled=yes
syslog_enabled=no

{{- if .Values.sip.advertisedFqdn }}
advertised_address={{ .Values.sip.advertisedFqdn | quote }}
{{- end }}

socket=udp:0.0.0.0:{{ .Values.opensips.service.sipPorts.udp }}
socket=tcp:0.0.0.0:{{ .Values.opensips.service.sipPorts.tcp }}
{{- if .Values.tls.enabled }}
socket=tls:0.0.0.0:{{ .Values.tls.port }}
{{- end }}
auto_aliases=no

children=4

# Fragment files are concatenated below this line by entrypoint.sh (@@FRAGMENTS@@)
