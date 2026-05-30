# Core SIP routing — Asterisk (LAN PBX) <-> OpenSIPS <-> carrier (VoIP.ms)

route {
    if (!mf_process_maxfwd_header(10)) {
        sl_send_reply(483, "Too Many Hops");
        exit;
    }

    if (is_method("OPTIONS")) {
        sl_send_reply(200, "OK");
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
    if ($rU != $null && lookup("location")) {
        if (is_method("INVITE|MESSAGE|NOTIFY|SUBSCRIBE|REFER|UPDATE|INFO")) {
            route(RELAY);
            exit;
        }
    }
    {{- end }}

    {{- if .Values.peers.asterisk.enabled }}
    if (is_method("INVITE|INFO|MESSAGE|NOTIFY|SUBSCRIBE|REFER|UPDATE")) {
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
route[FROM_PBX] {
    if (!is_method("INVITE|UPDATE|NOTIFY|REFER|INFO|MESSAGE|OPTIONS")) {
        return;
    }
    {{- if .Values.peers.asterisk.sourceCIDRs }}
    if (!( {{- range $i, $cidr := .Values.peers.asterisk.sourceCIDRs }}{{ if $i }} || {{ end }}is_ip_in_subnet("$si", {{ $cidr | quote }}){{- end }} )) {
        return;
    }
    {{- end }}
    if (is_method("INVITE|UPDATE")) {
        rtpengine_manage("trust-address replace-origin replace-session-connection");
    }
    {{- if .Values.carrier.enabled }}
    if (is_method("INVITE|UPDATE|NOTIFY|REFER|INFO|MESSAGE")) {
        $du = "sip:" + $rU + "@{{ .Values.carrier.host }}:{{ .Values.carrier.port }}";
    }
    {{- end }}
    route(RELAY);
    exit;
}

route[TO_PBX] {
    if (is_method("INVITE|UPDATE")) {
        rtpengine_manage("trust-address replace-origin replace-session-connection");
    }
    $du = "sip:{{ .Values.peers.asterisk.host }}:{{ .Values.peers.asterisk.port }}";
    route(RELAY);
}
{{- end }}

{{- if .Values.carrier.enabled }}
route[FROM_CARRIER] {
    if (!is_method("INVITE|UPDATE|NOTIFY|REFER|INFO|MESSAGE|OPTIONS")) {
        return;
    }
    if ($fd =~ "{{ .Values.carrier.host }}") {
        # matched by domain
    } else {
        {{- if .Values.carrier.sourceCIDRs }}
        if (!( {{- range $i, $cidr := .Values.carrier.sourceCIDRs }}{{ if $i }} || {{ end }}is_ip_in_subnet("$si", {{ $cidr | quote }}){{- end }} )) {
            return;
        }
        {{- else }}
        return;
        {{- end }}
    }
    if (is_method("INVITE|UPDATE")) {
        rtpengine_manage("trust-address replace-origin replace-session-connection");
    }
    {{- if .Values.peers.asterisk.enabled }}
    route(TO_PBX);
    {{- else }}
    route(RELAY);
    {{- end }}
    exit;
}
{{- end }}
