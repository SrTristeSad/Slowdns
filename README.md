# SrTriste SlowDNS

[![SlowDNS CI](https://github.com/SrTristeSad/Slowdns/actions/workflows/ci.yml/badge.svg)](https://github.com/SrTristeSad/Slowdns/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

SlowDNS é um projeto de túnel **TCP sobre DNS** baseado em [DNSTT](https://www.bamsoftware.com/software/dnstt/), originalmente criado neste repositório em 2021 e retomado em 2026 com uma implementação nova, organizada e testável.

A versão atual fornece cliente para **Android/Termux**, instalador de servidor para **Debian/Ubuntu**, configuração persistente, diagnóstico, suporte a UDP/DoH/DoT no cliente e um laboratório local para validar o túnel ponta a ponta sem depender de domínio ou VPS.

> **Uso responsável:** utilize somente em redes, domínios e servidores que você administra ou nos quais possui autorização. SlowDNS não promete “internet grátis”, não altera cobrança de operadora e não depende de uma falha específica de provedor.

---

## Estado do projeto

| Item | Estado |
|---|---|
| Cliente Termux | Implementado |
| Servidor Debian/Ubuntu | Implementado |
| Transporte DNS/UDP | Implementado e coberto pelo teste local |
| DNS-over-HTTPS (DoH) | Implementado no cliente |
| DNS-over-TLS (DoT) | Implementado no cliente |
| Configuração persistente | Implementada |
| Serviço `systemd` | Implementado |
| Diagnóstico cliente/servidor | Implementado |
| Teste local ponta a ponta | Implementado |
| CI no GitHub Actions | Ativo |

O workflow de CI valida a sintaxe Bash dos scripts atuais e executa `lab/local-test.sh`, que cria cliente, servidor e backend temporários e confirma tráfego TCP através do túnel DNSTT.

Isso comprova o funcionamento do núcleo em ambiente Linux de CI. Uma instalação real ainda depende da configuração correta de DNS, firewall, UDP/53, VPS, domínio e backend escolhidos pelo administrador.

---

# Versão atual e versão histórica

O repositório contém **duas gerações diferentes** do projeto. Elas são preservadas separadamente na documentação para evitar confusão.

## Atual — SlowDNS 3.x (2026)

Esta é a versão recomendada.

Arquivos principais:

```text
slowdns
client/install-termux.sh
server/install.sh
server/doctor.sh
lab/local-test.sh
.github/workflows/ci.yml
```

Características:

- cliente moderno para Termux;
- instalação atual do `dnstt-client` via Go;
- servidor `dnstt-server` para Debian/Ubuntu;
- perfis UDP para Google, Cloudflare, Quad9 e OpenDNS;
- suporte a DoH e DoT no cliente;
- resolver personalizado;
- configuração persistente em `~/.config/slowdns`;
- comandos `start`, `stop`, `restart`, `status`, `logs`, `doctor`, `config` e `version`;
- serviço `systemd` no servidor;
- usuário de serviço dedicado `dnstt`;
- geração e preservação das chaves do servidor;
- laboratório local ponta a ponta;
- CI automática.

## Legado — scripts de 2021

Os arquivos abaixo pertencem à geração antiga e são mantidos **somente como referência histórica**:

```text
slowdns.txt
robinhood
RobinHood.txt
```

Esses arquivos podem conter procedimentos, domínios, resolvers, chaves ou práticas que fizeram sentido no projeto original, mas **não representam a instalação recomendada atualmente**.

Para uma instalação nova, use exclusivamente os arquivos da versão 3.x descritos neste README.

---

# O que o SlowDNS faz

O DNSTT encapsula um fluxo TCP dentro de mensagens DNS.

Em uma instalação típica:

```text
Aplicação TCP local
        |
        v
  dnstt-client
        |
        | consultas DNS
        v
 Resolver DNS
        |
        v
 subdomínio delegado
        |
        v
  dnstt-server
        |
        v
 Backend TCP
```

Exemplo usando SSH:

```text
ssh -> 127.0.0.1:2222
        |
        v
   dnstt-client
        |
        v
      DNS
        |
        v
   dnstt-server
        |
        v
  127.0.0.1:22
```

A aplicação local não precisa entender DNS tunneling. Ela conversa com uma porta TCP local e o DNSTT transporta esse fluxo até o backend TCP configurado na VPS.

## O que ele não é

SlowDNS, sozinho, **não é uma VPN IP completa**. O projeto cria um encaminhamento TCP através do DNSTT.

Protocolos ou aplicações que precisem de um túnel IP completo, UDP arbitrário ou roteamento de todo o dispositivo precisam de uma camada adicional apropriada.

---

# Teste local antes de instalar

O laboratório permite verificar o núcleo do projeto sem domínio, VPS ou alteração permanente no sistema.

Requisitos:

- Linux;
- Go;
- `curl`;
- `python3`.

Execute:

```bash
git clone https://github.com/SrTristeSad/Slowdns.git
cd Slowdns
bash lab/local-test.sh
```

O laboratório monta temporariamente:

```text
curl :18081
   -> dnstt-client
   -> DNS/UDP 127.0.0.1:5300
   -> dnstt-server
   -> servidor HTTP :18080
```

Resultado esperado:

```text
OK: túnel DNSTT local funcionando ponta a ponta.
HTTP -> dnstt-client -> DNS/UDP -> dnstt-server -> HTTP
```

Os binários e arquivos gerados pelo laboratório ficam em um diretório temporário e são removidos ao final.

---

# Instalação real

## 1. Requisitos do servidor

Você precisa de:

- VPS Debian/Ubuntu;
- acesso `root` ou `sudo`;
- domínio próprio;
- controle dos registros DNS;
- UDP/53 disponível na VPS;
- backend TCP para receber a conexão.

O backend padrão do instalador é:

```text
127.0.0.1:22
```

ou seja, SSH local da própria VPS.

---

## 2. Delegar um subdomínio DNS

Exemplo:

```text
Domínio: exemplo.com
Túnel:   t.exemplo.com
VPS:     203.0.113.10
```

Crie registros equivalentes a:

```dns
A   tns.exemplo.com   203.0.113.10
NS  t.exemplo.com     tns.exemplo.com
```

O hostname usado como nameserver deve ficar fora da zona delegada. No exemplo, `tns.exemplo.com` fica fora de `t.exemplo.com`.

A propagação depende do provedor DNS e do TTL configurado.

---

## 3. Instalar o servidor

Na VPS:

```bash
git clone https://github.com/SrTristeSad/Slowdns.git
cd Slowdns
sudo bash server/install.sh t.exemplo.com 127.0.0.1:22
```

O instalador atual:

1. instala as dependências necessárias;
2. instala `dnstt-server@latest` via Go;
3. cria o usuário de serviço `dnstt` quando necessário;
4. cria `/etc/dnstt`;
5. gera o par de chaves na primeira instalação;
6. preserva chaves já existentes em reinstalações;
7. cria `dnstt.service`;
8. inicia o DNSTT em UDP/53;
9. mostra a chave pública necessária no cliente.

### Arquivos principais no servidor

```text
/etc/dnstt/server.key   chave privada
/etc/dnstt/server.pub   chave pública
/etc/dnstt/domain       domínio do túnel
/etc/dnstt/backend      backend TCP
/etc/dnstt/listen       endereço UDP de escuta
```

Nunca publique `server.key`.

### Status e logs

```bash
systemctl status dnstt --no-pager
journalctl -u dnstt -f
```

### Diagnóstico

```bash
sudo slowdns-server-doctor
```

ou, dentro do clone:

```bash
sudo bash server/doctor.sh
```

O diagnóstico verifica itens como binário, chaves, serviço, UDP/53 e delegação DNS.

---

# Instalação no Android / Termux

Use uma versão atual do Termux.

```bash
pkg install git -y
git clone https://github.com/SrTristeSad/Slowdns.git
cd Slowdns
bash client/install-termux.sh
```

O instalador:

- atualiza o índice do Termux;
- instala Go, Git, certificados, cURL, OpenSSH e ferramentas DNS;
- instala `dnstt-client@latest`;
- instala o comando `slowdns` em `$PREFIX/bin`;
- preserva a configuração existente quando ela já existe;
- abre a configuração inicial na primeira instalação.

## Configuração inicial

O cliente solicita:

- domínio do túnel;
- chave pública do servidor;
- resolver DNS UDP padrão;
- endereço TCP local;
- transporte padrão;
- endpoint DoH;
- endpoint DoT.

A configuração fica em:

```text
~/.config/slowdns/config
```

com permissão restrita ao usuário.

---

# Uso do cliente

Abrir o menu:

```bash
slowdns
```

Comandos principais:

```bash
slowdns config
slowdns start
slowdns stop
slowdns restart
slowdns status
slowdns doctor
slowdns logs
slowdns version
slowdns help
```

## Perfis UDP

```bash
slowdns start google
slowdns start cloudflare
slowdns start quad9
slowdns start opendns
```

Resolver personalizado:

```bash
slowdns start udp 192.0.2.53
```

## DNS-over-HTTPS

```bash
slowdns start doh-google
slowdns start doh-cloudflare
```

Endpoint personalizado:

```bash
slowdns start doh https://resolver.exemplo/dns-query
```

## DNS-over-TLS

```bash
slowdns start dot-google
slowdns start dot-cloudflare
```

Endpoint personalizado:

```bash
slowdns start dot resolver.exemplo:853
```

> O CI atual testa automaticamente o caminho DNS/UDP local. DoH e DoT estão implementados no cliente, mas não fazem parte desse teste ponta a ponta automatizado.

---

# Exemplo com SSH

Com o servidor configurado para:

```text
127.0.0.1:22
```

e o cliente usando:

```text
127.0.0.1:2222
```

inicie o túnel:

```bash
slowdns start google
```

Depois conecte o SSH à porta local:

```bash
ssh -p 2222 usuario@127.0.0.1
```

O SSH se conecta apenas ao endpoint TCP local; o DNSTT transporta o fluxo até o backend configurado na VPS.

---

# Atualização

## Cliente

Dentro do clone:

```bash
git pull
bash client/install-termux.sh
```

Se `~/.config/slowdns/config` já existir, o instalador o preserva.

## Servidor

```bash
cd Slowdns
git pull
sudo bash server/install.sh t.exemplo.com 127.0.0.1:22
```

As chaves existentes em `/etc/dnstt` são preservadas quando já estão presentes.

---

# Estrutura do repositório

```text
Slowdns/
├── .github/
│   └── workflows/
│       └── ci.yml              # testes automáticos
├── client/
│   └── install-termux.sh       # instalador do cliente atual
├── server/
│   ├── install.sh              # instalador atual da VPS
│   └── doctor.sh               # diagnóstico do servidor
├── lab/
│   └── local-test.sh           # teste DNSTT ponta a ponta local
├── slowdns                     # cliente atual / menu / CLI
├── CHANGELOG.md
├── README.md
├── LICENSE
│
├── slowdns.txt                 # legado de 2021
├── robinhood                   # legado de 2021
└── RobinHood.txt               # legado de 2021
```

---

# Diagnóstico de problemas

No cliente:

```bash
slowdns doctor
slowdns status
slowdns logs
```

No servidor:

```bash
sudo slowdns-server-doctor
systemctl status dnstt --no-pager
journalctl -u dnstt -n 100 --no-pager
```

Problemas comuns em uma implantação real incluem:

- UDP/53 bloqueado pelo provedor ou firewall;
- outro serviço já ocupando a porta 53;
- delegação NS incorreta;
- DNS ainda não propagado;
- chave pública diferente da chave da VPS;
- domínio do cliente diferente do configurado no servidor;
- backend TCP indisponível.

---

# Limitações

DNS tunneling possui overhead considerável. Normalmente haverá maior latência e menor throughput do que em uma conexão TCP/UDP direta.

O desempenho depende, entre outros fatores, de:

- resolver utilizado;
- rede entre cliente e resolver;
- MTU;
- comportamento do provedor DNS;
- latência da VPS;
- backend TCP;
- políticas da rede.

Não existe garantia de funcionamento em qualquer rede.

---

# Segurança

- mantenha a chave privada somente na VPS;
- não compartilhe `/etc/dnstt/server.key`;
- mantenha Termux, Go e o sistema da VPS atualizados;
- revise scripts antes de executá-los como `root`;
- mantenha autenticação e firewall do backend normalmente;
- não trate o túnel como substituto de controles de segurança;
- use somente infraestrutura e redes nas quais você tenha autorização.

---

# Dependência principal

Este projeto utiliza DNSTT como componente de transporte:

- projeto: `www.bamsoftware.com/software/dnstt/`
- instalação pelo código atual: `www.bamsoftware.com/git/dnstt.git/...@latest`

O DNSTT é um projeto independente e continua sujeito à licença e aos termos do próprio projeto.

---

# Licença

O código próprio deste repositório é disponibilizado sob a **MIT License**. Consulte o arquivo [`LICENSE`](LICENSE).

Componentes e dependências externas continuam sujeitos às respectivas licenças.

---

# Histórico

O SlowDNS começou neste repositório como um conjunto simples de scripts em 2021. Em 2026, o projeto foi retomado como SlowDNS 3.x, preservando os arquivos históricos, mas substituindo a instalação e operação principal por uma estrutura moderna com cliente, servidor, diagnóstico, configuração persistente, laboratório local e CI.

Para mudanças por versão, consulte [`CHANGELOG.md`](CHANGELOG.md).
