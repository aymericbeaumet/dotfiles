# dotfiles

Hello there! Here you can find my dotfiles for neovim, zsh, tmux, and many other
CLIs. I'm using those on a daily basis, and I'm putting a lot of effort trying
to keep them [simple](https://www.youtube.com/watch?v=LKtk3HCgTa8).

_While I would not recommend to install this on your machine as it is tailored
to my needs, I believe it is a good source of inspiration for your own
dotfiles._

## Setup

```bash
# Clone dotfiles
git clone --recursive https://github.com/aymericbeaumet/dotfiles.git "$HOME/.dotfiles" # read-only
git clone --recursive git@github.com:aymericbeaumet/dotfiles.git "$HOME/.dotfiles"     # read-write

# Setup system
"$HOME/.dotfiles/setup.sh"
```
