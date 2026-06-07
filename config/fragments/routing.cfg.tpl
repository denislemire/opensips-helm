# Core SIP routing: PBX <-> OpenSIPS <-> carrier.

route {
    if (!mf_process_maxfwd_header(10)) {
        sl_send_reply(483, "Too Many Hops");
        exit;
    }

    if (is_method("OPTIONS")) {
        sl_send_reply(200, "OK");
        exit;
    }

    if (is_method("CANCEL")) {
        if (t_check_trans()) {
            rtpengine_delete();
            t_relay();
        }
        exit;
    }

    if (has_totag()) {
        if (loose_route()) {
            if (is_method("BYE")) {
                rtpengine_delete();
            } else if (is_method("INVITE|UPDATE|ACK") && has_body("application/sdp")) {
                rtpengine_manage("trust-address replace-origin replace-session-connection");
            }
            route(RELAY);
            exit;
        }

        # A non-2xx ACK follows the INVITE server transaction.
        if (is_method("ACK") && t_check_trans()) {
            t_relay();
        }
        exit;
    }

    record_route();

    {{- if .Values.peers.asterisk.enabled }}
    route(FROM_PBX);
    {{- end }}

    {{- if .Values.carrier.enabled }}
    route(FROM_CARRIER);
    {{- end }}

    {{- if .Values.remoteRegistration.enabled }}
    if (is_method("REGISTER")) {
        if (!save("location")) {
            sl_reply_error();
        }
        exit;
    }
    if (lookup("location")) {
        if (is_method("INVITE|MESSAGE|NOTIFY|SUBSCRIBE|REFER|UPDATE|INFO")) {
            route(RELAY);
            exit;
        }
    }
    {{- end }}

    sl_send_reply(403, "Forbidden");
    exit;
}

route[RELAY] {
    if (!t_relay()) {
        sl_reply_error();
    }
}

{{- if .Values.peers.asterisk.enabled }}
route[FROM_PBX] {
    if (!is_method("INVITE|UPDATE|NOTIFY|REFER|INFO|MESSAGE|OPTIONS")) {
        return;
    }
    if ($fd =~ "{{ .Values.carrier.host }}") {
        return;
    }
    if (!($si =~ "^(10\\.|172\\.(1[6-9]|2[0-9]|3[0-1])\\.|192\\.168\\.)")) {
        return;
    }
    if (is_method("INVITE|UPDATE")) {
        rtpengine_manage("trust-address replace-origin replace-session-connection in-iface=internal out-iface=external");
        t_on_reply("FROM_CARRIER_REPLY");
    }
    {{- if .Values.carrier.enabled }}
    if (is_method("INVITE|UPDATE|NOTIFY|REFER|INFO|MESSAGE")) {
        uac_replace_from("", "sip:{{ .Values.registration.username }}@{{ default .Values.registration.registrar .Values.registration.domain }}");
        remove_hf("To");
        append_hf("To: <sip:$rU@{{ .Values.carrier.host }}>\r\n");
        $ru = "sip:" + $rU + "@{{ .Values.carrier.host }}:{{ .Values.carrier.port }}";
        $du = $ru;
        if (is_method("INVITE|UPDATE")) {
            t_on_failure("CARRIER_AUTH");
        }
    }
    {{- end }}
    route(RELAY);
    exit;
}

{{- if and .Values.peers.asterisk.enabled .Values.carrier.enabled }}
failure_route[CARRIER_AUTH] {
    if (t_was_cancelled()) {
        exit;
    }
    if (t_check_status("401|407")) {
        if (uac_auth()) {
            {{- with .Values.carrier.callerId }}
            append_hf("Remote-Party-ID: <sip:{{ . }}@{{ $.Values.carrier.host }}>;party=calling;privacy=off;screen=no\r\n");
            {{- end }}
            t_relay();
        }
    }
}
{{- end }}

onreply_route[FROM_CARRIER_REPLY] {
    if (has_body("application/sdp")) {
        rtpengine_manage("trust-address replace-origin replace-session-connection in-iface=external out-iface=internal");
    }
}

route[TO_PBX] {
    $du = "sip:{{ .Values.peers.asterisk.host }}:{{ .Values.peers.asterisk.port }}";
    route(RELAY);
}
{{- end }}

{{- if .Values.carrier.enabled }}
route[FROM_CARRIER] {
    if (!is_method("INVITE|UPDATE|NOTIFY|REFER|INFO|MESSAGE|OPTIONS")) {
        return;
    }
    if ($si != "{{ trimSuffix "/32" (first .Values.carrier.sourceCIDRs) }}") {
        return;
    }
    if (is_method("INVITE|UPDATE")) {
        rtpengine_manage("trust-address replace-origin replace-session-connection in-iface=external out-iface=internal");
        t_on_reply("FROM_PBX_REPLY");
    }
    {{- if .Values.peers.asterisk.enabled }}
    route(TO_PBX);
    {{- else }}
    route(RELAY);
    {{- end }}
    exit;
}

onreply_route[FROM_PBX_REPLY] {
    if (has_body("application/sdp")) {
        rtpengine_manage("trust-address replace-origin replace-session-connection in-iface=internal out-iface=external");
    }
}
{{- end }}
