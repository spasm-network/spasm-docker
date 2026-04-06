## Configure nginx and ssl

Running a setup script is the easiest option. If you don't understand bash, then simply show the script and templates to your LLM to confirm that it's safe to use them. Alternatively, you can go with a manual setup.

*Note: all commands should be executed from the project root.*

Prereqs: [DNS points](DNS.md) to this server IP; firewall allows ports 80 and 443.

### Automatic setup

```bash
# configure nginx, obtain SSL cert, add auto-renewal
sudo bash run setup your-domain.com 33333
```

### Manual setup

- Route port 80 to 33333 to make forum accessible by IP.
- Get SSL cert and route 443 to 33333 to make forum accessible by domain.

*Note: if you don't know how to do that, then follow the instructions below.*

#### Install dependencies

```bash
# Debian/Ubuntu
sudo apt update && sudo apt install -y nginx certbot python3-certbot-nginx

# Fedora/RHEL
sudo dnf install -y nginx certbot python3-certbot-nginx

# openSUSE
sudo zypper install -y nginx certbot python3-certbot-nginx

# Arch
sudo pacman -Sy && sudo pacman -S --noconfirm nginx certbot certbot-nginx
```

#### Configure nginx and obtain SSL certificate

```bash
# Set domain and port for this shell
DOMAIN=example.com PORT=33333

# Clean up any stale certificate data
sudo rm -rf /etc/letsencrypt/live/$DOMAIN
sudo rm -rf /etc/letsencrypt/archive/$DOMAIN
sudo rm -f /etc/letsencrypt/renewal/$DOMAIN.conf

# Install temporary HTTP-only nginx config (for ACME validation)
sudo cp ./config/nginx/nginx.http.template /etc/nginx/sites-available/$DOMAIN
sudo sed -i "s|example\.com|${DOMAIN}|g; s|:33333|:${PORT}|g" /etc/nginx/sites-available/$DOMAIN
sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN

# (optional) copy websocket config if missing
sudo cp -n ./config/nginx/websocket.conf /etc/nginx/conf.d/websocket.conf

# Validate and reload nginx
sudo nginx -t && sudo systemctl reload nginx

# Obtain certificate without changing nginx config (certonly)
sudo certbot certonly --nginx -d "$DOMAIN" --cert-name "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email

# Install canonical HTTP+HTTPS nginx template (now that cert exists)
sudo cp ./config/nginx/nginx.template /etc/nginx/sites-available/$DOMAIN
sudo sed -i "s|example\.com|${DOMAIN}|g; s|:33333|:${PORT}|g" /etc/nginx/sites-available/$DOMAIN
sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN
sudo nginx -t && sudo systemctl reload nginx

# Configure certbot to manage nginx (adds renewal automation like auto-restart)
sudo certbot --nginx --cert-name "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email
sudo nginx -t && sudo systemctl reload nginx

# (optional) check issued cert and renewal
sudo certbot certificates --cert-name "$DOMAIN"
sudo systemctl is-enabled --quiet certbot.timer && echo "enabled" || echo "NOT enabled"
```

#### Why call certbot twice?

Certbot's `--nginx` plugin often messes up full HTTP+HTTPS templates, while `--webroot` doesn't automate renewals, so our approach fixes this:

1. Issue cert using a simple HTTP-only template
2. Install a full HTTP+HTTPS template
3. `certbot --nginx` annotates the config for renewal automation

This preserves nginx structure while enabling automatic cert renewal.
