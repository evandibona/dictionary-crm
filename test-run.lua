misc = require("./lib/misc.lua")

-- Main - Loop --
local state = true
while state do
  io.write("\n>> ")
  io.flush()
  local line = io.read()
  local c = string.sub(line, 1, 1)
  if c == "x" then
    state = false
  elseif c == "a" then
    print("A")
  elseif c == "b" then
    io.write("B")
  elseif c == "c" then
    io.write("C")
  else
    print("\t...not found.")
  end
end
