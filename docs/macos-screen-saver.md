# Custom video screen saver

macOS uses Aerial 4, installed by the `aerial` cask in `Brewfile`. Enable its
native launch-at-login setting; do not add a second LaunchAgent or Flash startup
command. Aerial runs as both the desktop wallpaper and screen saver. Its
wallpaper mode is **Live wallpaper**, at normal speed (1×), with pausing when
windows cover the desktop disabled.

The native wallpaper extension also provides the video on the lock screen.
Selecting only the screen saver while keeping a static desktop does not give
the lock screen an animated background. Use Aerial's **Set as wallpaper** and
**Set as screensaver** actions so both apply across displays and Spaces. The
cold-boot login screen still uses the system wallpaper.

The Hobbiton video lives in `/Users/Shared/Aerial/My Videos/`, outside Downloads
so cleanup cannot remove the active media. This folder contains only that video.
The original is archived in Google Drive's **My Drive**; keep Aerial's playback
copy local so cloud sync and offline availability cannot interrupt playback.
The selected source is **My Videos**, with Apple's video sources disabled. A
single-entry playlist repeats the video. Media and Aerial's machine-local JSON
settings stay outside this repository.

Aerial's Video Library manages the selection. When changing its JSON settings
directly, quit Aerial first. `screensaver.json` holds the selection;
`playlists.json` can retain an older filter even after restarting. Back up and
remove that playlist file to rebuild it from the new selection. Original wallpaper
settings are backed up under `~/Library/Application Support/Hobbiton Screen Saver/`.

[Aerial documentation](https://aerialscreensaver.github.io/faq/) describes custom
video imports and screen-saver-only use.
