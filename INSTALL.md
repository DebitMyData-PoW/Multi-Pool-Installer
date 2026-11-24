# Installing a DebitMyData mining pool

These steps set up a DebitMyData mining pool on a server of your own. Below, `example.com`,
`pool.example.com` and `stratum.example.com` stand for your own domain and names.

## What you need

- A **fresh Ubuntu 24.04** server (x86_64). 4 GB of memory or more is best; 1 GB is the minimum.
- Root access with an SSH key.
- Two names pointing to the server's IP address (DNS A records):
  - the website, like `pool.example.com`. With Cloudflare, it can be **proxied** (the orange
    cloud) from the start: the server's IP address stays hidden;
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
   suggests (`example.com` and `*.example.com`: they cover `pool.example.com`), choose
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
| Website and HTTPS | Cloudflare | **Through Cloudflare** (proxied): the Cloudflare origin certificate, nginx sees the visitors' real IP addresses, and only Cloudflare reaches ports 80 and 443. **Directly**: Let's Encrypt (DNS only). **HTTP only**: the server's IP address, no domain |
| Domain name | the server's IP | The website's name, without `www.` |
| Cloudflare origin certificate | | With Cloudflare: the editor opens twice, for the certificate, then its private key (paste, Ctrl+O, Enter, Ctrl+X) |
| Stratum URL | the domain name | What miners connect to |
| Android app (Google Play) | none | If you publish the website as an Android app on Google Play (Bubblewrap): its package name, like `com.example.pool`. The website then knows when that app is installed. Empty if you have none |
| Admin email | | Shown on the website; with Let's Encrypt, its notices go to it |
| Your public IP | from your SSH connection | The IP address of the computer you run the admin from |
| DMD stratum port | 8700 | Miners connect to it; it is opened in the firewall |
| Admin portal user | `pooladmin` | nginx asks for it on `/site/AdminPortal` |
| Admin portal password | random | Keep it in your password manager |
| Database passwords | random | Keep them: nobody needs to type them |

The answers, with the passwords, are saved in `/home/crypto-data/yiimp/.yiimp.conf`, which only
the install user can read.

## After the install

