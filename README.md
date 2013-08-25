### What's happening here?

Are you a unconditional of _git_, _vim_, _tmux_ or _zsh_? I am one! Here you can
find my configuration files for these programs (and many others).

These repository is first of all for my personal use. I use it to share my
dotfiles over all my machines. But feel free to pick some code snippets here and
there!

## Overview

### Zsh

![overview](http://beaumet.me/dotfiles/images/overview.png)

This prompt is split in two part:

- In the left part:

  * the number of process in background
  * the return code of the last command
  * the path
  * the git branch and the repository status (if in a git repository)

- In the right part:

  * the username
  * the hostname
  * the shell level (if greater than 1)

## Installation

Simply clone the project, then run `make && make install`:

    git clone https://github.com/abeaumet/dotfiles.git ~/.dotfiles
    cd ~/.dotfiles
    make && make install

Don't worry about your previous configuration files, they are automatically
backed up!

## Uninstallation

Simply type `make uninstall` to get your old configuration files back.
