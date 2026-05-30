# Socket list injected by docker/entrypoint.sh (sidecar, dns, or static).
modparam("rtpengine", "rtpengine_sock", "@@RTPENGINE_SOCKETS@@")