1. **The DebitMyData node.** Download DebitMyData Core's Linux release from
   [GitHub](https://github.com/DebitMyData-PoW/DebitMyData-PoW-Core/releases) and check it: the
   SHA-256 that `sha256sum` prints must be the one published for that release. For a newer
   version, change `1.3.5` everywhere below:

   ```
   cd /tmp
   curl -LO https://github.com/DebitMyData-PoW/DebitMyData-PoW-Core/releases/download/v1.3.5/debitmydata-1.3.5-x86_64-linux-gnu.tar.gz
   sha256sum debitmydata-1.3.5-x86_64-linux-gnu.tar.gz
   tar -xzf debitmydata-1.3.5-x86_64-linux-gnu.tar.gz
   sudo install -m 755 debitmydata-1.3.5-x86_64-linux-gnu/debitmydatad debitmydata-1.3.5-x86_64-linux-gnu/debitmydata-cli /usr/local/bin/
   rm -rf debitmydata-1.3.5-x86_64-linux-gnu*
   ```

   Building it from [the source](https://github.com/DebitMyData-PoW/DebitMyData-PoW-Core) on the
   server works too: the installer has installed what that needs (CMake and the libraries).
   Run the node with RPC on 127.0.0.1 only, and its data in a folder under
   `/home/crypto-data/wallets`.
2. **The DMD coin**, in the admin portal (`https://pool.example.com/site/AdminPortal`): add DMD,
   algorithm sha256, with the node's RPC port, user and password. In its settings:
   - Dedicated port: the DMD stratum port (8700);
   - Charity percent: 0;
   - Has masternodes: off.

   The coin's page also shows the lines the node's config needs, `blocknotify` among them.
3. **The home page's explorer link** is `block_explorer` + `address/` + `master_wallet`, from the
   DMD coin. Its settings in the admin have the master wallet (the pool's address); the explorer,
   a DebitMyData block explorer whose address pages are `<explorer>/address/<address>`, is set
   once on the server:

   ```
   sudo mysql yiimpfrontend -e "UPDATE coins SET block_explorer='https://explorer.example.com/' WHERE symbol='DMD'"
   ```
4. **The fees** are in three places that must agree: `YAAMP_FEES_MINING` in
   `configuration/serverconfig.php` (0.5), `fee` and `solo_fee` in the `[PPLNS]` section of
   `stratum/config/dmd.sha.conf` (0.5 and 1), and `$fee_pool`, `$fee_solo` at the top of
   `web/yaamp/modules/site/index.php` (shown on the home page).
5. **Notifications** start with the server: `systemctl is-active dmd-pool-push` says `active`.
   Their keys are `configuration/push-vapid.pem` and `configuration/push.php`: back them up. A new
   key means every device turns notifications on again, so move both with the pool.

### The pool app on Google Play, later

The website installs as an app from the browser. If you also publish it on Google Play (a
Bubblewrap app), let the website know its package name, so that it does not offer the browser
version to people who have the Play app. In `/home/crypto-data/yiimp/site/web/manifest.json`, add
to `related_applications`:

```
{ "platform": "play", "id": "com.example.pool", "url": "https://play.google.com/store/apps/details?id=com.example.pool" }
```

The Play app opens without the browser's bar once the website vouches for it: save the
`assetlinks.json` file Bubblewrap describes (your package name and the SHA-256 fingerprint of the
Play app signing key, from Play Console, App integrity) as
`/home/crypto-data/yiimp/site/web/.well-known/assetlinks.json`.

### HTTPS later, with Let's Encrypt

If Let's Encrypt refused the certificate during the install (the domain did not point to the
server yet), the website runs on HTTP. Once the domain points to it:

```
bash ~/multipool/yiimp_single/https.sh
```

### Cloudflare's addresses

With Cloudflare, only Cloudflare's addresses reach ports 80 and 443 (the firewall's rules
marked `# Cloudflare`), and `/etc/nginx/conf.d/cloudflare-real-ip.conf` takes the visitor's IP
address from them only. Nobody can go around Cloudflare to the server's own address. Cloudflare
rarely changes its list (https://www.cloudflare.com/ips/); when it does, update both at once:

```
bash ~/multipool/yiimp_single/cloudflare.sh
```

It adds the new addresses before it removes the old ones, so the website is never cut off.

### Looking at the database

There is no phpMyAdmin on the server: the database holds every miner's balance, and a web page
for it would be one more door in. Reach it through SSH instead, with the key you already log in
with.

**From Windows**, [HeidiSQL](https://www.heidisql.com/) (free):

1. In HeidiSQL, **New** session. Network type: **MariaDB or MySQL (SSH tunnel)**.
   Hostname `127.0.0.1`, user `panel`, port `3306`, and the password from
   `/home/crypto-data/yiimp/.my.cnf` (`[clienthost1]`, `password=`).
2. In the **SSH tunnel** tab: the SSH program (`plink.exe`, or `ssh.exe` with an OpenSSH key),
   the server and its SSH port, your user name, your private key file, and a free local port
   such as `3307`.
3. **Open**, then the `yiimpfrontend` database.

**From macOS or Linux**, open the same tunnel with SSH, then point any MySQL client (DBeaver,
MySQL Workbench or `mysql`) at host `127.0.0.1`, port `3307`, user `panel`:

```
ssh -N -L 3307:127.0.0.1:3306 -p <SSH port> <user>@<server>
```

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

## Keeping it safe

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

## Other versions

Each repository's `master` branch is used. To try another branch or tag: `SETUP_REF=<ref>` before
`bash` in step 1, `SINGLE_REF=<ref> multipool` for the install, and `YIIMP_REF=<ref> multipool`
for the pool's code (the `main` branch of debitmydata-yiimp by default).
