local utils = require("utils")

local module = {}

function module.registerBindings(...)
  for _, args in ipairs(table.pack(...)) do
      hs.hotkey.bind(args[1], args[2], args[3])
  end
end

function module.typePasteboard()
  hs.eventtap.keyStrokes(hs.pasteboard.getContents())
end

return module
