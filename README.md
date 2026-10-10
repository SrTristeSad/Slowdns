# SrTriste SlowDNS

Projeto SlowDNS original de 2021 revivido para o ambiente atual usando **DNSTT**.

A proposta continua a mesma do projeto antigo: transportar uma conexão TCP através de consultas DNS, mas a implementação foi reorganizada em cliente, servidor e laboratório, com configuração persistente, diagnóstico e suporte aos transportes modernos do DNSTT.

> Use somente em redes, domínios e servidores que você administra ou tem autorização para testar. O projeto não promete internet gratuita, não altera cobrança de operadora e não depende de uma falha específica de rede.

## O que voltou à vida

- Cliente moderno para Termux.
- DNSTT instalado diretamente da versão atual via Go.
- Perfis UDP para Google, Cloudflare, Quad9 e OpenDNS.
- DNS-over-HTTPS (DoH) e DNS-over-TLS (DoT).
- DNS/resolver personalizado.
- Configuração persistente em `~/.config/slowdns`.
- `start`, `stop`, `restart`, `status`, `logs` e `doctor`.
- Instalador de servidor para Debian/Ubuntu.
- Serviço `systemd` com usuário dedicado `dnstt`.
- Geração e preservação de chaves do servidor.
- Diagnóstico do servidor.
- Laboratório local ponta a ponta que não exige domínio nem VPS.
- Scripts de 2021 preservados como referência histórica.

## Arquitetura

```text
Aplicação TCP local
        |
        v
  dnstt-client
        |
        | consultas DNS
        v
 Resolver recursivo
        |
        v
 subdomínio delegado
        |
        v
  dnstt-server
        |
        v
 Backend TCP (ex.: SSH)
```

O DNSTT encapsula fluxos TCP em mensagens DNS. O cliente pode falar com o resolver usando UDP, DoH ou DoT. O servidor recebe as consultas destinadas ao subdomínio delegado e encaminha o fluxo reconstruído para um backend TCP configurado.

## Teste local primeiro

Antes de configurar domínio ou VPS, é possível comprovar o túnel na própria máquina Linux.

Requisitos: `go`, `curl` e `python3`.

```bash
git clone https://github.com/SrTristeSad/Slowdns.git
cd Slowdns
bash lab/local-test.sh
```

O teste cria temporariamente:

```text
curl :18081
   -> dnstt-client
   -> DNS/UDP 127.0.0.1:5300
   -> dnstt-server
   -> servidor HTTP :18080
```

Ao final, a saída esperada é:

```text
OK: túnel DNSTT local funcionando ponta a ponta.
```

Nada é instalado permanentemente por esse teste.

---

# Instalação real

## 1. Requisitos do servidor

- VPS Debian/Ubuntu com acesso root.
- Domínio próprio com controle dos registros DNS.
- UDP/53 disponível na VPS.
- Um backend TCP para receber a conexão, por padrão `127.0.0.1:22` (SSH).

## 2. Delegação DNS

Exemplo:

- domínio: `exemplo.com`
- túnel: `t.exemplo.com`
- IPv4 da VPS: `203.0.113.10`

Crie no provedor DNS:

```dns
A   tns.exemplo.com   203.0.113.10
NS  t.exemplo.com     tns.exemplo.com
```

O hostname do nameserver (`tns.exemplo.com`) fica fora da zona que está sendo delegada (`t.exemplo.com`).

A propagação DNS pode levar algum tempo dependendo do provedor e do TTL.

## 3. Instalar o servidor

```bash
git clone https://github.com/SrTristeSad/Slowdns.git
cd Slowdns
sudo bash server/install.sh t.exemplo.com 127.0.0.1:22
```

O instalador:

1. instala as dependências;
2. instala `dnstt-server@latest`;
3. cria o usuário de serviço `dnstt`;
4. gera o par de chaves na primeira instalação;
5. cria `dnstt.service`;
6. inicia o servidor em UDP/53;
7. exibe a chave pública que será usada no Android.

Reexecutar o instalador **preserva as chaves existentes**.

### Diagnóstico do servidor

```bash
sudo slowdns-server-doctor
```

Ou diretamente pelo repositório:

```bash
sudo bash server/doctor.sh
```

