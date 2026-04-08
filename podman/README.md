## Podman

### Automatic setup
```bash
# install podman and configure auto-start after reboot
sudo bash run install-podman
```

### Manual setup

```bash
sudo loginctl enable-linger user

# install script and unit
install -Dm755 ./podman/auto-start.sh ~/.local/bin/podman-auto-start.sh
install -Dm644 ./podman/auto-start.service ~/.config/systemd/user/podman-auto-start.service

systemctl --user daemon-reload
systemctl --user enable --now podman-auto-start.service
```

#### Other

```
# view logs
tail -f ~/.local/share/podman-auto-start.log
```
