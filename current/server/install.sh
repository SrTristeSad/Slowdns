#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Execute como root: sudo bash server/install.sh t.seudominio.com [backend]"
    exit 1
fi

TUNNEL_DOMAIN="${1:-}"
BACKEND="${2:-127.0.0.1:22}"
LISTEN_ADDR="${DNSTT_LISTEN_ADDR:-:53}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="$SCRIPT_DIR/../DNSTT_VERSION"
DNSTT_VERSION="${DNSTT_VERSION:-v1.20260501.0}"

if [[ -r "$VERSION_FILE" ]]; then
    DNSTT_VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
fi

if [[ -z "$TUNNEL_DOMAIN" ]]; then
    echo "Uso: sudo bash server/install.sh t.seudominio.com [127.0.0.1:22]"
    exit 1
fi

if [[ ! "$TUNNEL_DOMAIN" =~ ^([A-Za-z0-9-]+\.)+[A-Za-z]{2,}$ ]]; then
    echo "Domínio inválido: $TUNNEL_DOMAIN"
    exit 1
fi

if [[ "$BACKEND" != *:* ]]; then
    echo "Backend inválido. Use host:porta, por exemplo 127.0.0.1:22"
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "Este instalador requer Debian/Ubuntu com apt-get."
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "[1/7] Instalando dependências..."
apt-get update
apt-get install -y golang-go ca-certificates dnsutils iproute2

echo "[2/7] Instalando dnstt-server $DNSTT_VERSION..."
GOBIN=/usr/local/bin go install "www.bamsoftware.com/git/dnstt.git/dnstt-server@$DNSTT_VERSION"
chmod 755 /usr/local/bin/dnstt-server

if ! id dnstt >/dev/null 2>&1; then
    useradd --system --home /var/lib/dnstt --create-home --shell /usr/sbin/nologin dnstt
fi

install -d -m 750 -o dnstt -g dnstt /etc/dnstt
printf '%s\n' "$TUNNEL_DOMAIN" > /etc/dnstt/domain
printf '%s\n' "$BACKEND" > /etc/dnstt/backend
printf '%s\n' "$LISTEN_ADDR" > /etc/dnstt/listen
printf '%s\n' "$DNSTT_VERSION" > /etc/dnstt/dnstt-version
chmod 640 /etc/dnstt/domain /etc/dnstt/backend /etc/dnstt/listen /etc/dnstt/dnstt-version
chown dnstt:dnstt /etc/dnstt/domain /etc/dnstt/backend /etc/dnstt/listen /etc/dnstt/dnstt-version

echo "[3/7] Preparando chaves..."
if [[ ! -s /etc/dnstt/server.key || ! -s /etc/dnstt/server.pub ]]; then
    rm -f /etc/dnstt/server.key /etc/dnstt/server.pub
    runuser -u dnstt -- /usr/local/bin/dnstt-server \
        -gen-key \
        -privkey-file /etc/dnstt/server.key \
        -pubkey-file /etc/dnstt/server.pub
else
    echo "Chaves existentes preservadas."
fi
chmod 600 /etc/dnstt/server.key
chmod 644 /etc/dnstt/server.pub
chown dnstt:dnstt /etc/dnstt/server.key /etc/dnstt/server.pub

echo "[4/7] Criando serviço systemd..."
cat > /etc/systemd/system/dnstt.service <<EOF_SERVICE
[Unit]
Description=SlowDNS DNSTT server
Documentation=https://github.com/SrTristeSad/Slowdns
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=dnstt
Group=dnstt
ExecStart=/usr/local/bin/dnstt-server -udp $LISTEN_ADDR -privkey-file /etc/dnstt/server.key $TUNNEL_DOMAIN $BACKEND
Restart=on-failure
RestartSec=3
NoNewPrivileges=true
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictSUIDSGID=true
LockPersonality=true

[Install]
WantedBy=multi-user.target
EOF_SERVICE

echo "[5/7] Instalando ferramentas de manutenção..."
if [[ -f "$SCRIPT_DIR/doctor.sh" ]]; then
    install -m 755 "$SCRIPT_DIR/doctor.sh" /usr/local/sbin/slowdns-server-doctor
fi
if [[ -f "$SCRIPT_DIR/uninstall.sh" ]]; then
    install -m 755 "$SCRIPT_DIR/uninstall.sh" /usr/local/sbin/slowdns-server-uninstall
fi

echo "[6/7] Ativando serviço..."
systemctl daemon-reload
systemctl enable dnstt.service >/dev/null
systemctl restart dnstt.service
sleep 1

if ! systemctl is-active --quiet dnstt.service; then
    echo "Falha ao iniciar dnstt.service."
    echo "Verifique se a porta UDP configurada já está ocupada:"
    ss -lunp 2>/dev/null | grep -F -- "${LISTEN_ADDR##*:}" || true
    echo
    journalctl -u dnstt.service -n 40 --no-pager || true
    exit 1
fi

echo "[7/7] Instalação concluída."
echo
PUBKEY="$(tr -d '[:space:]' < /etc/dnstt/server.pub)"
cat <<EOF_SUMMARY
============================================================
SlowDNS / DNSTT ativo
DNSTT             : $DNSTT_VERSION
Domínio do túnel  : $TUNNEL_DOMAIN
Backend TCP        : $BACKEND
Escutando em       : $LISTEN_ADDR/udp
Public key         : $PUBKEY
============================================================

No DNS do seu domínio, delegue o subdomínio do túnel.
Exemplo para t.exemplo.com e VPS 203.0.113.10:

  A   tns.exemplo.com   203.0.113.10
  NS  t.exemplo.com     tns.exemplo.com

O hostname do nameserver deve ficar fora da zona delegada.
Confirme também que UDP/53 está permitido na VPS/provedor.

Cliente Termux:
  slowdns config

Diagnóstico do servidor:
  sudo slowdns-server-doctor

Desinstalar preservando chaves/configuração:
  sudo slowdns-server-uninstall

Status:
  systemctl status dnstt --no-pager

Logs:
  journalctl -u dnstt -f
EOF_SUMMARY
