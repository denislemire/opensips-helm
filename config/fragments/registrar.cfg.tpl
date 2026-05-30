# Remote SIP registration to OpenSIPS (Internet -> OpenSIPS -> Asterisk)

loadmodule "registrar.so"

modparam("registrar", "default_expires", 3600)
modparam("registrar", "min_expires", 60)
modparam("registrar", "max_expires", 7200)
