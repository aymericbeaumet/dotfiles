#!/usr/bin/env bash
# Launch newsboat with Ctrl+Y reaching its keymap.
#
# macOS claims Ctrl+Y as the tty delayed-suspend character (dsusp), and the
# curses layer newsboat renders through leaves IEXTEN enabled, so the driver
# swallows ^Y before the application ever sees it. Ctrl+D and Ctrl+U are only
# special in canonical mode, which curses turns off, so they arrive untouched;
# ^Y is the one vim scroll binding that needs this.
#
# Both entry points run through here: the `newsboat` alias in .zshrc and the
# Flash status-bar feed popup.
set -euo pipefail

stty dsusp undef 2>/dev/null || true
exec newsboat "$@"
