# Core SIP routing

route {
    if (!mf_process_maxfwd_header(10)) {
        sl_send_reply(483, "Too Many Hops");
        exit;
    }

    if (has_totag()) {
        if (is_method("ACK")) {
            if (t_check_trans()) {
                t_relay();
            }
            exit;
        }
        route(RELAY);
        exit;
    }

    if (is_method("INVITE|UPDATE")) {
        rtpengine_manage("trust-address replace-origin replace-session-connection");
    }

    if (is_method("BYE|CANCEL")) {
        rtpengine_manage();
    }

    record_route();

    {{- if .Values.peers.asterisk.enabled }}
    if ($si == "{{ .Values.peers.asterisk.host }}" || $fd == "{{ .Values.peers.asterisk.host }}") {
        route(FROM_PBX);
        exit;
    }

    if (is_method("INVITE|OPTIONS|INFO|MESSAGE|NOTIFY|SUBSCRIBE|REFER")) {
        route(TO_PBX);
        exit;
    }
    {{- end }}

    route(RELAY);
}

route[RELAY] {
    if (!t_relay()) {
        sl_reply_error();
    }
}

{{- if .Values.peers.asterisk.enabled }}
route[TO_PBX] {
    if (is_method("INVITE|UPDATE")) {
        rtpengine_manage("trust-address replace-origin replace-session-connection");
    }
    $du = "sip:{{ .Values.peers.asterisk.host }}:{{ .Values.peers.asterisk.port }}";
    route(RELAY);
}

route[FROM_PBX] {
    if (is_method("INVITE|UPDATE")) {
        rtpengine_manage("trust-address replace-origin replace-session-connection");
    }
    route(RELAY);
}
{{- end }}
