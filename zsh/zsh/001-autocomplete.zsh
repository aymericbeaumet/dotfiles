# Autocomplete
###

autoload -U compinit
compinit

zstyle ':completion:*' menu select
zstyle ':completion:*:*:vim:*:*files' ignored-patterns '*.o'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=36=31'
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion:*' verbose yes
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:default' menu 'select=0'
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*:corrections' format '%B%d (errors %e)%b'
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

setopt COMPLETE_ALIASES		# autocomplete on aliases
setopt COMPLETE_IN_WORD
