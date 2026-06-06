# Carrier registration via uac_registrant when enabled.

modparam("uac_registrant", "hash_size", 1)
modparam("uac_registrant", "timer_interval", 60)
modparam("uac_registrant", "failure_retry_interval", 30)
modparam("uac_registrant", "db_url", "@@DB_URL@@")
modparam("uac_registrant", "table_name", "registrant")
