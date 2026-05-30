loadmodule "signaling.so"
loadmodule "sl.so"
loadmodule "tm.so"
loadmodule "rr.so"
loadmodule "maxfwd.so"
loadmodule "sipmsgops.so"
loadmodule "textops.so"
loadmodule "siputils.so"
loadmodule "proto_udp.so"
loadmodule "proto_tcp.so"
loadmodule "dialog.so"
loadmodule "rtpengine.so"
loadmodule "uac.so"
loadmodule "uac_auth.so"

modparam("rr", "append_fromtag", 1)
modparam("dialog", "dlg_match_mode", 1)
