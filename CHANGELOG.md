# Changelog

## 3.0.0 - 2026-10-10

Retomada do projeto SlowDNS original de 2021.

### Cliente

- Reescrito para Termux atual.
- Instalação do `dnstt-client@latest` via Go.
- Perfis UDP: Google, Cloudflare, Quad9 e OpenDNS.
- Suporte a DoH e DoT.
- Resolver e endpoints personalizados.
- Configuração persistente em `~/.config/slowdns`.
- Comandos `start`, `stop`, `restart`, `status`, `logs`, `doctor`, `config` e `version`.
- Validação de domínio, chave pública e endereço local.
- Instalador preserva configurações existentes durante atualizações.

### Servidor

- Instalador para Debian/Ubuntu.
- Instalação do `dnstt-server@latest`.
- Usuário dedicado `dnstt`.
- Serviço `systemd` com reinício automático e hardening básico.
- Geração automática e preservação do par de chaves.
- `server/doctor.sh` para diagnóstico de serviço, porta, chaves e DNS.

### Desenvolvimento

- `lab/local-test.sh` para teste ponta a ponta sem domínio ou VPS.
- Workflow de CI para validar sintaxe e executar o laboratório local.
- README completamente atualizado.
- Scripts históricos de 2021 mantidos no repositório.

## 2.x / 0.1 - 2021

Versões históricas do script original, mantidas nos arquivos `slowdns.txt`, `robinhood` e `RobinHood.txt`.
