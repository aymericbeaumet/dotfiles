local utils = require("utils")

function setupSupportedEvents(h, a, default)
  h[a] =
    h[a] or
    {
      windowFocused = {},
      windowUnfocused = {}
    }
end

local module = {}

--[[
  Accept a variable number of binding objects, each object has the following shape:

  {
    whitelist = {"Safari"} | blacklist = {}, -- mutually exclusive
    {{"cmd"}, "b", safari.toggleBookmarks},
    {{"cmd", "shift"}, "r", safari.refreshWithoutCache},
    {{"cmd", "alt"}, "t", safari.closeOtherTabs}
  }
--]]
function module.registerBindings(...)
  local arguments = table.pack(...)
  local handlersByApplicationByEvents = {}

  for _, argument in ipairs(arguments) do
    if (argument.whitelist ~= nil and argument.blacklist ~= nil) then
      error("whitelist and blacklist are mutually exclusive")
    end
    for _, binding in ipairs(argument) do
      local hotkey = hs.hotkey.new(binding[1], binding[2], binding[3])
      if argument.whitelist ~= nil then
        for _, application in ipairs(argument.whitelist) do
          setupSupportedEvents(handlersByApplicationByEvents, application)
          table.insert(handlersByApplicationByEvents[application].windowFocused, utils.bind(hotkey.enable, hotkey))
          table.insert(handlersByApplicationByEvents[application].windowUnfocused, utils.bind(hotkey.disable, hotkey))
        end
      elseif argument.blacklist ~= nil then
        for _, application in ipairs(argument.blacklist) do
          setupSupportedEvents(handlersByApplicationByEvents, application)
          table.insert(handlersByApplicationByEvents[application].windowFocused, utils.bind(hotkey.disable, hotkey))
          table.insert(handlersByApplicationByEvents[application].windowUnfocused, utils.bind(hotkey.enable, hotkey))
        end
      end
      if argument.blacklist ~= nil or argument.whitelist == nil then
        hotkey:enable()
      end
    end
  end

  for application, handlersByEvent in pairs(handlersByApplicationByEvents) do
    local filter = hs.window.filter.new(application)
    for event, handlers in pairs(handlersByEvent) do
      filter:subscribe(hs.window.filter[event], handlersByEvent[event])
    end
  end
end

function module.typePasteboard()
  hs.eventtap.keyStrokes(hs.pasteboard.getContents())
end

return module
