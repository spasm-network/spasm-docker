.PHONY: help setup nginx-test nginx-reload cert cert-renew cert-install update db-backup db-restore

# Detect container runtime (prefer podman, fall back to docker)
CONTAINER_CMD := $(shell if command -v podman >/dev/null 2>&1; then echo podman; else echo docker; fi)

# Default values
PORT ?= 33333

help:
	@echo "Available targets:"
	@echo ""
	@echo "  [SUDO] make setup DOMAIN=example.com [PORT=33333]"
	@echo "         Configure nginx and obtain SSL certificate"
	@echo ""
	@echo "  [SUDO] make nginx-test"
	@echo "         Validate nginx configuration"
	@echo ""
	@echo "  [SUDO] make nginx-reload"
	@echo "         Validate and reload nginx"
	@echo ""
	@echo "  [SUDO] make cert DOMAIN=example.com"
	@echo "         Obtain new SSL certificate"
	@echo ""
	@echo "  [SUDO] make cert-renew"
	@echo "         Renew all SSL certificates"
	@echo ""
	@echo "  [SUDO] make cert-install DOMAIN=example.com"
	@echo "         Install existing SSL certificate"
	@echo ""
	@echo "  make update"
	@echo "         Pull latest code, fetch new images, restart containers"
	@echo ""
	@echo "  make db-backup"
	@echo "         Backup database to backups/ folder"
	@echo ""
	@echo "  make db-restore BACKUP=path/to/backup.sql.gz"
	@echo "         Restore database from backup (backs up current DB first)"

setup:
	@[ -n "$(DOMAIN)" ] || (echo "Error: DOMAIN required"; exit 1)
	sudo bash scripts/setup/nginx-ssl-setup $(DOMAIN) $(PORT)

nginx-test:
	sudo nginx -t

nginx-reload: nginx-test
	sudo systemctl reload nginx

cert:
	@[ -n "$(DOMAIN)" ] || (echo "Error: DOMAIN required"; exit 1)
	sudo certbot --nginx --non-interactive --agree-tos -d $(DOMAIN) --register-unsafely-without-email

cert-renew:
	sudo certbot renew --nginx

cert-install:
	@[ -n "$(DOMAIN)" ] || (echo "Error: DOMAIN required"; exit 1)
	sudo certbot install --nginx -d $(DOMAIN)

update:
	git fetch origin
	git pull --ff-only
	$(CONTAINER_CMD) compose pull --ignore-pull-failures || true
	$(CONTAINER_CMD) compose up -d --remove-orphans

db-backup:
	bash scripts/database-backup.sh

db-restore:
	@[ -n "$(BACKUP)" ] || (echo "Error: BACKUP required (e.g., make db-restore BACKUP=backups/db.sql.gz)"; exit 1)
	bash scripts/database-backup.sh
	$(CONTAINER_CMD) compose down
	bash scripts/database-restore.sh $(BACKUP)
	$(CONTAINER_CMD) compose up -d --remove-orphans
