# SlowDNS

[![SlowDNS CI](https://github.com/SrTristeSad/Slowdns/actions/workflows/ci.yml/badge.svg)](https://github.com/SrTristeSad/Slowdns/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Túnel **TCP sobre DNS** baseado em DNSTT.

```text
Slowdns/
├── current/   versão atual (3.x)
└── legacy/    scripts originais de 2021
```

**Para instalar, use `current/`.** `legacy/` é somente histórico.

## Como funciona

```text
Aplicação TCP
    ↓
dnstt-client
    ↓
DNS / resolver
    ↓
dnstt-server
    ↓
backend TCP (ex.: SSH)
```

SlowDNS abre uma porta TCP local e usa o DNSTT para transportar esse fluxo até um backend TCP no servidor. Não é uma VPN IP completa.

## DNSTT usado

A versão atual fixa o DNSTT em **`v1.20260501.0`**. Isso evita que uma instalação mude só porque o upstream publicou código novo.

A revisão utilizada fica em [`current/DNSTT_VERSION`](current/DNSTT_VERSION).

## Testar sem VPS

Requisitos: Linux, Go, `curl` e `python3`.

```bash
git clone https://github.com/SrTristeSad/Slowdns.git
cd Slowdns
bash current/lab/local-test.sh
```

Resultado esperado:

```text
OK: túnel DNSTT local funcionando ponta a ponta.
HTTP -> dnstt-client -> DNS/UDP -> dnstt-server -> HTTP
```

O CI também executa `bash -n`, ShellCheck, verifica que os scripts não usam `@latest`, confirma suporte do binário a UDP/DoH/DoT e roda o teste ponta a ponta por DNS/UDP.

## Instalação rápida

### Android / Termux

```bash
pkg install git -y
git clone https://github.com/SrTristeSad/Slowdns.git
cd Slowdns
bash install.sh
```

Depois:

```bash
slowdns
```

### Servidor Debian/Ubuntu

Você precisa de domínio próprio e UDP/53 disponível.

Exemplo de delegação DNS:

```dns
A   tns.exemplo.com   203.0.113.10
NS  t.exemplo.com     tns.exemplo.com
```

Instale:

```bash
git clone https://github.com/SrTristeSad/Slowdns.git
cd Slowdns
sudo bash install.sh server t.exemplo.com 127.0.0.1:22
```

A chave pública exibida no final é usada na configuração do cliente.

## Comandos do cliente

```bash
slowdns config
slowdns start google
slowdns start cloudflare
slowdns start quad9
slowdns start opendns
slowdns start doh-google
slowdns start doh-cloudflare
slowdns start dot-google
slowdns start dot-cloudflare
slowdns status
slowdns doctor
slowdns logs
slowdns stop
```

Exemplo com SSH:

```bash
slowdns start google
ssh -p 2222 usuario@127.0.0.1
```

## Diagnóstico do servidor

```bash
sudo slowdns-server-doctor
```

Ele verifica serviço, porta UDP configurada, chaves, permissões, versão do DNSTT, backend local e delegação NS.

## Desinstalar

Termux, preservando configuração:

```bash
slowdns-uninstall
```

Servidor, preservando `/etc/dnstt` e as chaves:

```bash
sudo slowdns-server-uninstall
```

Use `--purge` somente quando quiser apagar também configuração/chaves.

## Estrutura

```text
Slowdns/
├── install.sh
├── current/
│   ├── README.md
│   ├── DNSTT_VERSION
│   ├── slowdns
│   ├── client/
│   ├── server/
│   └── lab/
├── legacy/
│   ├── README.md
│   ├── slowdns.txt
│   ├── robinhood
│   └── RobinHood.txt
├── CHANGELOG.md
└── LICENSE
```

## Limitações e uso responsável

DNS tunneling tem overhead: normalmente haverá mais latência e menos throughput que numa conexão direta. O resultado também depende do resolver, VPS, firewall, delegação DNS e rede utilizada.

Use somente em redes, domínios e servidores que você administra ou tem autorização para testar. Mantenha `/etc/dnstt/server.key` privado.

## Licença

Código próprio do repositório: **MIT License**. Consulte [`LICENSE`](LICENSE). Dependências externas mantêm suas próprias licenças.
