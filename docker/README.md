## Docker

Docker is the easiest option and it will automatically auto-restart containers after a system reboot.

#### Install dependencies

```bash
# Debian/Ubuntu
sudo apt-get update -y && sudo apt-get install -y docker.io docker-compose

# Fedora/RHEL
sudo dnf -y install docker docker-compose

# openSUSE
sudo zypper --non-interactive install docker docker-compose

# Arch
sudo pacman -Sy --noconfirm docker docker-compose
```

#### Enable docker

```bash
sudo systemctl enable --now docker
sudo groupadd docker || true
sudo usermod -aG docker $(whoami)

# Apply group changes to current session
newgrp docker
```
