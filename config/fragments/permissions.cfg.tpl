# Source address groups (grp 1 = PBX, grp 2 = carrier).
modparam("permissions", "partition", "default")
modparam("permissions", "db_url", "@@DB_URL@@")
modparam("permissions", "address_table", "address")
