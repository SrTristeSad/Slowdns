#!/usr/bin/env bash
set -u

CONFIG_DIR="/etc/dnstt"
SERVICE="dnstt.service"
problems=0

ok() { printf '[OK] %s\n' "$*"; }
warn() { printf '[AVISO] %s\n' "$*"; }
err() { printf '[ERRO] %s\n' "$*"; problems=$((problems + 1)); }

if [[ $EUID -ne 0 ]]; then
    echo "Execute como root: sudo bash server/doctor.sh"
    exit 1
fi

echo "=== SlowDNS Server Doctor ==="

if command -v dnstt-server >/dev/null 2>&1; then
    ok "dnstt-server instalado: $(command -v dnstt-server)"
else
    err "dnstt-server não encontrado"
fi

if [[ -s "$CONFIG_DIR/server.key" && -s "$CONFIG_DIR/server.pub" ]]; then
    ok "par de chaves encontrado"
else
    err "chaves ausentes em $CONFIG_DIR"
fi

if [[ -s "$CONFIG_DIR/domain" ]]; then
    domain="$(tr -d '[:space:]' < "$CONFIG_DIR/domain")"
    ok "domínio configurado: $domain"
else
    domain=""
    err "arquivo $CONFIG_DIR/domain ausente"
fi

if [[ -s "$CONFIG_DIR/backend" ]]; then
    backend="$(tr -d '[:space:]' < "$CONFIG_DIR/backend")"
    ok "backend configurado: $backend"
else
    backend=""
    err "arquivo $CONFIG_DIR/backend ausente"
fi

if systemctl is-active --quiet "$SERVICE"; then
    ok "$SERVICE está ativo"
else
    err "$SERVICE não está ativo"
    systemctl --no-pager --full status "$SERVICE" 2>/dev/null | tail -n 12 || true
fi

if ss -lunp 2>/dev/null | grep -Eq '(^|[[:space:]])[^[:space:]]*:53[[:space:]]'; then
    ok "há um processo escutando UDP/53"
else
    err "nenhum processo encontrado em UDP/53"
fi

if [[ -n "$domain" ]] && command -v dig >/dev/null 2>&1; then
    ns_output="$(dig +short NS "$domain" 2>/dev/null || true)"
    if [[ -n "$ns_output" ]]; then
        ok "delegação NS pública encontrada"
        printf '%s\n' "$ns_output" | sed 's/^/     /'
    else
        warn "não encontrei NS público para $domain; confirme a delegação no provedor DNS"
    fi
else
    warn "não foi possível verificar a delegação NS (domínio/dig indisponível)"
fi

echo
if (( problems == 0 )); then
    echo "Servidor passou nas verificações locais essenciais."
    exit 0
fi

echo "$problems problema(s) crítico(s) encontrado(s)."
exit 1
