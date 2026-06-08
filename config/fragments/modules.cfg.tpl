loadmodule "signaling.so"
loadmodule "sl.so"
loadmodule "tm.so"
loadmodule "rr.so"
loadmodule "maxfwd.so"
loadmodule "sipmsgops.so"
loadmodule "textops.so"
loadmodule "proto_udp.so"
loadmodule "proto_tcp.so"
loadmodule "dialog.so"
loadmodule "rtpengine.so"
loadmodule "uac.so"
loadmodule "uac_auth.so"
{{- if .Values.mariadb.enabled }}
loadmodule "db_mysql.so"
loadmodule "usrloc.so"
{{- if or .Values.peers.asterisk.enabled .Values.carrier.enabled }}
loadmodule "permissions.so"
modparam("permissions", "partition", "default: db_url=@@DB_URL@@; table_name=address")
{{- end }}
{{- end }}
{{- if .Values.remoteRegistration.enabled }}
loadmodule "registrar.so"
{{- end }}
{{- if and .Values.mariadb.enabled .Values.registration.enabled .Values.carrier.enabled }}
loadmodule "uac_registrant.so"
{{- end }}

modparam("rr", "append_fromtag", 1)
modparam("dialog", "dlg_match_mode", 1)
