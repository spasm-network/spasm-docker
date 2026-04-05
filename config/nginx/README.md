## Install dependencies

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

## Configure nginx and obtain SSL certificate

```bash
# Set your domain name and port for this shell only
DOMAIN=example.com PORT=33333

# Configure nginx
sudo cp ./nginx.template /etc/nginx/sites-available/$DOMAIN
sudo sed -i "s|example\.com|${DOMAIN}|g; s|:33333|:${PORT}|g" /etc/nginx/sites-available/$DOMAIN
sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN

# (optional) skip this if you already have websocket config
sudo cp -n ./websocket.conf /etc/nginx/conf.d/websocket.conf

# Create bootstrap self-signed certificate so nginx -t passes before Certbot runs
CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
sudo mkdir -p "$CERT_DIR"
sudo openssl req -x509 -newkey rsa:2048 -keyout "$CERT_DIR/privkey.pem" \
  -out "$CERT_DIR/fullchain.pem" -days 1 -nodes -subj "/CN=$DOMAIN" 2>/dev/null

# Validate and reload with bootstrap cert
sudo nginx -t && sudo systemctl reload nginx

# Obtain certificate (replaces bootstrap cert)
sudo certbot --nginx --non-interactive --agree-tos -d $DOMAIN \
  --register-unsafely-without-email --reinstall

# Validate and reload with real certificate
sudo nginx -t && sudo systemctl reload nginx
```

*Note: `certbot --nginx` messes up a template if we only set http block, so we're keeping both http and https blocks and self-sign temporary cert to pass `nginx -t` before obtaining certificate.*
