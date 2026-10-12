#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Execute como root: sudo slowdns-server-uninstall [--purge]"
    exit 1
fi

PURGE=false
case "${1:-}" in
    "") ;;
    --purge) PURGE=true ;;
    *)
        echo "Uso: sudo slowdns-server-uninstall [--purge]"
        exit 2
        ;;
esac

systemctl disable --now dnstt.service >/dev/null 2>&1 || true
rm -f /etc/systemd/system/dnstt.service
systemctl daemon-reload
systemctl reset-failed dnstt.service >/dev/null 2>&1 || true

rm -f /usr/local/bin/dnstt-server
rm -f /usr/local/sbin/slowdns-server-doctor
rm -f /usr/local/sbin/slowdns-server-uninstall

if [[ "$PURGE" == true ]]; then
    rm -rf /etc/dnstt
    if id dnstt >/dev/null 2>&1; then
        userdel -r dnstt >/dev/null 2>&1 || userdel dnstt >/dev/null 2>&1 || true
    fi
    echo "SlowDNS Server removido, incluindo chaves e configuração."
else
    echo "SlowDNS Server removido."
    if [[ -d /etc/dnstt ]]; then
        echo "Chaves e configuração preservadas em /etc/dnstt."
        echo "Use --purge somente quando quiser apagar esses dados também."
    fi
fi
