# Global parameters — OpenSIPS 4.0 syntax
# opensips-helm — Copyright (C) 2026 Denis Lemire <denis@lemire.name>
# SPDX-License-Identifier: GPL-2.0-or-later
log_level=3
stderror_enabled=yes
syslog_enabled=no

{{- if .Values.sip.advertisedFqdn }}
advertised_address={{ .Values.sip.advertisedFqdn | quote }}
{{- end }}

socket=udp:0.0.0.0:{{ .Values.opensips.service.sipPorts.udp }} use_reverse_dns no
socket=tcp:0.0.0.0:{{ .Values.opensips.service.sipPorts.tcp }} use_reverse_dns no
{{- if .Values.tls.enabled }}
socket=tls:0.0.0.0:{{ .Values.tls.port }} use_reverse_dns no
{{- end }}

children=4

import "opensips.d/modules.cfg"
{{- if .Values.tls.enabled }}
import "opensips.d/tls.cfg"
{{- end }}
import "opensips.d/rtpengine.cfg"
import "opensips.d/routing.cfg"
{{- if .Values.peers.asterisk.enabled }}
import "opensips.d/peers-asterisk.cfg"
{{- end }}
{{- if .Values.registration.enabled }}
import "opensips.d/registration.cfg"
{{- end }}
{{- if .Values.opensipsCfg.extraRoutes }}
import "opensips.d/extra-routes.cfg"
{{- end }}
