## Spasm forum docker/podman deployment

Mirrors: [Forgejo](https://git.spasm.network/spasm-network/spasm-docker) [Codeberg](https://codeberg.org/spasm-network/spasm-docker) [Github](https://github.com/spasm-network/spasm-docker)

Launch [Spasm](https://spasm.network) under three minutes.

The entire stack runs in isolated containers without exposing ports, routing traffic through a proxy container. Frontend and db stay on an internal network, backend uses external ones for federation. It's secure, self-contained, and easy to deploy. You can also [verify](gpg/README.md) GPG signatures of all git commits.

This repo is for deploying Spasm on existing servers along with other software. For new server, dedicated for Spasm, use [spasm-ansible](https://github.com/spasm-network/spasm-ansible) repo to automate everything from system hardening to deployment with just one script.

### Prerequisites

[Docker](docker/README.md) or [Podman](podman/README.md). Docker is easy, Podman is more secure, but requires extra setup to auto-restart.

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

The app listens on port 33333 by default (you can change HOST_PORT in spasm-docker/.env file).

You can verify the app is running with `curl http://127.0.0.1:33333/api/health`

### Make your forum public

Prerequisites: [DNS points](./config/nginx/DNS.md) to the server IP and firewall allows ports 80 and 443.

#### Automatic setup

```bash
# configure nginx, obtain SSL cert, add auto-renewal
sudo bash run setup your-domain.com 33333
```

#### Manual setup

- Route port 80 to 33333 to make forum accessible by IP.
- Get SSL cert and route 443 to 33333 to make forum accessible by domain.

[See detailed nginx setup instructions](./config/nginx/README.md)

### Customize forum

Open web admin panel at `http://<your-ip-address>/admin` or `https://your-domain.com/admin`, connect your extension with admin keys and customize your forum.

### Update forum

*Note: the `run` script automatically detects whether Docker or Podman is installed and uses it.*

```bash
# automatic: pull code, fetch images, restart containers
bash run update

# or manual:
git pull --ff-only
docker compose pull && docker compose up -d --force-recreate
```

#### Database management

```bash
# backup database (saves .gz into backups/ folder)
bash run db-backup

# restore database (supports .sql and .gz, restarts containers)
bash run db-restore backups/spasm-docker_spasm_database_20260101.sql.gz
```

