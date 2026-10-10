# SlowDNS / DNSTT

Versão modernizada do antigo script deste repositório, baseada no `dnstt` atual e separada em cliente Termux e servidor Linux.

Este projeto é destinado a testes e uso em redes e servidores sob sua autorização. Ele não transforma um plano móvel em internet grátis ou ilimitada.

## Requisitos

- VPS Debian/Ubuntu com acesso root.
- Domínio próprio com controle de registros DNS.
- UDP/53 disponível na VPS.
- Termux atualizado no Android.

## DNS

Exemplo para uma VPS `203.0.113.10` e domínio `exemplo.com`:

```dns
A   tns.exemplo.com   203.0.113.10
NS  t.exemplo.com     tns.exemplo.com
```

O subdomínio `t.exemplo.com` é delegado para a VPS. O hostname `tns.exemplo.com` deve ficar fora da zona delegada.

## Servidor

```bash
git clone https://github.com/SrTristeSad/Slowdns.git
cd Slowdns
sudo bash server/install.sh t.exemplo.com 127.0.0.1:22
```

O instalador gera um novo par de chaves e cria `dnstt.service`.

Status:

```bash
systemctl status dnstt --no-pager
```

Logs:

```bash
journalctl -u dnstt -f
```

Chave pública:

```bash
cat /etc/dnstt/server.pub
```

A chave privada fica em `/etc/dnstt/server.key` e não deve ser compartilhada.

## Cliente Termux

```bash
cd Slowdns
bash client/install-termux.sh
```

Na configuração, informe o domínio do túnel, a chave pública gerada pela VPS, o resolver DNS desejado e o endereço local.

Comandos:

```bash
slowdns
slowdns start google
slowdns start cloudflare
slowdns start quad9
slowdns start opendns
slowdns status
slowdns log
slowdns stop
slowdns config
```

## Teste básico

Se o backend configurado na VPS for o SSH local (`127.0.0.1:22`) e o endereço local do cliente permanecer em `127.0.0.1:2222`, você pode verificar a conexão com um cliente SSH apontando para `127.0.0.1` porta `2222`.

## Arquivos antigos

`slowdns.txt`, `robinhood` e `RobinHood.txt` foram mantidos apenas como referência histórica da versão de 2021. A instalação moderna usa `slowdns`, `client/install-termux.sh` e `server/install.sh`.

## Observações

- Libere UDP/53 apenas na infraestrutura que você administra.
- Se a porta 53 já estiver ocupada por outro serviço DNS, `dnstt.service` não iniciará.
- Mantenha VPS, Termux e dependências atualizados.
