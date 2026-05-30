# Source address groups (grp 1 = Asterisk, grp 2 = VoIP.ms)
modparam("permissions", "partition", "default")
modparam("permissions", "db_url", "@@DB_URL@@")
modparam("permissions", "address_table", "address")
