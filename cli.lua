function splitInput( str )
  local ary = {}
  for e in string.gmatch(str, "([^%s]+)") do
    table.insert(ary, e)
  end
  return ary
end

function printAry( s )
  if s ~= nil then
    for i, e in pairs(s) do
      print("\t"..e)
    end
  end
end

-- Table Tests
local stack = {}
local words = 
{
  ["a"]= function() print("Aye") end, 
  ["b"]= function() print("Bee") end, 
  ["c"]= function() print("See") end,

  [".s"]= function() printAry(stack) end, 
  ["clr"]= function() stack = {} end
}

-- Main - Loop --

while true do
  for ix, word in pairs(splitInput(io.read('*l'))) do
    if words[word] ~= nil then
      words[word](stack)
    elseif tonumber(word) ~= nil then
      table.insert(stack, tonumber(word))
    elseif #word >= 3 then
      table.insert(stack, word)
    else
      print("\t...not found.")
    end
  end
end
