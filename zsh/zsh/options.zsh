# Options
###

setopt AUTO_CD			            # change directory without cd
setopt ALIASES			            # expand aliases
setopt SHORT_LOOPS		          # allow short forms (if, for, functions...)
setopt AUTO_CONTINUE		        # background process stay alive on shell exit
setopt RC_EXPAND_PARAM          # expand on all the param array
setopt NUMERIC_GLOB_SORT
unsetopt CORRECT_ALL		        # don't auto-correct
unsetopt EXTENDED_GLOB          # avoid bad completions
unsetopt LIST_AMBIGUOUS
unsetopt RM_STAR_WAIT           # don't wait after `rm *`

# Automatic URL escaping
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

# No beep
unsetopt BEEP			# no beep
unsetopt HIST_BEEP		# no beep
unsetopt LIST_BEEP		# no beep
