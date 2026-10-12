# SlowDNS

[![SlowDNS CI](https://github.com/SrTristeSad/Slowdns/actions/workflows/ci.yml/badge.svg)](https://github.com/SrTristeSad/Slowdns/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Túnel **TCP sobre DNS** baseado em DNSTT.

O repositório está dividido de verdade em duas partes:

```text
Slowdns/
├── current/   # versão atual (2026 / 3.x)
└── legacy/    # código antigo preservado (2021)
```

## Qual versão usar?

Use **`current/`**.

`legacy/` existe somente para preservar o código original e a história do projeto. Ele não é a instalação recomendada.

## O que a versão atual faz

```text
Aplicação TCP
    ↓
dnstt-client
    ↓
consultas DNS
    ↓
resolver DNS
    ↓
dnstt-server
    ↓
backend TCP (ex.: SSH)
```

O cliente abre uma porta TCP local. O DNSTT transporta esse fluxo por DNS até o servidor e entrega ao backend configurado.

A versão atual possui:

- cliente Android/Termux;
- servidor Debian/Ubuntu;
- DNS/UDP;
- DoH e DoT no cliente;
- configuração persistente;
- serviço `systemd`;
- diagnóstico de cliente e servidor;
- teste local ponta a ponta;
- CI no GitHub Actions.

## Testar sem VPS ou domínio

Requisitos: Linux, Go, `curl` e `python3`.

```bash
git clone https://github.com/SrTristeSad/Slowdns.git
cd Slowdns/current
bash lab/local-test.sh
```

Resultado esperado:

```text
OK: túnel DNSTT local funcionando ponta a ponta.
HTTP -> dnstt-client -> DNS/UDP -> dnstt-server -> HTTP
```

Esse mesmo teste é executado pelo CI.

## Instalar servidor

Você precisa de uma VPS Debian/Ubuntu, domínio próprio e UDP/53 disponível.

Exemplo de DNS:

```dns
A   tns.exemplo.com   203.0.113.10
NS  t.exemplo.com     tns.exemplo.com
```

Instalação:

```bash
git clone https://github.com/SrTristeSad/Slowdns.git
cd Slowdns/current
sudo bash server/install.sh t.exemplo.com 127.0.0.1:22
```

O instalador cria o serviço `dnstt`, gera as chaves na primeira instalação e mostra a chave pública para configurar o cliente.

Diagnóstico:

```bash
sudo slowdns-server-doctor
```

Logs:

```bash
journalctl -u dnstt -f
```

## Instalar no Android / Termux

```bash
pkg install git -y
git clone https://github.com/SrTristeSad/Slowdns.git
cd Slowdns/current
bash client/install-termux.sh
```

Depois:

```bash
slowdns
```

Comandos úteis:

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

Exemplo com SSH, usando o padrão local `127.0.0.1:2222`:

```bash
slowdns start google
ssh -p 2222 usuario@127.0.0.1
```

## Código atual

```text
current/
├── slowdns
├── client/
│   └── install-termux.sh
├── server/
│   ├── install.sh
│   └── doctor.sh
└── lab/
    └── local-test.sh
```

## Código antigo

```text
legacy/
├── slowdns.txt
├── robinhood
└── RobinHood.txt
```

Os arquivos de `legacy/` foram preservados sem serem transformados na versão nova.

## Está funcionando?

O GitHub Actions valida a sintaxe dos scripts da versão atual e executa um túnel DNSTT local completo usando DNS/UDP.

Isso testa o núcleo do projeto. Uma instalação real também depende da VPS, delegação NS, firewall, UDP/53 e backend estarem configurados corretamente.

DoH e DoT estão implementados no cliente, mas o teste ponta a ponta atual do CI cobre DNS/UDP.

## Limitações

SlowDNS não é uma VPN IP completa. Ele transporta **TCP** através do DNSTT.

Túnel DNS possui overhead e normalmente terá mais latência e menos velocidade que uma conexão direta.

## Segurança

Mantenha `/etc/dnstt/server.key` privado e use o projeto somente em redes, domínios e servidores que você administra ou tem autorização para testar.

## Licença

Código próprio deste repositório: **MIT License**. Veja [`LICENSE`](LICENSE).

DNSTT e outras dependências mantêm suas próprias licenças.
