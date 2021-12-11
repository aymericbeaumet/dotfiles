# dotfiles

[![travis](https://img.shields.io/travis/aymericbeaumet/dotfiles?style=flat-square&logo=travis)](https://travis-ci.org/aymericbeaumet/dotfiles)
[![github](https://img.shields.io/github/issues/aymericbeaumet/dotfiles?style=flat-square&logo=github)](https://github.com/aymericbeaumet/dotfiles/issues)

Hello fellow dotfiler, here you can find configuration for git, neovim, tmux,
zsh, and many more other programs.

I have been gathering, updating, carefully nitpicking my dotfiles for nearly
10 years.

Feel free to copy, fork, PR, improve, suggest. I am always looking to make
this work evolve toward a more convenient workflow.

## Install

### read-only (https)

```bash
git clone --recursive https://github.com/aymericbeaumet/dotfiles.git "$HOME/.config/dotfiles"
"$HOME/.config/dotfiles/make" bootstrap symlink
```

### read-write (git+ssh)

```bash
git clone --recursive git@github.com:aymericbeaumet/dotfiles.git "$HOME/.config/dotfiles"
"$HOME/.config/dotfiles/make" bootstrap symlink
```

## Usage

### `./make bootstrap`

Update the submodules, install all the dependencies, prune the
unneeded dependencies.

It also takes care to install the latest Node.js and Yarn versions.

### `./make symlink`

Symlink all the configuration files from the
[`./src`](https://github.com/aymericbeaumet/dotfiles/tree/master/src)
directory to `$HOME`.

## FAQ

> Why do you need both `src` and `shallow` directories?

The way it works, `./make symlink` will _recursively_ create symlinks for all
the files in `src` folder, individually. Some directories need to be
symlinked as a whole (e.g., `~/.config/karabiner`). The trick is then to
leverage a separate directory (`shallow`) and to create a link pointing from
`src` to `shallow`. That way when `./make symlink` browses through the
files in `src`, it only creates the symlink `$HOME/.config/karabiner`,
pointing to `dotfiles/src/.config/karabiner`.
