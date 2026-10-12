#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

if ! command -v pkg >/dev/null 2>&1; then
    echo "Este desinstalador foi feito para Termux."
    exit 1
fi

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/slowdns"
PURGE=false

case "${1:-}" in
    "") ;;
    --purge) PURGE=true ;;
    *)
        echo "Uso: slowdns-uninstall [--purge]"
        exit 2
        ;;
esac

if command -v slowdns >/dev/null 2>&1; then
    slowdns stop >/dev/null 2>&1 || true
fi

rm -f "$PREFIX/bin/slowdns" "$PREFIX/bin/dnstt-client" "$PREFIX/bin/slowdns-uninstall"

if [[ "$PURGE" == true ]]; then
    rm -rf "$CONFIG_DIR"
    echo "SlowDNS removido, incluindo configuração local."
else
    echo "SlowDNS removido."
    if [[ -d "$CONFIG_DIR" ]]; then
        echo "Configuração preservada em: $CONFIG_DIR"
        echo "Use --purge para apagar a configuração junto com a instalação."
    fi
fi
