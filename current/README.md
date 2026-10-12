# SlowDNS 3.x — código atual

Esta pasta contém a versão mantida do projeto.

## Componentes

```text
current/
├── DNSTT_VERSION
├── slowdns
├── client/
│   ├── install-termux.sh
│   └── uninstall.sh
├── server/
│   ├── install.sh
│   ├── doctor.sh
│   └── uninstall.sh
└── lab/
    └── local-test.sh
```

`DNSTT_VERSION` define a revisão do DNSTT usada pelos instaladores e pelo laboratório. A versão atual está fixada em `v1.20260501.0`; não usamos `@latest` para evitar instalações diferentes sem mudança no SlowDNS.

## Teste local

```bash
bash lab/local-test.sh
```

O teste instala o DNSTT temporariamente, confirma que o cliente possui suporte a UDP/DoH/DoT e valida tráfego TCP ponta a ponta usando DNS/UDP.

## Termux

```bash
bash client/install-termux.sh
```

Desinstalar preservando configuração:

```bash
slowdns-uninstall
```

Apagar também a configuração:

```bash
slowdns-uninstall --purge
```

## Servidor Debian/Ubuntu

```bash
sudo bash server/install.sh t.exemplo.com 127.0.0.1:22
```

Diagnóstico:

```bash
sudo slowdns-server-doctor
```

Desinstalar preservando `/etc/dnstt`:

```bash
sudo slowdns-server-uninstall
```

Apagar também chaves e configuração:

```bash
sudo slowdns-server-uninstall --purge
```
