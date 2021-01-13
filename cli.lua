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
  io.write(#a.." 《")
  for i=#s-2,#s,1 do
    if s[i] then io.write('■ ') else io.write('□ ') end
  end
  io.write("》"..(b or 'nil')..' › ') 
  io.flush()
end

function max( str )
  if #str > 72 then
    str = string.sub(str,1,72)
  end return str end

function flatPrint( a )
  for i=1,#a do
    print(max("  "..a[i]))
  end
end

function prettyPrint( a )
  local prefix = " "
  local function prettyInner( a )
    if tonumber(a) then
      local e = crm.extract(tonumber(a)) 
      print(e.addr..max( prefix..(e.label or e.data) ))
    elseif type(a)=='string' then
      print(max( prefix..a ))
    elseif type(a)=='table' then
      if #a > 2 then
        prefix = prefix.."  "
      end
      for i=1,#a do
        prettyInner(a[i])
      end
      if #a > 2 then
        prefix = string.sub(prefix, 1, #prefix-2)
      end
    else
      print("\tInvalid Input.")
    end
  end
  prettyInner(a)
end

function nth( s, a )
  s[#s] = a[s[#s]]
end

function find( s )
  return crm.addr(drops(s)) 
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

function push( s, n ) s[#s+1] = n     end
function dup ( s )    s[#s+1] = s[#s] end
function drop( s )    s[#s] = nil     end
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

function exitSave()
  crm.save("data.db")
  return false
end

crm.open("data.db")
local stack = {}
local A = {}
local B = 0
local state = true
local words = 
{
-- Return Array
  ['a'] = function() A = crm.entries() end, 
  ['t'] = function() A = crm.trunks() end, 
  ['c'] = function() A = crm.childrenOf(B) end, 
  ['g'] = function() A = crm.graph(B) print() end, 
  ['l'] = function() A = crm.lineage( B )  end, 
--Return Node( tree or branch )
  ['f'] = function() B = find( stack ) end, 
  ['+t'] = function() addTrunk  ( stack ) end, 
  ['+b'] = function() addBranch ( stack ) end, 
  ['+l'] = function() addLeaf   ( B, sstack ) end, 

  ['@'] = function() fetchAttr( stack ) end,
  ['!'] = function() storeAttr( stack ) end, 

-- Input Array
  ['nth'] = function() nth(stack, A) end, 
  [".A"]   = function() prettyPrint(A) end, 
  --length
-- Input Node
  [".B"]   = function() prettyPrint(B) end, 
  --summary, lineage, info, graph. Don't alter B. 
  --next, increment B to next entry or next item in A.
--Other
  ['i'] = function() crm.info(stack) end, 
  ['r'] = function() print("report, catered to strategy") end, 
--Meta
  ['kick'] = function() crm.drop()    end, 

  ['address!'] = function() addressAttr( stack ) end, 

  ['+']    = function()  add(stack) end,
  ['++']   = function()  addadd(stack) end,
  ["drop"] = function() drop(stack) end, 
  ["dup"]  = function()  dup(stack) end, 
  ["swap"] = function() swap(stack) end, 

  ["A"]    = function() A = drops(stack) end, 
  ["B"]    = function() B = drops(stack) end, 
  ["B+"]   = function() B = crm.extract(B).next end, 
  [".s"]   = function() flatPrint(stack) end, 
  ["clr"]  = function() stack = {} end,

  ['help'] = function() print("not yet") end, 
  ['save'] = function() crm.save('data.db') end,
  ['x']    = function()  state = false end,
  ['exit'] = function()  state = false end
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
    else
      table.insert(stack, typed)
    end
  end
end

