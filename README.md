# Aymeric's dotfiles

Only tested on OSX.

## Requirements

```bash
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install git
```

## Installation

```bash
git clone git://github.com/andsens/homeshick.git "$HOME/.homesick/repos/homeshick"
source "$HOME/.homesick/repos/homeshick/homeshick.sh"
homeshick clone https://github.com/aymericbeaumet/dotfiles.git
homeshick link dotfiles
```

## License

See [UNLICENSE](./UNLICENSE)
