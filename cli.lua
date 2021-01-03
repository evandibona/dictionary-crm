local csv = require('./lib/csv.lua')
local crm = require('./lib/crm.lua')

function splitInput( str )
  local ary = {}
  for e in string.gmatch(str, "([^%s]+)") do
    table.insert(ary, e)
  end
  return ary
end

function drop( s ) s[#s] = nil end
function drops(s ) 
  local e = s[#s] 
  s[#s] = nil
  return e
end

function add( s )
  local a = s[#s]
  local b = s[#s-1]
  drop(s)
  s[#s] = a+b
end

function printAry( s )
  if s ~= nil then
    for i, e in pairs(s) do
      print("\t"..e)
    end
  end
end

function xS( d )
  print("Database file to save as:")
  crm.save(io.read(), d)
end

-- Table Tests
local stack = {}
local db = ""
local state = true
local words = 
{
  ['db'] = function() db = crm.slurp(stack[#stack]) end, 
  ['x']  = function() state = false end, 
  ['done']  = function() state = false xS( db )  end, 
  
  ['+'] = function() add(stack) end,
  ["d"] = function() drop(stack) end, 

  [".s"]= function() printAry(stack) end, 
  ["clr"]= function() stack = {} end
}

-- Main - Loop --

while state do
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
