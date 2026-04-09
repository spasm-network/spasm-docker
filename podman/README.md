## Podman

Podman is more secure than Docker because it's rootless and daemonless, but we have to apply an extra hack to enable auto-restart of containers after a system reboot. If it didn't work on your system, then use Docker.

If you'll use Podman, then simply change `docker` to `podman` in all commands, e.g. `podman compose up -d`.

#### Install dependencies

```bash
# Debian/Ubuntu
sudo apt-get update -y && sudo apt-get install -y podman docker-compose

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

systemctl --user daemon-reload
systemctl --user enable --now podman-auto-start-spasm.service
```

*Note: this setup only enables auto-restart for containers from directories that start with `spasm-docker` in home root `~/` and in `~/apps.*

#### Troubleshooting

If `systemctl --user` fails with scope bus errors, then your systemd session isn't active. Verify with:

```bash
loginctl show-user $(whoami) | grep State=active
```

Solution: run all commands while logged in directly as the target user (not via `su`). If your user doesn't have `sudo`, then enable lingering for your user from admin, then run the install/systemctl commands as a user.

```bash
# As admin (with sudo), enable lingering for 'user'
sudo loginctl enable-linger user

# As 'user'
install -Dm755 ./podman/auto-start.sh ~/.local/bin/podman-auto-start-spasm.sh
install -Dm644 ./podman/auto-start.service ~/.config/systemd/user/podman-auto-start-spasm.service
systemctl --user daemon-reload
systemctl --user enable --now podman-auto-start-spasm.service
```

Install the app and verify that containers restart after reboot.

```bash
podman ps
su - admin
sudo reboot now
# ssh back into user
podman ps
# you should see a list or running containers
```

Alternativelly, use Docker since it's much easier to set up because it runs as a root.

#### Other

```
# view logs
tail -f ~/.local/share/podman-auto-start-spasm.log
```

