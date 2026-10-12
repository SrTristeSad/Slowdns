# Changelog

## 3.0.0 - 2026-10-12

Retomada moderna do SlowDNS original de 2021.

### Cliente

- Cliente Termux com UDP, DoH e DoT.
- Perfis Google, Cloudflare, Quad9 e OpenDNS.
- Configuração persistente em `~/.config/slowdns`.
- Comandos `start`, `stop`, `restart`, `status`, `logs`, `doctor`, `config` e `version`.
- Desinstalador com preservação de configuração por padrão.

### Servidor

- Instalador Debian/Ubuntu com serviço `systemd` e usuário dedicado `dnstt`.
- Geração e preservação das chaves do servidor.
- Diagnóstico de serviço, porta, chaves, permissões, backend e DNS.
- Desinstalador que preserva `/etc/dnstt` por padrão.

### Dependência DNSTT

- DNSTT fixado em `v1.20260501.0` para builds reproduzíveis.
- A versão usada fica em `current/DNSTT_VERSION`.
- Removido o uso de `@latest` nos scripts atuais.

### Desenvolvimento

- Código atual separado em `current/` e legado em `legacy/`.
- README próprio em cada geração.
- Instalador de entrada `install.sh` na raiz.
- CI com `bash -n`, ShellCheck, verificação do pin e laboratório local ponta a ponta.
- O laboratório também confirma que o cliente DNSTT expõe opções UDP, DoH e DoT.

## 2.x / 0.1 - 2021

Versões históricas preservadas em `legacy/slowdns.txt`, `legacy/robinhood` e `legacy/RobinHood.txt`.
