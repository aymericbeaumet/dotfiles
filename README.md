# Aymeric's dotfiles

Hey! You've reached my configuration files. Feel free to look around for some
inspiration ;)

## How can I use it?

```bash
git clone git://github.com/andsens/homeshick.git "$HOME/.homesick/repos/homeshick"
source "$HOME/.homesick/repos/homeshick/homeshick.sh"
homeshick clone git@github.com:aymericbeaumet/dotfiles
source "$HOME/.homesick/repos/dotfiles/home/.zlogin"
homeshick link dotfiles
```

## Full bootstrap

```bash
curl https://raw.githubusercontent.com/aymericbeaumet/dotfiles/master/bootstrap.sh | /bin/bash
```

## License

See [UNLICENSE](./UNLICENSE)
