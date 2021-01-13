#!/usr/bin/lua5.3

local csv = require('./lib/csv.lua')
local crm = require('./lib/crm.lua')

local usefulSymbols = "︙🞂🞍🞜"

function splitInput( str )
  local ary = {}
  for e in string.gmatch(str, "([^%s]+)") do
    table.insert(ary, e)
  end
  return ary
end

function prompt(s, a, b)
  io.write("#A:"..#a.." ")
  for i=#s-4,#s,1 do
    if s[i] then io.write('■ ') else io.write('□ ') end
  end
  io.write("︙"..(b or 'nil')..' › ') 
  io.flush()
end

function help()
  print()
    io.write("   +t  ( s -- ) +Trunk   ")
    io.write("+t  ( n s -- ) +Branch   ")
    io.write("+t  ( n s -- ) +Leaf   ")

  print('\n')
    io.write("  s  ( n -- )  Summarize\t")
       print("  d  ( n -- )  Diagram\t\t")
    io.write("  i  ( n -- )  Info\t\t")
       print("  f  ( n -- )  Find\t\t")
    io.write("  ;  ( n -- )  Print\t\t")
       print("  @  ( n s -- )  Attribute of Tree\t\t")
    io.write("  t  ( -- )    Print Trunk\t")
       print("  r  ( -- )    Random Trunk\t\t")
    io.write("  a  ( a -- )  Adjacent\t\t")
       print("  l  ( n -- )  Lineage\t\t")
    io.write("  j  ( -- )    Jumper, latest. ")
       print("\n","  kick  ( -- n )  Kick, drop latest.")
  print('\n')
end

function randEntry(s)
  math.randomseed(s[#s])
  local entries = crm.entries()
  s[#s] = entries[math.random(1,#entries)]
end
function randEntryPlus(s)
  local h = s[#s]
  randEntry(s)
  table.insert(s, h+1)
  swap(s)
end

function find( s )
  s[#s] = crm.addr(s[#s]) 
end

function addTrunk( s )
  table.insert( s, crm.addT( drops(s) ) )
end

function addBranch( s )
  swap( s )
  table.insert( s, crm.addL( drops(s), drops(s) ) )
end

function addLeaf( s, ss, o )
  o = o or ""
  if not string.find(ss[#ss], ":") then
    print("\tNo attribute specified, leaf not added.")
  else
    s[#s] = crm.parentOf( crm.addL( s[#s], drops(ss) ) )
  end
end

function fetchAttr( s )
  local a = drops(s) local p = drops(s)
  for k, v in pairs( crm.getAttributes(p) ) do
    if a==k then print( v ) end
  end
  table.insert( s, p )
end

function storeAttr( s )
  local a = drops(s) local p = drops(s)
  io.write("  "..a.."> ") io.flush()
  local v = io.read()
  crm.addL( p, a..":"..v )
  table.insert( s, p )
end

function addressAttr( s )
  
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
  s[#s-1] = s[#s] + s[#s-1]
  drop(s)
end

function addadd( s )
  s[#s] = s[#s] + s[#s-1]
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

function exitSave()
  crm.save("data.db")
  return false
end

crm.open("data.db")
local backup= crm.db
local stack = {}
local A = {}
local B = 0
local state = true
local words = 
{
-- Return Array
  ['l'] = function() A = crm.lineage( stack )  end, 
  --AllEntries
  ['t'] = function() crm.trunks() end, 
  --AllChildrenOf
  --Search All Data / Labels
  ['g'] = function() A = crm.graph(B)   end, 
--Return Node( tree or branch )
  ['f'] = function() B = find( stack ) end, 
  ['+t'] = function() addTrunk  ( stack ) end, 
  ['+b'] = function() addBranch ( stack ) end, 
  ['+l'] = function() addLeaf   ( stack, sstack ) end, 
-- Input Array
  --prettyPrint
  --nth
  --length
-- Input Node
  --summary, lineage, info, graph. Don't alter B. 
  --next, increment B to next entry or next item in A.
--Other
  ['i'] = function() crm.info(stack) end, 
  ['r'] = function() print("report, catered to strategy") end, 
--Meta
  ['kick'] = function() crm.drop()    end, 

  ['@'] = function() fetchAttr( stack ) end,
  ['!'] = function() storeAttr( stack ) end, 

  ['address!'] = function() addressAttr( stack ) end, 

  ['+']    = function()  add(stack) end,
  ['++']   = function()  addadd(stack) end,
  ["drop"] = function() drop(stack) end, 
  ["dup"]  = function()  dup(stack) end, 
  ["swap"] = function() swap(stack) end, 

  ["A"]    = function() A = drops(stack) end, 
  [".A"]   = function() prettyPrint(A) end, 
  [".B"]   = function() crm.print(B) end, 
  [".s"]   = function() printStack(stack) end, 
  ["clr"]   = function() stack = {} end,

  ['help']  = function() help() end, 
  ['undo']  = function() crm.db = backup crm.save("data.db") end,
  ['x']     = function()  state = false end
}

-- Main - Loop --
print("\n")
while state do
  prompt(stack, A, B) 
  local line = io.read('*l')
  for ix, typed in pairs(splitInput(line)) do
    if words[typed] ~= nil then
      words[typed]()
    elseif tonumber(typed) ~= nil then
      table.insert(stack, tonumber(typed))
    elseif #typed>= 3 then
      table.insert(stack, typed)
    else
      print("\t...word not found.")
    end
  end
  crm.save("data.db")
end

