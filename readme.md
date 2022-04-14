# dotfiles

Hello there! Here you can find my dotfiles for neovim, zsh, tmux, and many
other clis. I'm using those on a daily basis, and I'm putting a lot of effort
trying to keep it [simple](https://www.youtube.com/watch?v=LKtk3HCgTa8). While
I would not recommend to install this on your machine as it is tailored to my
needs, I think it is a good source of inspiration for your own dotfiles.

## Install

```bash
# Clone dotfiles
git clone --recursive git@github.com:aymericbeaumet/dotfiles.git "$HOME/.dotfiles"

# Symlink dotfiles
"$HOME/.dotfiles/symlink.sh"

# Install homebrew 
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew bundle --file "$HOME/.dotfiles/Brewfile"
```
