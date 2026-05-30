# MariaDB-backed state (dialog, usrloc, uac_registrant)
loadmodule "db_mysql.so"
loadmodule "usrloc.so"

modparam("dialog", "db_url", "@@DB_URL@@")
modparam("dialog", "db_mode", 1)

modparam("usrloc", "db_url", "@@DB_URL@@")
modparam("usrloc", "working_mode_preset", "sql-only")
modparam("usrloc", "use_domain", 1)
