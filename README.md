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

These are the things that I use:
- [zsh](https://www.zsh.org/)
- [zinit](https://github.com/zdharma-continuum/zinit)
- [oh-my-posh](https://ohmyposh.dev/)
- [ghostty](https://ghostty.org/)
- [tmux](https://github.com/tmux/tmux/wiki)
- [i3](https://i3wm.org/)
  - [picom](https://github.com/yshui/picom)
  - [feh](https://github.com/derf/feh)
  - [flameshot](https://flameshot.org/)
  - [xidlehook](https://docs.rs/crate/xidlehook/0.7.1)
- [yazi](https://yazi-rs.github.io/)
- [fzf](https://github.com/junegunn/fzf)
