{{- if .Values.tracing.enabled }}
loadmodule "proto_hep.so"
loadmodule "tracer.so"
modparam("proto_hep", "hep_id", "[hid]{{ required "tracing.hep.host is required when tracing.enabled" .Values.tracing.hep.host }}:{{ .Values.tracing.hep.port }};transport={{ .Values.tracing.hep.transport }};version={{ .Values.tracing.hep.version }}")
modparam("proto_hep", "hep_capture_id", {{ .Values.tracing.hep.captureId }})
modparam("tracer", "trace_id", "[hep]uri=hep:hid")
{{- end }}
