#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<'USAGE'
SlowDNS installer

Termux / Android:
  bash install.sh
  bash install.sh client

Debian / Ubuntu server:
  sudo bash install.sh server t.exemplo.com [127.0.0.1:22]
USAGE
}

mode="${1:-auto}"

if [[ "$mode" == "client" ]]; then
    shift
    exec bash "$ROOT_DIR/current/client/install-termux.sh" "$@"
fi

if [[ "$mode" == "server" ]]; then
    shift
    if [[ $# -lt 1 ]]; then
        usage
        exit 2
    fi
    exec bash "$ROOT_DIR/current/server/install.sh" "$@"
fi

if [[ "$mode" != "auto" ]]; then
    usage
    exit 2
fi

if command -v pkg >/dev/null 2>&1 && [[ "${PREFIX:-}" == *"com.termux"* ]]; then
    exec bash "$ROOT_DIR/current/client/install-termux.sh"
fi

cat <<'MSG'
Ambiente Linux detectado, mas o servidor precisa do domínio do túnel.
Use:
  sudo bash install.sh server t.exemplo.com [127.0.0.1:22]
MSG
exit 2
