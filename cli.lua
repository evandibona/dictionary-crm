#!/usr/bin/lua5.3

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

function help()
  print()
    io.write("   +t  ( s -- ) +Trunk    ")
    io.write("+t  ( n s -- ) +Branch\t")
    io.write("+t  ( n s -- ) +Leaf\t")

  print('\n')
    io.write("  s  ( n -- )  Summarize\t\t")
       print("  d  ( n -- )  Diagram\t\t")
    io.write("  i  ( n -- )  Info\t\t")
       print("  f  ( n -- )  Find\t\t")
    io.write("  ;  ( n -- )  Print\t\t")
       print("  @  ( n s -- )  Attribute of Tree\t\t")
    io.write("  t  ( -- )  Print Trunk\t\t")
       print("  r  ( -- )  Random Trunk\t\t")
    io.write("  a  ( a -- )  Adjacent\t\t")
       print("  l  ( n -- )  Lineage\t\t")
    io.write("  k  ( ?? )  Judge\t\t")
       print("  j  ( ?? )  Know\t\t")
  print('\n\n')
end

function map()
  print( "Trunks:  "..#crm.trunks() )
end

function randTrunk(s)
  local ts = crm.trunks()
  ts = ts[ math.random( 1, #ts ) ]
  table.insert( s, ts )
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
  crm.addL( drops(s), drops(ss) )
end

function attrOf( s )
  local a = drops(s)
  local p = drops(s)
  for k, v in pairs( crm.getAttributes(p) ) do
    if a==k then print( v ) end
  end
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

function exitSave()
  crm.save("data.db")
  return false
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

  ['i'] = function() one( stack, crm.info      ) end, 
  ['m'] = function() map() end, 
  ['r'] = function() randTrunk( stack ) end, 
  ['t'] = function() crm.printEntries( crm.trunks() ) end, 

  ['+t'] = function() addTrunk  ( stack ) end, 
  ['+b'] = function() addBranch ( stack ) end, 
  ['+l'] = function() addLeaf   ( stack, sstack ) end, 

  ['@'] = function() attrOf( stack ) end,

  ['+']    = function()  add(stack) end,
  ["drop"] = function() drop(stack) end, 
  ["dup"]  = function()  dup(stack) end, 
  ["swap"] = function() swap(stack) end, 

  ["sdrop"]= function() drop(sstack) end, 
  ["sdup"] = function()  dup(sstack) end, 

  [".s"]    = function() printAry(stack) end, 
  [".ss"]   = function() printAry(sstack) end, 
  ["clr"]   = function() stack = {} sstack = {} end,
  ['help']  = function() help() end, 
  ['x']     = function()  state = false end, 
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
