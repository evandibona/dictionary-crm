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

function find( s )
  s[#s] = crm.find(s[#s]) 
end

function addTrunk( s )
  crm.addT( drops(s) )
end

function addBranch( s )
  swap( s )
  crm.addL( crm.addr( drops(s) ), drops(s) )
end

function addLeaf( s, ss )
  crm.addL( crm.addr( drops(s) ), drops(ss) )
end


function dup ( s ) s[#s+1] = s[#s] end
function drop( s ) s[#s] = nil end
function drops(s ) 
  local e = s[#s] 
  s[#s] = nil
  if not e then print("Stack Empty, prepare for crash!") end
  return e
end
function swap( s ) 
  local e = s[#s]
    s[#s] = s[#s-1]
  s[#s-1] = e
end

function add( s )
  local a = s[#s]
  local b = s[#s-1]
  drop(s)
  s[#s] = a+b
end

function one( s, f )
  if #s > 0 then 
    f( drops(s) ) 
  else
    print("  stack is empty, preventing crash.")
  end
end

function printAry( s )
  if s ~= nil then
    for i, e in pairs(s) do
      print("\t"..e)
    end
  end
end

function printWords(a) 
  local s = "\t\t"
  for i, v in pairs(a) do
    s = s..i..'\t'
    if #s > 16 then print(s) s = "\t\t" end
  end
  print(s)
end

crm.open("data.db")
local backup= crm.db
local stack = {}
local sstack= {}
local state = true
local words = 
{
  ['a'] = function() one( stack, crm.adjacent  ) end, 
  ['s'] = function() one( stack, crm.summarize ) end, 
  ['d'] = function() one( stack, crm.diagram   ) end, 
  ['f'] = function() find( stack ) end, 
  ['j'] = function() one( stack, crm.judge     ) end, 
  ['k'] = function() one( stack, crm.know      ) end, 
  ['l'] = function() one( stack, crm.lineage   ) end, 
  [';'] = function() one( stack, crm.print     ) end, 

  ['t'] = function() crm.printEntries( crm.trunks() ) end, 

  ['+t'] = function() addTrunk  ( stack ) end, 
  ['+b'] = function() addBranch ( stack ) end, 
  ['+l'] = function() addLeaf   ( stack, sstack ) end, 

  ['+']    = function()  add(stack) end,
  ["drop"] = function() drop(stack) end, 
  ["dup"]  = function()  dup(stack) end, 
  ["swap"] = function() swap(stack) end, 

  ["sdrop"]= function() drop(sstack) end, 
  ["sdup"] = function()  dup(sstack) end, 

  [".s"] = function() printAry(stack) end, 
  [".ss"]= function() printAry(sstack) end, 
  ["clr"]= function() stack = {} sstack = {} end,
  ['x']  = function() state = false end, 
  ['done'] = function() state = false xS( db )  end, 
  ['cancel'] = function() crm.db = backup crm.save('data.db') end
}

-- Main - Loop --
while state do
  local line = io.read('*l')
  line = processStrings(sstack, line)
  for ix, word in pairs(splitInput(line)) do

    if word == 'words' then printWords(words)
    elseif words[word] ~= nil then
      words[word](stack)
    elseif tonumber(word) ~= nil then
      table.insert(stack, tonumber(word))
    elseif #word >= 3 then
      table.insert(stack, word)
    else
      print("\t...not found.")
    end
  end
  crm.save("data.db")
end
