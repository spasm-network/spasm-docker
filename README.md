## Spasm forum docker/podman deployment

Launch [Spasm](https://spasm.network) under three minutes. The entire stack runs in isolated containers without exposing ports, while all traffic is funneled through a proxy container. It's secure, self-contained, and easy to deploy.

This repo is for deploying Spasm on existing servers. For new server setups, use [spasm-ansible](https://github.com/spasm-network/spasm-ansible) repo to automate everything from hardening to deployment with just one script.

### Prerequisites

Docker or Podman (with `docker-compose` or `podman‑compose`). Podman is recommended for better isolation (rootless, daemonless). If you gonna use podman, then simply change `docker` to `podman` in all commands, e.g. `podman compose up -d`.

### Installation

```bash
# get the deploy repo
git clone https://github.com/spasm-network/spasm-docker spasm-docker/
cd spasm-docker/

# set ADMINS and POSTGRES_PASSWORD in .env
cp .env.example .env
nano .env

# start the app
docker compose up -d
```

The app listens on port 33333 by default (you can change HOST_PORT in .env).

You can now open `http://<your-ip-address>:33333/admin` web panel, connect your extension with admin keys and customize your forum (e.g. `http://123.44.567.88:33333`).

### Make your forum public

Your forum can already federate with other instances on its own, but to let other users and instances reach you and fully unlock the power of Spasm, make the service accessible from the internet.

You can use nginx to map port 33333 to your public domain e.g. `https://forum.website.com`. See example nginx config at `docs/nginx.config.example`

If you need nginx configured automatically, execute these scripts:

```bash
# adds config to /etc/nginx/sites-available/<your-domain-name>
bash scripts/setup/sudo-configure-nginx.sh

# get free TLS cert with auto-renewal via certbot (Let's Encrypt)
bash scripts/setup/sudo-get-ssl.sh
```

### Update forum

```bash
cd spasm-docker/
git pull --ff-only
# or if you want to force-match remote (discards local changes):
# git fetch origin && git reset --hard origin/master

docker compose pull && docker compose up -d
```

## Scripts

### Database scripts

```bash
# Backup database (saves .gz into backups/ folder)
bash scripts/database-backup.sh

# Restore database (supports .sql and .gz)
bash scripts/database-restore.sh path/to/db/backup.sql.gz

# example:
bash scripts/database-restore.sh backups/spasm-docker_spasm_database_20260101-33333.sql.gz

# Note: you should manually restart containers after database was restored
docker compose stop && docker compose up -d
```





