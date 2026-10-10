#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Execute como root: sudo bash server/install.sh t.seudominio.com [backend]"
    exit 1
fi

TUNNEL_DOMAIN="${1:-}"
BACKEND="${2:-127.0.0.1:22}"
LISTEN_ADDR="${DNSTT_LISTEN_ADDR:-:53}"

if [[ -z "$TUNNEL_DOMAIN" ]]; then
    echo "Uso: sudo bash server/install.sh t.seudominio.com [127.0.0.1:22]"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "[1/6] Instalando dependências..."
apt-get update
apt-get install -y golang-go ca-certificates

echo "[2/6] Instalando dnstt-server atual..."
GOBIN=/usr/local/bin go install www.bamsoftware.com/git/dnstt.git/dnstt-server@latest
chmod 755 /usr/local/bin/dnstt-server

if ! id dnstt >/dev/null 2>&1; then
    useradd --system --home /var/lib/dnstt --create-home --shell /usr/sbin/nologin dnstt
fi

install -d -m 750 -o dnstt -g dnstt /etc/dnstt
printf '%s\n' "$TUNNEL_DOMAIN" > /etc/dnstt/domain
printf '%s\n' "$BACKEND" > /etc/dnstt/backend
chmod 640 /etc/dnstt/domain /etc/dnstt/backend
chown dnstt:dnstt /etc/dnstt/domain /etc/dnstt/backend

echo "[3/6] Gerando chaves..."
if [[ ! -s /etc/dnstt/server.key || ! -s /etc/dnstt/server.pub ]]; then
    rm -f /etc/dnstt/server.key /etc/dnstt/server.pub
    runuser -u dnstt -- /usr/local/bin/dnstt-server \
        -gen-key \
        -privkey-file /etc/dnstt/server.key \
        -pubkey-file /etc/dnstt/server.pub
fi
chmod 600 /etc/dnstt/server.key
chmod 644 /etc/dnstt/server.pub
chown dnstt:dnstt /etc/dnstt/server.key /etc/dnstt/server.pub

echo "[4/6] Criando serviço systemd..."
cat > /etc/systemd/system/dnstt.service <<EOF
[Unit]
Description=DNSTT DNS tunnel server
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
EOF

echo "[5/6] Ativando serviço..."
systemctl daemon-reload
systemctl enable --now dnstt.service
sleep 1

if ! systemctl is-active --quiet dnstt.service; then
    echo "Falha ao iniciar dnstt.service. Verifique se a porta UDP/53 já está em uso:"
    ss -lunp 2>/dev/null | grep ':53 ' || true
    journalctl -u dnstt.service -n 40 --no-pager || true
    exit 1
fi

echo "[6/6] Instalação concluída."
echo
PUBKEY="$(tr -d '[:space:]' < /etc/dnstt/server.pub)"
cat <<EOF
============================================================
DNSTT ativo
Domínio do túnel : $TUNNEL_DOMAIN
Backend TCP       : $BACKEND
Escutando em      : $LISTEN_ADDR/udp
Public key        : $PUBKEY
============================================================

No DNS do seu domínio, faça uma delegação de subdomínio.
Exemplo para t.exemplo.com e uma VPS 203.0.113.10:

  A   tns.exemplo.com   203.0.113.10
  NS  t.exemplo.com     tns.exemplo.com

O nome do servidor autoritativo (tns) deve ficar fora da zona delegada.
Confirme também que UDP/53 está liberado no firewall da sua VPS/provedora.

No Termux, execute:
  slowdns config

e informe o domínio e a public key mostrada acima.

Status:
  systemctl status dnstt --no-pager
Logs:
  journalctl -u dnstt -f
EOF
