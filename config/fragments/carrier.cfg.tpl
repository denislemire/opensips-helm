# VoIP.ms / carrier peer — registration via uac_registrant when enabled.

modparam("uac_registrant", "hash_size", 2)
modparam("uac_registrant", "timer_interval", 120)
modparam("uac_registrant", "db_url", "@@DB_URL@@")
modparam("uac_registrant", "table_name", "registrant")
