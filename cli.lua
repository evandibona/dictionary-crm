-- Split String

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
  for ix, word in 
    pairs(splitInput(io.read('*l'))) do
    if words[word] then
      words[word](stack)
    else
      print("\t...not found.")
    end
  end
end

--[[
  3 Input Types?
    Word:  
    String
    Number
--]]
