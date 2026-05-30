loadmodule "proto_tls.so"
loadmodule "tls_openssl.so"
loadmodule "tls_mgm.so"

modparam("tls_mgm", "certificate", {{ .Values.tls.certificatePath | quote }})
modparam("tls_mgm", "private_key", {{ .Values.tls.privateKeyPath | quote }})
modparam("tls_mgm", "require_cert", "0")
modparam("tls_mgm", "verify_cert", "0")
