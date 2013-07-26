### What's happening here?

Are you a unconditional of _git_, _vim_, _tmux_ or _zsh_? I am one! Here you can find my configuration files for these programs.

Feel free to pick some lines here and there! In a flash of madness you can also try them, that's safe for your actual configuration files as they are automatically backed up :)

## Overview

### Zsh

![overview](http://beaumet.me/dotfiles/images/overview.png)

This prompt is splitted in two part:

- In the left part:

  * the number of process in background
  * the return code of the last command
  * the path
  * the git branch and the repository status (if in a git repository)

- In the right part:

  * the username
  * the hostname
  * the shell level (if greather than 1)

## Installation

Simply clone the project, then run `make && make install`:

    git clone https://github.com/abeaumet/dotfiles.git ~/.dotfiles
    cd ~/.dotfiles
    make && make install

Don't worry about your previous configuration files, they are automatically backed up!

## Uninstallation

Simply type `make uninstall` to get your old configuration files back.
