#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/SrTristeSad/Slowdns/main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v pkg >/dev/null 2>&1; then
    echo "Este instalador foi feito para Termux."
    exit 1
fi

echo "[1/4] Atualizando pacotes..."
pkg update -y

echo "[2/4] Instalando dependências..."
pkg install -y golang git ca-certificates curl openssh

echo "[3/4] Instalando dnstt-client atual..."
GOBIN="$PREFIX/bin" go install www.bamsoftware.com/git/dnstt.git/dnstt-client@latest

if [[ -f "$SCRIPT_DIR/../slowdns" ]]; then
    cp "$SCRIPT_DIR/../slowdns" "$PREFIX/bin/slowdns"
else
    curl -fsSL "$REPO_RAW/slowdns" -o "$PREFIX/bin/slowdns"
fi
chmod 755 "$PREFIX/bin/slowdns"

echo "[4/4] Configuração inicial..."
echo
slowdns config

echo
echo "Instalação concluída."
echo "Use: slowdns"
echo "Ou:  slowdns start google"
