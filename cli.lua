function splitInput( str )
  local ary = {}
  for e in string.gmatch(str, "([^%s]+)") do
    table.insert(ary, e)
  end
  return ary
end

-- Table Tests
local words = 
{
  ["a"]= function() print("Aye") end, 
  ["b"]= function() print("Bee") end, 
  ["c"]= function() print("See") end
}
local stack = {}

-- Main - Loop --

while true do
  for ix, word in pairs(splitInput(io.read('*l'))) do
    if words[word] ~= nil then
      words[word](stack)
    elseif tonumber(word) ~= nil then
      table.insert(stack, tonumber(word))
    elseif #word > 3 then
      table.insert(stack, word)
    else
      print("\t...not found.")
    end
  end
end
