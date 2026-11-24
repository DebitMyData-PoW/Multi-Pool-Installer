# DebitMyData pool installer

Sets up a complete DebitMyData mining pool on one fresh server, in about 20 minutes, with a few
questions: the same pool that runs at [pool.debitmydata.io](https://pool.debitmydata.io).
It installs [debitmydata-yiimp](https://github.com/DebitMyData-PoW/debitmydata-yiimp), YiiMP with
DebitMyData's changes, on **Ubuntu 24.04 with PHP 8.3**.

## What it sets up

- **The pool**: PPLNS payouts paid in the block itself, and solo mining (password `m=solo`), on the
  DMD stratum port.
- **My wallet**: each miner's workers, earnings, payouts and blocks, with notifications on the
  phone or the computer, and the pool's installable app.
- **The website** on nginx with HTTPS, behind Cloudflare (or with Let's Encrypt), with the admin
  portal behind its own password.
- **MariaDB, memcached, the firewall**, and the jobs that start with the server.
- **Hardening**: the pool runs under its own user, not root; only Cloudflare reaches the web ports;
  the database is never reachable from the internet; secrets stay on the server, readable by the
  pool only.

## How it is built

The installer comes in three repositories, each downloaded by the one before:

1. **Multi-Pool-Installer** (this one): `bootstrap.sh`, the one command to run.
2. [multipool_setup](https://github.com/DebitMyData-PoW/multipool_setup): the checks, the user
   account the pool runs as, the menu.
3. [multipool_yiimp_single](https://github.com/DebitMyData-PoW/multipool_yiimp_single): the
   install itself.

## Installation

See **[INSTALL.md](INSTALL.md)**: what you need, the install and its questions, what to do after
it, where things are, the commands, and keeping the server safe.

## Security

To report a security problem, write to info@debitmydata.com with the subject line
`Security: DebitMyData pool`. Please don't open a public issue for it.

## Credits

- [Mail-in-a-Box](https://github.com/mail-in-a-box/mailinabox), where the installer's structure comes from
- cryptopool.builders and Original-Tasty, for the Ultimate Crypto-Server Setup Installer (its README gave its license as MIT)
- [le2Ks](https://github.com/le2Ks/Multi-Pool-Installer), for its update of that installer
- [tpruvot](https://github.com/tpruvot/yiimp), for YiiMP
