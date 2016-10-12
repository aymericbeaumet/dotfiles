-- bindings

function activateOrLaunch(name)
  return function()
    hs.application.launchOrFocus(name)
  end
end

function moveFocusedWindow(x, y, w, h) -- https://gist.github.com/swo/91ec23d09a3d6da5b684
  return function()
    local win = hs.window.focusedWindow()
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()
    f.x = max.w * x
    f.y = max.h * y
    f.w = max.w * w
    f.h = max.h * h
    win:setFrame(f, 0)
  end
end

hs.hotkey.bind({'cmd', 'alt'}, 'left',  moveFocusedWindow(0, 0, 0.5, 1))
hs.hotkey.bind({'cmd', 'alt'}, 'right', moveFocusedWindow(0.5, 0, 0.5, 1))
hs.hotkey.bind({'cmd', 'alt'}, 'up',    moveFocusedWindow(0, 0, 1, 0.5))
hs.hotkey.bind({'cmd', 'alt'}, 'down',  moveFocusedWindow(0, 0.5, 1, 0.5))
hs.hotkey.bind({'cmd', 'alt'}, 'c',     moveFocusedWindow(0.15, 0.15, 0.70, 0.70))
hs.hotkey.bind({'cmd', 'alt'}, 'e',     activateOrLaunch('Evernote'))
hs.hotkey.bind({'cmd', 'alt'}, 'f',     moveFocusedWindow(0, 0, 1, 1))
hs.hotkey.bind({'cmd', 'alt'}, 'g',     activateOrLaunch('Google Chrome'))
hs.hotkey.bind({'cmd', 'alt'}, 'i',     activateOrLaunch('iTerm'))
hs.hotkey.bind({'cmd', 'alt'}, 'r',     function() hs.reload() end)
hs.hotkey.bind({'cmd', 'alt'}, 's',     activateOrLaunch('Slack'))
hs.hotkey.bind({'cmd', 'alt'}, 't',     activateOrLaunch('Tweetbot'))
hs.hotkey.bind({'cmd', 'alt'}, 'v',     function() hs.eventtap.keyStrokes(hs.pasteboard.getContents()) end)

-- unix bindings

local unix = {
  { {{'ctrl'}, '['}, --[[ => --]] {{}, 'escape'}             },
  { {{'ctrl'}, 'a'}, --[[ => --]] {{'cmd'}, 'left'}          },
  { {{'ctrl'}, 'b'}, --[[ => --]] {{}, 'left'}               },
  { {{'ctrl'}, 'd'}, --[[ => --]] {{}, 'forwarddelete'}      },
  { {{'ctrl'}, 'e'}, --[[ => --]] {{'cmd'}, 'right'}         },
  { {{'ctrl'}, 'f'}, --[[ => --]] {{}, 'right'}              },
  { {{'ctrl'}, 'h'}, --[[ => --]] {{}, 'delete'}             },
  { {{'ctrl'}, 'i'}, --[[ => --]] {{}, 'tab'}                },
  -- { {{'ctrl'}, 'k'}, [> => --<] {{'cmd'}, 'forwarddelete'} },
  { {{'ctrl'}, 'm'}, --[[ => --]] {{}, 'padenter'}           },
  { {{'ctrl'}, 'n'}, --[[ => --]] {{}, 'down'}               },
  { {{'ctrl'}, 'p'}, --[[ => --]] {{}, 'up'}                 },
  { {{'ctrl'}, 'u'}, --[[ => --]] {{'cmd'}, 'delete'}        },
  { {{'ctrl'}, 'w'}, --[[ => --]] {{'alt'}, 'delete'}        },
  { {{'alt'},  'b'}, --[[ => --]] {{'alt'}, 'left'}          },
  { {{'alt'},  'd'}, --[[ => --]] {{'alt'}, 'forwarddelete'} },
  { {{'alt'},  'f'}, --[[ => --]] {{'alt'}, 'right'}         },
}

local nobindings = {
 'iterm',
 'macvim',
 'neovim',
}

function enableBindings()
  for _, binding in pairs(unix) do
    hs.hotkey.bind(binding[1][1], binding[1][2], function()
      hs.eventtap.keyStroke(binding[2][1], binding[2][2])
    end)
  end
end

function disableBindings()
  for _, binding in pairs(unix) do
    hs.hotkey.deleteAll(binding[1][1], binding[1][2])
  end
end

hs.application.watcher.new(function(name, event, application)
  if event ~= hs.application.watcher.activated then
    return
  end
  for _, app in pairs(nobindings) do
    if name:lower() == app then
      disableBindings()
      return
    end
  end
  enableBindings()
end):start()

-- wifi

hs.wifi.watcher.new(function()
  local network = hs.wifi.currentNetwork()
  if network ~= nil then
    hs.alert.show('Wi-Fi connected: ' .. network .. ' ✔')
  else
    hs.alert.show('Wi-Fi disconnected ✘')
  end
end):start()

-- done

hs.alert.show('Hammerspoon loaded ✔')
