#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/SrTristeSad/Slowdns/main/current"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="$SCRIPT_DIR/../DNSTT_VERSION"
DNSTT_VERSION="${DNSTT_VERSION:-v1.20260501.0}"

if [[ -r "$VERSION_FILE" ]]; then
    DNSTT_VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
fi

if ! command -v pkg >/dev/null 2>&1; then
    echo "Este instalador foi feito para Termux."
    exit 1
fi

if [[ "${PREFIX:-}" != *"com.termux"* ]]; then
    echo "Aviso: PREFIX inesperado (${PREFIX:-vazio}). Continuando porque 'pkg' está disponível."
fi

echo "[1/6] Atualizando índice de pacotes..."
pkg update -y

echo "[2/6] Instalando dependências..."
pkg install -y golang git ca-certificates curl openssh dnsutils iproute2

echo "[3/6] Instalando dnstt-client $DNSTT_VERSION..."
GOBIN="$PREFIX/bin" go install "www.bamsoftware.com/git/dnstt.git/dnstt-client@$DNSTT_VERSION"

if [[ ! -x "$PREFIX/bin/dnstt-client" ]]; then
    echo "Falha: dnstt-client não foi instalado em $PREFIX/bin"
    exit 1
fi

echo "[4/6] Instalando comando slowdns..."
if [[ -f "$SCRIPT_DIR/../slowdns" ]]; then
    cp "$SCRIPT_DIR/../slowdns" "$PREFIX/bin/slowdns"
else
    curl -fsSL "$REPO_RAW/slowdns" -o "$PREFIX/bin/slowdns"
fi
chmod 755 "$PREFIX/bin/slowdns"

echo "[5/6] Instalando desinstalador..."
if [[ -f "$SCRIPT_DIR/uninstall.sh" ]]; then
    cp "$SCRIPT_DIR/uninstall.sh" "$PREFIX/bin/slowdns-uninstall"
else
    curl -fsSL "$REPO_RAW/client/uninstall.sh" -o "$PREFIX/bin/slowdns-uninstall"
fi
chmod 755 "$PREFIX/bin/slowdns-uninstall"

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/slowdns"
mkdir -p "$CONFIG_DIR"
printf '%s\n' "$DNSTT_VERSION" > "$CONFIG_DIR/dnstt-version"
chmod 600 "$CONFIG_DIR/dnstt-version"

echo "[6/6] Verificação..."
slowdns version

echo
if [[ -f "$CONFIG_DIR/config" ]]; then
    echo "Configuração anterior encontrada; ela foi preservada."
    echo "Use 'slowdns config' se quiser alterá-la."
else
    echo "Abrindo configuração inicial..."
    slowdns config
fi

echo
echo "Instalação concluída."
echo "DNSTT:       $DNSTT_VERSION"
echo "Menu:        slowdns"
echo "Diagnóstico: slowdns doctor"
echo "Desinstalar: slowdns-uninstall"
