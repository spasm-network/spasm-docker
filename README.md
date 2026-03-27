## Spasm forum docker/podman deployment

This is the easiest method to deploy the Spasm forum on an existing server.

### Prerequisites

Docker (with Docker Compose plugin) or Podman with the Podman Compose plugin (or legacy option `podman‑compose`). Podman is recommended for better isolation (rootless, daemonless).

### Installation

```bash
# get the deploy repo
git clone https://github.com/spasm-network/spasm-docker spasm-docker/
cd spasm-docker/

# Set ADMINS and POSTGRES_PASSWORD in .env
cp .env.example .env
nano .env

# start the app with Docker
docker compose up -d

# or use Podman with plugin
# podman compose up -d
# or legacy: podman-compose up -d
```

The app listens on port 33333 by default (you can change HOST_PORT in .env).

You can now open `http://<your-ip-address>:33333/admin` web panel, connect your extension with admin keys and customize your forum (e.g. `http://123.44.567.88:33333`).

### Make your forum public

Your forum can already federate with other instances on its own, but to let other users and instances reach you and fully unlock the power of Spasm, make the service accessible from the internet.

You can use nginx to map port 33333 to your public domain e.g. `https://forum.website.com`. See example nginx config at `doc/nginx.config.example`

If you need nginx configured automatically, execute this scripts:

```
# replaces existing nginx config (use only if this server runs just this app)
bash scripts/setup/sudo-configure-nginx.sh

# obtain a TLS cert (Certbot/Let's Encrypt).
bash scripts/setup/sudo-get-ssl.sh
```

### Update forum

```bash
cd spasm-docker/
git pull --ff-only
# or if you want to force-match remote (discars local changes):
# git fetch origin && git reset --hard origin/main

# docker
docker compose pull && docker compose up -d

# or use podman
# podman compose pull && podman compose up -d
# or legacy: podman-compose pull && podman-compose up -d
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
```





