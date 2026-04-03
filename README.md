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

You can verify the app is running with `curl http://127.0.0.1:33333/api/health`

### Make your forum public

#### Prerequisites

- [DNS points](./config/nginx/DNS.md) to this server's IP address
- Firewall allows ports 80 and 443

#### Automatic setup

```bash
# configure nginx and obtain free SSL with auto-renewal
bash scripts/setup/sudo-nginx-ssl your-domain.com 33333
```

#### Manual setup

- Route port 80 to 33333 to make forum accessible by IP.
- Get SSL cert and route 443 to 33333 to make forum accessible by domain.

[See detailed nginx setup instructions](./config/nginx/README.md)

### Customize forum

Open web admin panel at `http://<your-ip-address>/admin` or `https://your-domain.com/admin`, connect your extension with admin keys and customize your forum.

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

