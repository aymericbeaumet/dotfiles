# Getting the scripts directory
SCRIPTS_DIR=$(dir $(lastword $(MAKEFILE_LIST)))/.scripts

all:
	@echo 'Updating dotfiles...'
	@$(SCRIPTS_DIR)/update.sh
	@echo 'dotfiles successfully updated!'

install:
	@echo 'Installing dotfiles...'
	@$(SCRIPTS_DIR)/install.sh
	@echo 'dotfiles successfully installed!'

uninstall:
	@echo 'Cleaning dotfiles...'
	@$(SCRIPTS_DIR)/clean.sh
	@echo 'dotfiles successfully cleaned!'

.PHONY:	all install
