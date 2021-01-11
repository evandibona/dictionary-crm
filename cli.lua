#!/usr/bin/lua5.3

local csv = require('./lib/csv.lua')
local crm = require('./lib/crm.lua')
local ext = { } 
if arg[1] then
  local ext = require(arg[1])
end


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

function map()
  print( "Trunks:  "..#crm.trunks() )
end

function randTrunk(s)
  math.random(s[#s])
  local ts = crm.trunks()
  s[#s] = ts[ math.random( 1, #ts ) ]
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

function jmpr( s )
  s[#s+1] = crm.last()
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
  ['j'] = function() jmpr( stack ) end, 
  ['k'] = function() print( sstack[#sstack] ) end, 
  ['l'] = function() one( stack, crm.lineage   ) end, 
  [';'] = function() one( stack, crm.print     ) end, 

  ['i'] = function() one( stack, crm.info      ) end, 
  ['m'] = function() map() end, 
  ['r'] = function() randTrunk( stack ) end, 
  ['t'] = function() crm.printEntries( crm.trunks() ) end, 

  ['+t'] = function() addTrunk  ( stack ) end, 
  ['+b'] = function() addBranch ( stack ) end, 
  ['+l'] = function() addLeaf   ( stack, sstack ) end, 

  ['@'] = function() fetchAttr( stack ) end,
  ['!'] = function() storeAttr( stack ) end, 

  ['address!'] = function() addressAttr( stack ) end, 

  ['+']    = function()  add(stack) end,
  ["drop"] = function() drop(stack) end, 
  ["dup"]  = function()  dup(stack) end, 
  ["swap"] = function() swap(stack) end, 

  ["sdrop"]= function() drop(sstack) end, 
  ["sdup"] = function()  dup(sstack) end, 

  [".s"]    = function() printAry(stack) end, 
  [".ss"]   = function() printAry(sstack) end, 
  ["clr"]   = function() stack = {} sstack = {} end,
  ['kick'] = function() crm.drop()    end, 
  ['help']  = function() help() end, 
  ['x']     = function()  state = false end, 
}

-- Main - Loop --
while state do
  if stack[#stack-1] then io.write(' ■ ') else io.write(' □ ') end
  io.write((stack[#stack] or 'nil')..' > ') 
  io.flush()
  local line = io.read('*l')
  line = processStrings(sstack, line)
  for ix, typed in pairs(splitInput(line)) do
    if words[typed] ~= nil then
      words[typed]()
    elseif ext[typed] ~= nil then
      ext[typed]()
    elseif tonumber(typed) ~= nil then
      table.insert(stack, tonumber(typed))
    elseif #typed>= 3 then
      table.insert(stack, typed)
    else
      print("\t...not found.")
    end
  end
  crm.save("data.db")
end
