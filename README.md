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
- [JetBrains Mono](https://www.jetbrains.com/lp/mono/)
- [Symbols Nerd Font](https://www.nerdfonts.com/)
- [Noto](https://fonts.google.com/noto)

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
  - [arch-update](https://github.com/Antiz96/arch-update)
  - [fastfetch](https://github.com/fastfetch-cli/fastfetch)
- [yazi](https://yazi-rs.github.io/)
  - [imv](https://git.sr.ht/~exec64/imv/)
- [fzf](https://github.com/junegunn/fzf)
- [keychain](https://github.com/danielrobbins/keychain)
- [lightdm](https://github.com/canonical/lightdm)
  - [lightdm-gtk-greeter](https://github.com/Xubuntu/lightdm-gtk-greeter)

NOTE: There may be dependencies and other stuff not listed here, go over the config
files and setup these
