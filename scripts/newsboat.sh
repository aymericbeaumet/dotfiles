#!/usr/bin/env bash
# Launch newsboat with Ctrl+Y and Ctrl+O reaching its keymap.
#
# macOS claims Ctrl+Y as the tty delayed-suspend character (dsusp) and Ctrl+O
# as discard. The curses layer newsboat renders through leaves IEXTEN enabled,
# so the driver swallows both before the application ever sees them. Ctrl+D
# and Ctrl+U are only special in canonical mode, which curses turns off.
#
# Both entry points run through here: the `newsboat` alias in .zshrc and the
# Flash status-bar feed popup. They share one config, including the cursor.
set -euo pipefail

stty dsusp undef 2>/dev/null || true
stty discard undef 2>/dev/null || true
exec newsboat "$@"
