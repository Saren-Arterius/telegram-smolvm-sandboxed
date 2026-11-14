# Telegram Desktop in a smolvm microVM

Same idea as `telegram-podman-sandboxed`, but Telegram gets its own kernel (KVM via
[smolvm](https://github.com/smol-machines/smolvm)) instead of sharing the host's. No root
daemon and no iptables: `--block-private` drops LAN, host loopback, CGNAT and metadata.

## Setup

```
sudo pacman -S smolvm waypipe        # Docker is only used to build the image
curl -fLO https://github.com/telegramdesktop/tdesktop/releases/download/v7.4.3/td-setup-linux-x64-7.4.3.tar.xz
sed "s|@DIR@|$PWD|g" telegram-smolvm.desktop > ~/.local/share/applications/org.telegram.desktop._3e485da34fc040f9218e3891ecde1e6c.desktop
./run.sh
```

The first start imports the image (about a minute); after that it boots in under a second.

## What Telegram can reach

- `home/` (its `$HOME`), `bin/` (Telegram binary, self-updating), `share/`.
- Your downloads folder read-only; `Telegram Desktop/` inside it writable. It's also linked
  at its host path, so drag and drop works from there only.
- The internet, minus private ranges.
- Your compositor, through waypipe (clipboard included).

Inside the VM, Telegram runs as your uid so the mounted files stay yours. The VM is the
boundary; the uid only matters inside it.

## Notes

- Wayland only. Raw Wayland can't cross a VM (it passes fds), so waypipe serialises it over
  one socket mounted with `--mount-socket`.
- No GPU; Qt draws in software (llvmpipe). Don't add `--gpu` on NVIDIA: smolvm's GPU is
  Vulkan only (virtio-gpu/Venus). With Telegram's experimental `enable-vulkan-rhi` it does
  render on the card, but on an RTX 4090 with the proprietary driver it raised Xid 31/13
  faults in gnome-shell's GPU context and took the desktop down (gdm restart needed). GL
  doesn't work either: Zink rejects Venus (`failed to choose pdev`, no
  `VK_EXT_physical_device_drm`), and virgl fails to initialise.
- smolvm 1.34 crashes on non-ASCII guest mount paths, hence the symlink trick in `run.sh`.
- Rebuild the runtime image: `rm image.tar && ./run.sh`.
