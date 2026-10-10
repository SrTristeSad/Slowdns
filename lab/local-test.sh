#!/usr/bin/env bash
set -euo pipefail

DOMAIN="t.local"
SERVER_UDP="127.0.0.1:5300"
BACKEND="127.0.0.1:18080"
CLIENT_TCP="127.0.0.1:18081"
TMPDIR_SLOWDNS="$(mktemp -d)"
SERVER_PID=""
CLIENT_PID=""
HTTP_PID=""

cleanup() {
    [[ -n "$CLIENT_PID" ]] && kill "$CLIENT_PID" 2>/dev/null || true
    [[ -n "$SERVER_PID" ]] && kill "$SERVER_PID" 2>/dev/null || true
    [[ -n "$HTTP_PID" ]] && kill "$HTTP_PID" 2>/dev/null || true
    rm -rf "$TMPDIR_SLOWDNS"
}
trap cleanup EXIT INT TERM

need() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Dependência ausente: $1"
        exit 1
    }
}

need go
need curl
need python3

export GOBIN="$TMPDIR_SLOWDNS/bin"
mkdir -p "$GOBIN"

echo "[1/6] Instalando binários DNSTT temporários..."
go install www.bamsoftware.com/git/dnstt.git/dnstt-server@latest
go install www.bamsoftware.com/git/dnstt.git/dnstt-client@latest

echo "[2/6] Gerando chaves temporárias..."
"$GOBIN/dnstt-server" -gen-key \
    -privkey-file "$TMPDIR_SLOWDNS/server.key" \
    -pubkey-file "$TMPDIR_SLOWDNS/server.pub" >/dev/null
PUBKEY="$(tr -d '[:space:]' < "$TMPDIR_SLOWDNS/server.pub")"

echo "SlowDNS local test" > "$TMPDIR_SLOWDNS/index.html"

echo "[3/6] Iniciando backend HTTP em $BACKEND..."
python3 -m http.server 18080 --bind 127.0.0.1 --directory "$TMPDIR_SLOWDNS" \
    >"$TMPDIR_SLOWDNS/http.log" 2>&1 &
HTTP_PID=$!

echo "[4/6] Iniciando dnstt-server em $SERVER_UDP..."
"$GOBIN/dnstt-server" \
    -udp "$SERVER_UDP" \
    -privkey-file "$TMPDIR_SLOWDNS/server.key" \
    "$DOMAIN" "$BACKEND" >"$TMPDIR_SLOWDNS/server.log" 2>&1 &
SERVER_PID=$!

echo "[5/6] Iniciando dnstt-client em $CLIENT_TCP..."
"$GOBIN/dnstt-client" \
    -udp "$SERVER_UDP" \
    -pubkey "$PUBKEY" \
    "$DOMAIN" "$CLIENT_TCP" >"$TMPDIR_SLOWDNS/client.log" 2>&1 &
CLIENT_PID=$!

sleep 2

echo "[6/6] Testando tráfego TCP através do túnel DNS..."
RESULT="$(curl -fsS --max-time 20 "http://$CLIENT_TCP/")"

if [[ "$RESULT" == "SlowDNS local test" ]]; then
    echo
    echo "OK: túnel DNSTT local funcionando ponta a ponta."
    echo "HTTP -> dnstt-client -> DNS/UDP -> dnstt-server -> HTTP"
else
    echo "Falha: resposta inesperada: $RESULT"
    echo "--- server.log ---"
    cat "$TMPDIR_SLOWDNS/server.log" || true
    echo "--- client.log ---"
    cat "$TMPDIR_SLOWDNS/client.log" || true
    exit 1
fi
