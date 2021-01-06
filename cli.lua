local csv = require('./lib/csv.lua')
local crm = require('./lib/crm.lua')

function splitInput( str )
  local ary = {}
  for e in string.gmatch(str, "([^%s]+)") do
    table.insert(ary, e)
  end
  return ary
end

function processStrings( ss, ln )
  local state = false
  local ix = #ss + 1
  local nl = ""
  for i = 1, #ln do
    local s = string.sub(ln, i, i)
    if s == '"' then
      state = not state
      if state then 
        ss[ix] = ""
      else
        ix = ix+1 
      end
    elseif state then
      ss[ix] = ss[ix]..s
    else
      nl = nl..s
    end
  end
  return nl
end

function dup( s ) s[#s+1] = s[#s] end
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

function printNodes( d )
  crm.forEachNode(d, 
    function(node) 
      print(node['label'])
    end
  )
end

function xS( d )
  print("Database file to save as:")
  crm.save(io.read(), d)
end

crm.slurp("data.db")
local stack = {}
local sstack= {}
local state = true
local words = 
{
  ['a'] = function() end, --adjacent
  ['s'] = function() end, --summary
  ['d'] = function() end, --diagram
  ['f'] = function() end, --find
  ['j'] = function() end, --judge
  ['k'] = function() end, --know
  ['l'] = function() end, --lineage
  [';'] = function() end, --print

  ['+t'] = function() end,
  ['+b'] = function() end,
  ['+l'] = function() end,

  ['+']    = function()  add(stack) end,
  ["drop"] = function() drop(stack) end, 
  ["dup"]  = function()  dup(stack) end, 

  ["sdrop"]= function() drop(sstack) end, 
  ["sdup"] = function()  dup(sstack) end, 

  [".s"] = function() printAry(stack) end, 
  [".ss"]= function() printAry(sstack) end, 
  ["clr"]= function() stack = {} sstack = {} end,
  ['x']  = function() state = false end, 
  ['done'] = function() state = false xS( db )  end
}

-- Main - Loop --

while state do
  local line = io.read('*l')
  line = processStrings(sstack, line)
  for ix, word in pairs(splitInput(line)) do
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
