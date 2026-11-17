# DebitMyData pool installer

Installs the DebitMyData mining pool, as it runs on
[pool.debitmydata.io](https://pool.debitmydata.io), on one server: YiiMP with DebitMyData's
changes ([debitmydata-yiimp](https://github.com/DebitMyData-PoW/debitmydata-yiimp)), on
**Ubuntu 24.04 with PHP 8.3**.

- PPLNS paid in the block itself, and solo mining (password `m=solo`), on the DMD stratum port
- My wallet, with notifications on the phone or the computer, and the installable pool app
- The website on nginx with HTTPS, behind Cloudflare (or with Let's Encrypt), the admin portal
  behind a password
- MariaDB, memcached, the firewall, and the jobs that start with the server

## What you need

- A **fresh Ubuntu 24.04** server (x86_64). 4 GB of memory or more is best; 1 GB is the minimum.
- Root access with an SSH key.
- Two names pointing to the server's IP (DNS A records):
  - the website, like `pool.example.com`. With Cloudflare, it can be **proxied** (the orange
    cloud) from the start: the server's IP stays hidden;
  - the stratum, like `stratum.example.com`. It must be **DNS only** (the grey cloud):
    Cloudflare's proxy does not carry mining connections.
- For HTTPS, one of:
  - **with Cloudflare** (recommended): a Cloudflare origin certificate (below);
  - **without Cloudflare**: an email address for Let's Encrypt, and the website's name pointing
    to the server directly.

### The Cloudflare origin certificate

Cloudflare makes it, for up to 15 years, and only Cloudflare trusts it: visitors see
Cloudflare's own certificate, and Cloudflare checks this one on the way to the server. Make it
just before the install, which asks you to paste it:

1. In Cloudflare, open your domain, then **SSL/TLS**, **Origin Server**, **Create Certificate**.
2. Keep "Generate private key and CSR with Cloudflare" (RSA) and the host names Cloudflare
   suggests (your domain and `*.` your domain: they cover `pool.` your domain), choose
   **15 years**, and create it.
3. Keep the page open, in PEM format: the install asks for the **Origin Certificate**, then the
   **Private Key**. Cloudflare shows the private key only once: also put it in your password
   manager.
4. In **SSL/TLS**, **Overview**, set the encryption mode to **Full (strict)**.

The install keeps them in `/etc/ssl/cloudflare/` (the key readable only by root).

## Install

1. Log in to the server as root, and run:

   ```
   curl -fsSL https://raw.githubusercontent.com/DebitMyData-PoW/Multi-Pool-Installer/master/bootstrap.sh | bash
   ```

2. The pool does not run as root: the installer makes a user account for it. Choose its name
   and password (put the password in your password manager). Root's SSH keys are copied to it,
   so the same key logs in.
3. Reboot (`reboot`), then log in as the new user and type:

   ```
   multipool
   ```

4. Choose **YiiMP single server**, and answer the questions (below). The install then runs by
   itself, for about 20 minutes.
5. When it says so, reboot again (`sudo reboot`). After about a minute, type `motd`: main,
   loop2, blocks and debug should say running.

### The questions

| Question | Default | |
| :-- | :-- | :-- |
| Using sub-domain | | Yes for `pool.example.com`; no for `example.com` (then `www.example.com` too) |
| Website and HTTPS | Cloudflare | **Through Cloudflare** (proxied): the Cloudflare origin certificate, nginx sees the visitors' real IPs, and only Cloudflare reaches ports 80 and 443. **Directly**: Let's Encrypt (DNS only). **HTTP only**: the server's IP, no domain |
| Domain name | the server's IP | The website's name, without `www.` |
| Cloudflare origin certificate | | With Cloudflare: the editor opens twice, for the certificate, then its private key (paste, Ctrl+O, Enter, Ctrl+X) |
| Stratum URL | the domain name | What miners connect to |
| Admin email | | Shown on the website; with Let's Encrypt, its notices go to it |
| Your public IP | from your SSH connection | The IP of the computer you run the admin from |
| DMD stratum port | 8700 | Miners connect to it; it is opened in the firewall |
| Admin portal user | `pooladmin` | nginx asks for it on `/site/AdminPortal` |
| Admin portal password | random | Keep it in your password manager |
| Database passwords | random | Keep them: nobody needs to type them |

The answers, with the passwords, are saved in `/home/crypto-data/yiimp/.yiimp.conf`, which only
the install user can read.

## After the install

1. **The DMD node.** Build DMD Core on the server (the installer has installed what it needs:
   CMake and the libraries) and run it with RPC on 127.0.0.1 only.
2. **The DMD coin**, in the admin portal (`https://<your site>/site/AdminPortal`): add DMD,
   algorithm sha256, with the node's RPC port, user and password. In its settings:
   - Dedicated port: the DMD stratum port (8700);
   - Charity percent: 0;
   - Has masternodes: off.

   The coin's page also shows the lines the node's config needs, `blocknotify` among them.
3. **The home page's explorer link** is `block_explorer` + `address/` + `master_wallet`, from the
   DMD coin. Its settings in the admin have the master wallet (the pool's address); the explorer
   is set once on the server:

   ```
   sudo mysql yiimpfrontend -e "UPDATE coins SET block_explorer='https://mempool.debitmydata.io/' WHERE symbol='DMD'"
   ```
4. **The fees** are in three places that must agree: `YAAMP_FEES_MINING` in
   `configuration/serverconfig.php` (0.5), `fee` and `solo_fee` in the `[PPLNS]` section of
   `stratum/config/dmd.sha.conf` (0.5 and 1), and `$fee_pool`, `$fee_solo` at the top of
   `web/yaamp/modules/site/index.php` (shown on the home page).
5. **Notifications** start with the server: `systemctl is-active dmd-pool-push` says `active`.
   Their keys are `configuration/push-vapid.pem` and `configuration/push.php`: back them up. A new
   key means every device turns notifications on again, so move both with the pool.

### HTTPS later, with Let's Encrypt

If Let's Encrypt refused the certificate during the install (the domain did not point to the
server yet), the website runs on HTTP. Once the domain points to it:

```
bash ~/multipool/yiimp_single/https.sh
```

### Cloudflare's addresses

With Cloudflare, only Cloudflare's addresses reach ports 80 and 443 (the firewall's rules
marked `# Cloudflare`), and `/etc/nginx/conf.d/cloudflare-real-ip.conf` takes the visitor's IP
from them only. Nobody can go around Cloudflare to the server's own IP. Cloudflare rarely
changes its list (https://www.cloudflare.com/ips/); when it does, update both at once:

```
bash ~/multipool/yiimp_single/cloudflare.sh
```

It adds the new addresses before it removes the old ones, so the website is never cut off.

### Looking at the database

There is no phpMyAdmin on the server: the database holds every miner's balance, and a web page
for it would be one more door in. From Windows, [HeidiSQL](https://www.heidisql.com/) (free)
reaches it through SSH, with the key you already log in with:

1. In HeidiSQL, **New** session. Network type: **MariaDB or MySQL (SSH tunnel)**.
   Hostname `127.0.0.1`, user `panel`, port `3306`, and the password from
   `/home/crypto-data/yiimp/.my.cnf` (`[clienthost1]`, `password=`).
2. In the **SSH tunnel** tab: the SSH program (`plink.exe`, or `ssh.exe` with an OpenSSH key),
   the server and its SSH port, your user name, your private key file, and a free local port
   such as `3307`.
3. **Open**, then the `yiimpfrontend` database.

The database itself is never reachable from the internet: MariaDB only listens on the server.

## Where things are

| Folder | |
| :-- | :-- |
| `/home/crypto-data/yiimp/site/web` | The website |
| `/home/crypto-data/yiimp/site/configuration` | `serverconfig.php` (settings), `push.php` and `push-vapid.pem` (notifications) |
| `/home/crypto-data/yiimp/site/stratum` | The stratum; its config files in `config/` (`dmd.sha.conf`: the DMD port) |
| `/home/crypto-data/yiimp/site/crons` | The jobs: `main.sh`, `loop2.sh`, `blocks.sh` |
| `/home/crypto-data/yiimp/site/log` | `debug.log`, nginx's error log, and who opened the admin portal (`<site>.access.log`) |
| `/home/crypto-data/yiimp/site/backup` | The database backups |
| `/home/crypto-data/yiimp/starts` | What starts at boot: `screens.start.sh`, `stratum.start.sh` |
| `/home/crypto-data/wallets` | For the coin nodes' data |
| `/etc/yiimp/keys.php` | The website's secrets |
| `/etc/nginx/sites-available/<site>.conf`, `/etc/nginx/snippets/yiimp-site.conf` | The website's nginx config |
| `/etc/ssl/cloudflare/<site>.pem`, `<site>.key` | The Cloudflare origin certificate and its key |

## Commands

| Command | |
| :-- | :-- |
| `motd` | The jobs' screens, running or stopped |
| `screen -r main` (or `loop2`, `blocks`, `debug`, `dmd`) | Look at a screen; Ctrl+A then D to leave it |
| `screens start\|stop\|restart main\|loop2\|blocks\|debug` | Start, stop or restart a job |
| `yiimp` | YiiMP's own commands |
| `sudo ufw allow <port>` | Open another stratum port. Open after the install: SSH, the DMD port, and HTTP and HTTPS (from Cloudflare only, behind Cloudflare) |

## Security

- **The admin portal** is protected by nginx's password (`/etc/nginx/.pma_pass_panel`); the
  website itself lets in whoever gets past it. Never remove the `location /site/AdminPortal`
  block from `/etc/nginx/snippets/yiimp-site.conf`. To change the password:

  ```
  printf '%s:%s\n' pooladmin "$(openssl passwd -apr1)" | sudo tee /etc/nginx/.pma_pass_panel
  ```

- **Secrets** stay on the server and out of any repository: `.yiimp.conf` and `.my.cnf`
  (`/home/crypto-data/yiimp`), `serverconfig.php`, `keys.php`, the stratum's `*.conf`
  (database password) and `push-vapid.pem`. Only the install user and the website can read them.
- **SSH keys only**: once you log in with your key as the new user, turn off password logins:

  ```
  printf 'PasswordAuthentication no\nKbdInteractiveAuthentication no\nPermitRootLogin prohibit-password\n' | sudo tee /etc/ssh/sshd_config.d/00-keys-only.conf
  sudo sshd -t && sudo systemctl reload ssh
  ```

  Then, from your computer, `ssh -o PubkeyAuthentication=no <user>@<server>` must answer
  `Permission denied (publickey)`.

To report a security problem, write to info@debitmydata.com with the subject line
`Security: DebitMyData pool`. Please don't open a public issue for it.

## Versions

The installer comes in three repositories, each downloaded by the one before:

1. [Multi-Pool-Installer](https://github.com/DebitMyData-PoW/Multi-Pool-Installer) (this one): `bootstrap.sh`
2. [multipool_setup](https://github.com/DebitMyData-PoW/multipool_setup): the checks, the user account, the menu
3. [multipool_yiimp_single](https://github.com/DebitMyData-PoW/multipool_yiimp_single): the install itself

Each one's `master` branch is used. To try another branch or tag: `SETUP_REF=<ref>` before
`bash` in step 1, `SINGLE_REF=<ref> multipool` for the install, and `YIIMP_REF=<ref> multipool`
for the pool's code (the `ubuntu-24.04` branch of debitmydata-yiimp by default).

## Credits

- [Mail-in-a-Box](https://github.com/mail-in-a-box/mailinabox), where the installer's structure comes from
- cryptopool.builders and Original-Tasty, for the Ultimate Crypto-Server Setup Installer (its README gave its license as MIT)
- [le2Ks](https://github.com/le2Ks/Multi-Pool-Installer), for its update of that installer
- [tpruvot](https://github.com/tpruvot/yiimp), for YiiMP
