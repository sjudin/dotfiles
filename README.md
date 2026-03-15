# My dotfiles

# Installing

First, clone this repository. Then install [stow](https://www.gnu.org/software/stow/manual/stow.html) and run
```
cd <dotfiles/repo/path> && stow -v -t "$HOME" package*
```
or if you want to individually choose the packages:
```
cd <dotfiles/repo/path> && stow -v -t "$HOME" <package1> <package2> ...
```

this will symlink all the config files.

# What to install next

Fonts:
- [JetBrains Mono Nerd Font](https://archlinux.org/packages/extra/any/ttf-jetbrains-mono-nerd/)
- [Noto](https://fonts.google.com/noto)
  - [Noto Color Emoji](https://fonts.google.com/noto/specimen/Noto+Color+Emoji)

These are the things that I use:
- [zsh](https://www.zsh.org/)
- [zinit](https://github.com/zdharma-continuum/zinit)
- [oh-my-posh](https://ohmyposh.dev/)
- [ghostty](https://ghostty.org/)
- [tmux](https://github.com/tmux/tmux/wiki)
- [sway](https://swaywm.org/)
  - [grim](https://gitlab.freedesktop.org/emersion/grim)
  - [slurp](https://github.com/emersion/slurp)
  - [waybar](https://github.com/Alexays/Waybar)
  - [hyprlock](https://wiki.hypr.land/Hypr-Ecosystem/hyprlock/)
  - [hypridle](https://wiki.hypr.land/Hypr-Ecosystem/hypridle/)
  - [chayang](https://gitlab.freedesktop.org/emersion/chayang)
  - [swaync](https://github.com/ErikReider/SwayNotificationCenter)
  - [wayland-pipewire-idle-inhibit](https://github.com/rafaelrc7/wayland-pipewire-idle-inhibit)
  - [arch-update](https://github.com/Antiz96/arch-update)
  - [fastfetch](https://github.com/fastfetch-cli/fastfetch)
  - [rofi](https://github.com/davatorium/rofi)
    - [cliphist](https://github.com/sentriz/cliphist)
- [yazi](https://yazi-rs.github.io/)
  - [imv](https://git.sr.ht/~exec64/imv/)
- [fzf](https://github.com/junegunn/fzf)
- [keychain](https://github.com/danielrobbins/keychain)
- [lightdm](https://github.com/canonical/lightdm)
  - [lightdm-gtk-greeter](https://github.com/Xubuntu/lightdm-gtk-greeter)

NOTE: There may be dependencies and other stuff not listed here, go over the config
files and setup these

# Notes/Fixes

## System suspends before screen lock fires when using SwayWM+hyprlock
When suspending the system we want to lock it first, however the suspend command
does not wait for the locker to finish before suspending since Sway does not implement
the [hyprland-lock-notify-v1 protocol](https://wayland.app/protocols/hyprland-lock-notify-v1).
We fix this by adding a small delay before suspending.

Create this file `/etc/systemd/system/user-suspend@.service`:
```ini
[Unit]
Description=Delay Suspend by 0.4s
Before=sleep.target

[Service]
User=%i
Type=oneshot
ExecStart=/usr/bin/bash -c "sleep 0.4"

[Install]
WantedBy=sleep.target
```

Enable: 
```bash
# systemctl enable --now user-suspend@<USER>.service
```
Where `<USER>` is the user who'd be running the service

[source](https://github.com/hyprwm/hypridle/issues/146#issuecomment-2961021929)

Another approach would be to disable `logind`'s handling of lid events and suspend [altogether](https://wiki.archlinux.org/title/Sway#Screen_content_shown_briefly_upon_resume)

## Fingerprint scanner not working correctly after suspend
Fingerprint scanner sometimes stops working after suspend. Making sure that `fprintd`
is disabled before suspend may help. Create a new file `/usr/lib/systemd/system-sleep/fprintd-resume.sh`:
```bash
#!/bin/sh

# This script is called by systemd when suspending (pre) and resuming (post).

case $1 in
  pre)
    # I stop fprintd before suspend to prevent it from ever hanging.
    /usr/bin/logger -t fprintd-resume-hook "Entering suspend. Stopping fprintd.service..."
    /usr/bin/systemctl stop fprintd.service
    ;;
  post)
    # On resume, I don't need to do anything. The fprintd service will be
    # auto-started by systemd's socket activation the first time
    # hyprlock needs it.
    /usr/bin/logger -t fprintd-resume-hook "Resuming from suspend. fprintd will be started on demand."
    ;;
esac
```

Make it executable:
```bash
chmod +x /usr/lib/systemd/system-sleep/fprintd-resume.sh
```

[source](https://eldon.me/intermittent-fingerprint-reader-issue/)

## Slow boot times due to networkd-wait-online
Systems with multiple ethernet interfaces or wlan+ethernet may hang on the `systemd-networkd-wait-online.service`
because one of the interfaces won´t come online. Verify this is the case by running `/usr/lib/systemd/systemd-networkd-wait-online` manually
or checking the status using `networkctl list`.

Remedy by editing the service file: 
```bash
systemctl edit systemd-networkd-wait-online.service
```
and adding the following:
```ini
[Service]
ExecStart=
ExecStart=/usr/lib/systemd/systemd-networkd-wait-online --ignore=<NAME_OF_INTERFACE_NOT_COMING_ONLINE>
```

## Screen sharing not working under wayland/sway

Add this at the bottom of your sway config, see the note in the source
```swayconfig
include /etc/sway/config.d/*
```
[source](https://wiki.archlinux.org/title/Sway#Configuration)
