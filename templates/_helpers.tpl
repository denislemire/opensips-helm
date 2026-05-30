{{- define "opensips.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "opensips.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "opensips.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "opensips.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "opensips.labels" -}}
helm.sh/chart: {{ include "opensips.chart" . }}
{{ include "opensips.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end -}}

{{- define "opensips.selectorLabels" -}}
app.kubernetes.io/name: {{ include "opensips.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "opensips.image" -}}
{{- $tag := default .Chart.Version .Values.opensips.image.tag -}}
{{- printf "%s:%s" .Values.opensips.image.repository $tag -}}
{{- end -}}

{{- define "opensips.rtpengineImage" -}}
{{- printf "%s:%s" .Values.rtpengine.image.repository .Values.rtpengine.image.tag -}}
{{- end -}}

{{- define "opensips.configMapName" -}}
{{- if .Values.opensipsCfg.existingConfigMap -}}
{{- .Values.opensipsCfg.existingConfigMap -}}
{{- else -}}
{{- include "opensips.fullname" . -}}
{{- end -}}
{{- end -}}

{{- define "opensips.rtpengineHeadlessHost" -}}
{{- printf "%s-rtpengine-headless.%s.svc.cluster.local" (include "opensips.fullname" .) .Release.Namespace -}}
{{- end -}}

{{- define "opensips.rtpengineStatefulSetName" -}}
{{- printf "%s-rtpengine" (include "opensips.fullname" .) -}}
{{- end -}}

{{- define "opensips.rtpengineStaticSockets" -}}
{{- $root := . -}}
{{- $host := include "opensips.rtpengineHeadlessHost" . -}}
{{- $name := include "opensips.rtpengineStatefulSetName" . -}}
{{- $port := int .Values.rtpengine.service.controlPort -}}
{{- $count := int .Values.rtpengine.replicaCount -}}
{{- $sockets := list -}}
{{- range $i := until $count -}}
{{- $sockets = append $sockets (printf "udp:%s-%d.%s:%d" $name $i $host $port) -}}
{{- end -}}
{{- join " " $sockets -}}
{{- end -}}

{{- define "opensips.tlsSecretName" -}}
{{- if .Values.tls.existingSecret -}}
{{- .Values.tls.existingSecret -}}
{{- else if .Values.tls.certManager.secretName -}}
{{- .Values.tls.certManager.secretName -}}
{{- else -}}
{{- printf "%s-tls" (include "opensips.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "opensips.tlsEnabled" -}}
{{- if .Values.tls.enabled -}}true{{- else -}}false{{- end -}}
{{- end -}}

{{- define "opensips.rtpengineSidecar" -}}
{{- if and .Values.rtpengine.enabled (eq .Values.rtpengine.mode "sidecar") -}}true{{- else -}}false{{- end -}}
{{- end -}}

{{- define "opensips.rtpengineDistributed" -}}
{{- if and .Values.rtpengine.enabled (eq .Values.rtpengine.mode "distributed") -}}true{{- else -}}false{{- end -}}
{{- end -}}

{{- define "opensips.rtpengineInterfaceArg" -}}
{{- if .Values.rtpengine.media.advertisedIp -}}
internal/any!{{ .Values.rtpengine.media.advertisedIp }}
{{- else -}}
any
{{- end -}}
{{- end -}}
