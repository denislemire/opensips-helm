loadmodule "httpd.so"
loadmodule "prometheus.so"

modparam("httpd", "ip", "*")
modparam("httpd", "port", {{ .Values.prometheus.port }})
modparam("prometheus", "root", "metrics")
modparam("prometheus", "statistics", {{ .Values.prometheus.statistics | quote }})
