local module = {}

-- https://stackoverflow.com/a/43513332/1071486
function module.bind(fn, ...)
  local args1 = table.pack(...)
  return function(...)
    local args2 = table.pack(...)

    for i = 1, args2.n do
      args1[args1.n + i] = args2[i]
    end
    args1.n = args1.n + args2.n

    fn(table.unpack(args1, 1, args1.n))
  end
end

function module.noop()
end

return module
