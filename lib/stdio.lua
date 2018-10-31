require("love.event")
local event, channel = ...
do
  local function _0_()
    io.write("> ")
    io.flush()
    return io.read("*l")
  end
  local prompt = _0_
  local function looper(input)
    if input then
      love.event.push(event, input)
      print(channel:demand())
      return looper(prompt())
    end
  end
  return looper(prompt())
end
