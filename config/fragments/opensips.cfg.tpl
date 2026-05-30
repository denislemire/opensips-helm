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

import_file "/etc/opensips/run/opensips.d/modules.cfg"
{{- if .Values.tls.enabled }}
import_file "/etc/opensips/run/opensips.d/tls.cfg"
{{- end }}
import_file "/etc/opensips/run/opensips.d/rtpengine.cfg"
import_file "/etc/opensips/run/opensips.d/routing.cfg"
{{- if .Values.peers.asterisk.enabled }}
import_file "/etc/opensips/run/opensips.d/peers-asterisk.cfg"
{{- end }}
{{- if .Values.registration.enabled }}
import_file "/etc/opensips/run/opensips.d/registration.cfg"
{{- end }}
{{- if .Values.opensipsCfg.extraRoutes }}
import_file "/etc/opensips/run/opensips.d/extra-routes.cfg"
{{- end }}
