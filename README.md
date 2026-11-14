# Telegram Desktop in a smolvm microVM

## What this is

This project runs Telegram Desktop in a small virtual machine (VM).

In November 2026, Telegram had a security bug: a message could run bad code on the device.
Telegram repaired this bug. But a new bug of this type can occur in the future.
If it occurs, the VM stops the bad code from getting to your files, your network, and your account.

The VM has its own Linux kernel. If bad code breaks the kernel in the VM,
the kernel of your computer is still safe.

The VM gives Telegram these limits:

- Telegram cannot see your home folder. It can see only the folders in "What Telegram can see".
- Telegram cannot connect to your home network, your router, or your computer.
- Telegram can connect to the internet.

You do not need root access to run the VM.

## Two versions of this project

There are two versions. Select the version that is applicable to you.

| | [Podman version](https://github.com/Saren-Arterius/telegram-podman-sandboxed) | [smolvm version](https://github.com/Saren-Arterius/telegram-smolvm-sandboxed) |
|---|---|---|
| Type | Container | Virtual machine (VM) |
| Linux kernel | Shared with your computer | Its own kernel. Safer if bad code breaks the kernel. |
| NVIDIA GPU | Yes (optional) | No. Telegram draws the screen with the CPU. |
| Desktop | Wayland or X11 | Wayland only |
| Files that Telegram saves | Belong to a different user | Belong to your user |
| Tools | Podman. These tools are mature. | smolvm. This tool is new and has some bugs. |
| Packages | `podman`, `passt` | `smolvm`, `waypipe`, Docker (to build the image) |

## Before you start

You must have these items:

1. Linux with a Wayland desktop. This project does not operate with X11.
2. Access to `/dev/kvm`.
3. The `smolvm` and `waypipe` packages.
4. Docker. The project uses Docker only to build the VM image.

On Arch Linux, type this command to install the packages:

```
sudo pacman -S smolvm waypipe
```

## Install

Do these steps in the project folder.

1. Download Telegram:

   ```
   curl -fLO https://github.com/telegramdesktop/tdesktop/releases/download/v7.4.3/td-setup-linux-x64-7.4.3.tar.xz
   ```

2. Add Telegram to your app menu:

   ```
   sed "s|@DIR@|$PWD|g" telegram-smolvm.desktop > ~/.local/share/applications/org.telegram.desktop._3e485da34fc040f9218e3891ecde1e6c.desktop
   ```

3. Start Telegram:

   ```
   ./run.sh
   ```

The first start builds and loads the VM image. This takes some minutes.
After the first start, the VM starts in less than one second.

## Start and stop Telegram

To start Telegram, click "Telegram (smolvm)" in your app menu. You can also type `./run.sh`.

To stop Telegram, close Telegram. The VM stops when Telegram stops.

## What Telegram can see

Telegram can see only these items:

| Item | Telegram can read | Telegram can change |
|---|---|---|
| Your downloads folder | Yes | No |
| The `Telegram Desktop` folder in your downloads folder | Yes | Yes |
| The `home` folder in this project (Telegram login and settings) | Yes | Yes |
| The `bin` folder in this project (the Telegram program) | Yes | Yes |
| The `share` folder in this project | Yes | Yes |
| The internet | Yes | Yes |
| Your desktop, through `waypipe` (windows and clipboard) | Yes | Yes |

Telegram cannot connect to:

- Your home network and your router.
- Your computer.
- Private network addresses, for example `192.168.x.x` and `10.x.x.x`.

Files that Telegram saves belong to your user. You can change them.

To drag a file into Telegram, put the file in your downloads folder first.

## The GPU

The VM does not use the GPU. Telegram draws the screen with the CPU.
This is satisfactory for most persons.

WARNING: Do not add `--gpu` to `run.sh` on a computer with an NVIDIA GPU.
In a test on an NVIDIA RTX 4090, the GPU caused the desktop to stop.
The user had to restart the login manager (gdm).

## Problems and solutions

**You changed the `Dockerfile`, and the change does not apply.**
Delete the old image. Then start Telegram again:

```
rm image.tar && ./run.sh
```

**Your downloads folder has a name with special letters, for example `下載`.**
This is satisfactory. smolvm 1.34 stops if a folder name in the VM has letters that are not ASCII.
`run.sh` gives the folder an ASCII name in the VM. Then it adds a link with your folder name.

## Telegram updates

Telegram updates itself in the `bin` folder.
The updater checks the download only with TLS. It does not check a signature.

## Technical notes

These notes are for persons who change the project.

- Wayland cannot go directly out of a VM. `waypipe` sends the Wayland data through one socket.
  `run.sh` gives this socket to the VM with `--mount-socket`.
- `--block-private` blocks private networks, the computer, CGNAT addresses, and cloud metadata.
- In the VM, `run.sh` starts as root for some setup steps. Then Telegram runs as your user,
  with no new permissions.
- smolvm cannot put one shared folder in another shared folder. `run.sh` does this with `mount --bind` in the VM.
- GPU test results: smolvm gives only a Vulkan GPU (Venus). Telegram with `enable-vulkan-rhi`
  caused Xid 31 and Xid 13 errors in gnome-shell. OpenGL does not operate: Zink cannot select
  the Venus device, and virgl does not start.

## Remove

Delete the project folder. This also deletes your Telegram login and settings.
Then delete the app menu entry:

```
rm ~/.local/share/applications/org.telegram.desktop._3e485da34fc040f9218e3891ecde1e6c.desktop
```
