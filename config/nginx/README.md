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

sudo nginx -t && sudo systemctl reload nginx

# obtain certificate
sudo certbot --non-interactive --agree-tos --nginx -d $DOMAIN --register-unsafely-without-email

sudo nginx -t && sudo systemctl reload nginx
```

