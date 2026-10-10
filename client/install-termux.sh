#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/SrTristeSad/Slowdns/main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v pkg >/dev/null 2>&1; then
    echo "Este instalador foi feito para Termux."
    exit 1
fi

if [[ "${PREFIX:-}" != *"com.termux"* ]]; then
    echo "Aviso: PREFIX inesperado (${PREFIX:-vazio}). Continuando porque 'pkg' está disponível."
fi

echo "[1/5] Atualizando índice de pacotes..."
pkg update -y

echo "[2/5] Instalando dependências..."
pkg install -y golang git ca-certificates curl openssh dnsutils

echo "[3/5] Instalando dnstt-client atual..."
GOBIN="$PREFIX/bin" go install www.bamsoftware.com/git/dnstt.git/dnstt-client@latest

if [[ ! -x "$PREFIX/bin/dnstt-client" ]]; then
    echo "Falha: dnstt-client não foi instalado em $PREFIX/bin"
    exit 1
fi

echo "[4/5] Instalando comando slowdns..."
if [[ -f "$SCRIPT_DIR/../slowdns" ]]; then
    cp "$SCRIPT_DIR/../slowdns" "$PREFIX/bin/slowdns"
else
    curl -fsSL "$REPO_RAW/slowdns" -o "$PREFIX/bin/slowdns"
fi
chmod 755 "$PREFIX/bin/slowdns"

echo "[5/5] Verificação..."
slowdns version

echo
if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/slowdns/config" ]]; then
    echo "Configuração anterior encontrada; ela foi preservada."
    echo "Use 'slowdns config' se quiser alterá-la."
else
    echo "Abrindo configuração inicial..."
    slowdns config
fi

echo
echo "Instalação concluída."
echo "Menu:        slowdns"
echo "Diagnóstico: slowdns doctor"
echo "Ajuda:       slowdns help"
