loadmodule "proto_tls.so"
loadmodule "tls_openssl.so"
loadmodule "tls_mgm.so"

# OpenSIPS 4.0 tls_mgm uses named domains — [domain]path syntax for cert params.
modparam("tls_mgm", "server_domain", "default")
modparam("tls_mgm", "certificate", "[default]{{ .Values.tls.certificatePath }}")
modparam("tls_mgm", "private_key", "[default]{{ .Values.tls.privateKeyPath }}")
modparam("tls_mgm", "verify_cert", "[default]0")
modparam("tls_mgm", "require_cert", "[default]0")
