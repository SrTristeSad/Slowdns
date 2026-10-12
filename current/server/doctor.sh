#!/usr/bin/env bash
set -u

CONFIG_DIR="/etc/dnstt"
SERVICE="dnstt.service"
EXPECTED_DNSTT_VERSION="v1.20260501.0"
problems=0

ok() { printf '[OK] %s\n' "$*"; }
info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[AVISO] %s\n' "$*"; }
err() { printf '[ERRO] %s\n' "$*"; problems=$((problems + 1)); }

if [[ $EUID -ne 0 ]]; then
    echo "Execute como root: sudo slowdns-server-doctor"
    exit 1
fi

echo "=== SlowDNS Server Doctor ==="

if command -v dnstt-server >/dev/null 2>&1; then
    dnstt_bin="$(command -v dnstt-server)"
    ok "dnstt-server instalado: $dnstt_bin"
    if command -v go >/dev/null 2>&1; then
        build_info="$(go version -m "$dnstt_bin" 2>/dev/null || true)"
        if grep -Fq "$EXPECTED_DNSTT_VERSION" <<<"$build_info"; then
            ok "DNSTT na versão esperada: $EXPECTED_DNSTT_VERSION"
        else
            warn "não consegui confirmar $EXPECTED_DNSTT_VERSION no binário instalado"
        fi
    else
        warn "Go indisponível; versão embutida do DNSTT não foi verificada"
    fi
else
    err "dnstt-server não encontrado"
fi

if [[ -s "$CONFIG_DIR/dnstt-version" ]]; then
    recorded_version="$(tr -d '[:space:]' < "$CONFIG_DIR/dnstt-version")"
    if [[ "$recorded_version" == "$EXPECTED_DNSTT_VERSION" ]]; then
        ok "versão registrada: $recorded_version"
    else
        warn "versão registrada é $recorded_version; esperada: $EXPECTED_DNSTT_VERSION"
    fi
else
    warn "arquivo de versão $CONFIG_DIR/dnstt-version ausente"
fi

if [[ -s "$CONFIG_DIR/server.key" && -s "$CONFIG_DIR/server.pub" ]]; then
    ok "par de chaves encontrado"
    pubkey="$(tr -d '[:space:]' < "$CONFIG_DIR/server.pub")"
    if [[ "$pubkey" =~ ^[0-9a-fA-F]{64}$ ]]; then
        ok "chave pública possui formato esperado"
    else
        err "chave pública possui formato inesperado"
    fi
    key_mode="$(stat -c '%a' "$CONFIG_DIR/server.key" 2>/dev/null || true)"
    if [[ "$key_mode" == "600" ]]; then
        ok "permissão da chave privada: 600"
    else
        warn "permissão da chave privada é ${key_mode:-desconhecida}; esperado: 600"
    fi
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

if [[ -s "$CONFIG_DIR/listen" ]]; then
    listen_addr="$(tr -d '[:space:]' < "$CONFIG_DIR/listen")"
    listen_port="${listen_addr##*:}"
    ok "escuta configurada: $listen_addr/udp"
else
    listen_addr=":53"
    listen_port="53"
    warn "arquivo $CONFIG_DIR/listen ausente; assumindo :53"
fi

if systemctl is-enabled --quiet "$SERVICE" 2>/dev/null; then
    ok "$SERVICE habilitado no boot"
else
    warn "$SERVICE não está habilitado no boot"
fi

if systemctl is-active --quiet "$SERVICE"; then
    ok "$SERVICE está ativo"
else
    err "$SERVICE não está ativo"
    systemctl --no-pager --full status "$SERVICE" 2>/dev/null | tail -n 12 || true
fi

if ss -lunp 2>/dev/null | grep -Eq ":${listen_port}[[:space:]]"; then
    ok "há processo escutando UDP/$listen_port"
else
    err "nenhum processo encontrado em UDP/$listen_port"
fi

if [[ -n "$backend" ]]; then
    backend_host="${backend%:*}"
    backend_port="${backend##*:}"
    if [[ "$backend_host" == "127.0.0.1" || "$backend_host" == "localhost" ]]; then
        if ss -ltn 2>/dev/null | grep -Eq ":${backend_port}[[:space:]]"; then
            ok "backend local parece estar escutando na porta $backend_port"
        else
            warn "backend local não apareceu escutando na porta $backend_port"
        fi
    else
        info "backend não local; disponibilidade não foi testada automaticamente"
    fi
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
