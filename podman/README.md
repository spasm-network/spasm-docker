## Podman

Podman is more secure than Docker because it's rootless and daemonless, but we have to apply an extra hack to enable auto-restart of containers after a system reboot. If it didn't work on your system, then use Docker.

If you'll use Podman, then simply change `docker` to `podman` in all commands, e.g. `podman compose up -d`.

#### Install dependencies

```bash
# Debian/Ubuntu
sudo apt-get update -y && apt-get install -y podman docker-compose

# Fedora/RHEL
sudo dnf -y install podman docker-compose

# openSUSE
sudo zypper --non-interactive install podman docker-compose

# Arch
sudo pacman -Sy --noconfirm podman docker-compose
```

#### Enable auto-restart

```bash
sudo loginctl enable-linger "$(whoami)"

# install script and unit
install -Dm755 ./podman/auto-start.sh ~/.local/bin/podman-auto-start-spasm.sh
install -Dm644 ./podman/auto-start.service ~/.config/systemd/user/podman-auto-start-spasm.service

# if you get an error, try to log out/back in, rerun
systemctl --user daemon-reload
systemctl --user enable --now podman-auto-start-spasm.service
```

*Note: this only enables auto-restart for containers from directories that start with `spasm-docker` in home root `~/` and in `~/apps.*

#### Other

```
# view logs
tail -f ~/.local/share/podman-auto-start-spasm.log
```
