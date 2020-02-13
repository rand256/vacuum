#!/bin/bash
# Spoof outgoing dns requests for cloud domains

LIST_CUSTOM_PRINT_USAGE+=("custom_print_usage_cloud_dnsmasq")
LIST_CUSTOM_PRINT_HELP+=("custom_print_help_cloud_dnsmasq")
LIST_CUSTOM_PARSE_ARGS+=("custom_parse_args_cloud_dnsmasq")
LIST_CUSTOM_FUNCTION+=("custom_function_cloud_dnsmasq")
ENABLE_CLOUD_DNSMASQ=${ENABLE_CLOUD_DNSMASQ:-"0"}

function custom_print_usage_cloud_dnsmasq() {
    cat << EOF
Custom parameters for '${BASH_SOURCE[0]}':
[--enable-cloud-dnsmasq]
EOF
}

function custom_print_help_cloud_dnsmasq() {
    cat << EOF
Custom options for '${BASH_SOURCE[0]}':
  --enable-cloud-dnsmasq       Spoof outgoing dns requests for cloud domains
EOF
}

function custom_parse_args_cloud_dnsmasq() {
    case ${PARAM} in
        *-enable-cloud-dnsmasq)
            ENABLE_CLOUD_DNSMASQ=1
            ;;
        -*)
            return 1
            ;;
    esac
}

function custom_function_cloud_dnsmasq() {
    if [ $ENABLE_CLOUD_DNSMASQ -eq 1 ]; then
        echo "+ Installing cloud dnsmasq"
        DNSMASQ_PATH=$(dirname $(readlink_f "${BASH_SOURCE[0]}"))
        ln "${IMG_DIR}/usr/sbin/dnsmasq" "${IMG_DIR}/usr/sbin/cloud-dnsmasq"
        if [ -f "${IMG_DIR}/etc/inittab" ]; then
            install -m 0755  "${DNSMASQ_PATH}/S09dnsmasq" "${IMG_DIR}/etc/init/S09dnsmasq"
        fi
        install -m 0644 "${DNSMASQ_PATH}/dnsmasq.conf" "${IMG_DIR}/etc/init/dnsmasq.conf"
        sed -i 's/exit 0//' "${IMG_DIR}/etc/rc.local"
        cat << EOF >> "${IMG_DIR}/etc/rc.local"
### CLOUD-DNSMASQ INIT ###
iptables -t nat -A OUTPUT -p udp -m owner ! --uid-owner nobody --dport 53 -j DNAT --to 127.0.0.1:5354
iptables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner nobody --dport 53 -j DNAT --to 127.0.0.1:5354
### CLOUD-DNSMASQ END ###
EOF
        echo "exit 0" >> "${IMG_DIR}/etc/rc.local"
    fi
}