O diagnóstico verifica binário, chaves, serviço, UDP/53 e a delegação NS pública.

### Comandos úteis do servidor

```bash
systemctl status dnstt --no-pager
journalctl -u dnstt -f
cat /etc/dnstt/server.pub
```

A chave privada fica em:

```text
/etc/dnstt/server.key
```

Não publique nem compartilhe essa chave.

## 4. Instalar no Android / Termux

Use uma versão atual do Termux.

```bash
pkg install git -y
git clone https://github.com/SrTristeSad/Slowdns.git
cd Slowdns
bash client/install-termux.sh
```

Na primeira instalação, o configurador pede:

- domínio do túnel;
- chave pública exibida pela VPS;
- resolver UDP padrão;
- endereço TCP local;
- transporte padrão;
- endpoint DoH/DoT opcional.

Depois basta executar:

```bash
slowdns
```

## Comandos do cliente

```bash
slowdns
slowdns config
slowdns status
slowdns doctor
slowdns logs
slowdns stop
slowdns version
slowdns help
```

### UDP clássico

```bash
slowdns start google
slowdns start cloudflare
slowdns start quad9
slowdns start opendns
```

DNS personalizado:

```bash
slowdns start udp 192.0.2.53
```

### DoH

```bash
slowdns start doh-google
slowdns start doh-cloudflare
```

Endpoint personalizado:

```bash
slowdns start doh https://resolver.exemplo/dns-query
```

### DoT

```bash
slowdns start dot-google
slowdns start dot-cloudflare
```

Endpoint personalizado:

```bash
slowdns start dot resolver.exemplo:853
```

## Testar o backend SSH

Com o servidor apontando para `127.0.0.1:22` e o cliente usando o padrão `127.0.0.1:2222`:

```bash
slowdns start google
ssh -p 2222 usuario@127.0.0.1
```

A aplicação SSH fala apenas com a porta TCP local. O DNSTT transporta o fluxo até o backend configurado na VPS.

## Atualizar

No clone local:

```bash
git pull
bash client/install-termux.sh
```

O instalador preserva `~/.config/slowdns/config` quando já existe.

No servidor:

```bash
cd Slowdns
git pull
sudo bash server/install.sh t.exemplo.com 127.0.0.1:22
```

As chaves existentes em `/etc/dnstt` são mantidas.

## Estrutura

```text
Slowdns/
├── slowdns                    # cliente principal / menu
├── client/
│   └── install-termux.sh      # instalador Android/Termux
├── server/
│   ├── install.sh             # instalador Debian/Ubuntu
│   └── doctor.sh              # diagnóstico da VPS
├── lab/
│   └── local-test.sh          # teste ponta a ponta local
├── slowdns.txt                # versão histórica de 2021
├── robinhood                  # base histórica
└── RobinHood.txt              # base histórica
```

## Versão histórica de 2021

O repositório original usava domínio, chave e resolvers fixos dentro do próprio script e compilava o DNSTT diretamente no Termux. Esses arquivos continuam no Git para preservar a história do projeto.

A versão atual não depende de `t.srtriste.cloudns.cl`, `t.rgntunnel.online` nem das antigas chaves gravadas nos scripts.

## Limitações

DNS tunneling possui bastante overhead. Ele normalmente terá maior latência e menor throughput que uma conexão TCP/UDP direta. O desempenho também depende do resolver, TTLs, MTU, rede e política do provedor.

O SlowDNS não é, sozinho, uma VPN IP completa. O DNSTT cria um encaminhamento **TCP** entre uma porta local e o backend configurado no servidor. SSH, proxies ou outros serviços TCP podem ser usados por cima dele quando isso fizer sentido.

## Segurança

- Mantenha a chave privada apenas na VPS.
- Não execute scripts desconhecidos como root.
- Revise o conteúdo de `server/install.sh` antes da instalação.
- Mantenha Termux, Go e o sistema da VPS atualizados.
- Restrinja os outros serviços da VPS normalmente; o túnel não substitui firewall nem autenticação.
- Use somente infraestrutura e redes em que você tenha autorização.

## Origem

Este repositório começou como um pequeno script SlowDNS em 2021 e foi retomado em 2026 mantendo a ideia e a interface simples do projeto original, mas substituindo dependências e práticas antigas por uma estrutura atualizável.
