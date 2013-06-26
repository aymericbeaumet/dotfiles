# Binding
###

# Useful in a term (but vim rox)
set -o emacs

bindkey '^[OH'		beginning-of-line		#HOME
bindkey '^[OF'		end-of-line			#END
bindkey '^[[6~'		history-search-forward		#PAGE DOWN
bindkey '^[[5~'		history-search-backward		#PAGE UP
bindkey '^[[2~'		overwrite-mode			#INSERT
bindkey '^[[1;5D'	backward-word			#CTRL <-
bindkey '^[[1;5C'	forward-word			#CTRL ->
bindkey '^[[3~'		delete-char			#DELETE
