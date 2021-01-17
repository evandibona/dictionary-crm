#!/usr/bin/lua5.3

local csv = require('./lib/csv.lua')
local crm = require('./lib/crm.lua')

local usefulSymbols = "︙🞂🞍🞜"

function join( a, d )
  local s = ""
  for i=1,(#a-1) do
    s = s..a[i]..d
  end return s..a[#a]
end

function splitInput( str )
  local wrds = {}
  local sS = false
  local curw = ""
  for i=1,#str do
    local c = string.sub(str, i, i)
    if c==" " and (not sS)  then
      if #curw > 0 then
        table.insert(wrds, curw)
        curw = "" 
      end
    elseif c=='"' then
      sS = not sS
      if sS == false then
      elseif sS == true then
        if #curw > 0 then
          table.insert(wrds, curw) 
          curw = "" 
        end
      end
    else
      curw = curw..c
    end
  end
  if #curw > 0 then
    table.insert(wrds, curw)
  end
  return wrds
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
  print()
  for i=1,#a do
    if type(a[i])=='table' then
      print("     --table--")
    else
      print("  "..max((#a-i+1).."  "..a[i]))
    end
  end
end

function prettyPrint( a )
  local prefix = " "
  local function prettyInner( a )
    if tonumber(a) then
      local e = crm.extract(tonumber(a)) 
      local adr = string.format( '%8d' ,tostring(e.addr) )
      print(adr..max( prefix..(e.label or e.data) ))
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
  return a[drops(s)+1]
end

function fetchAttr( a, p )
  local atr = crm.attributesOf(p)
  local mts = { }
  for i=#atr,1,-1 do
    local e = crm.extract(atr[i]).data
    if crm.split(e)[1] == a then
      table.insert(mts, atr[i])
    end
  end
  return mts[1]
end

function storeAttr( a, p )
  io.write("  "..a.."> ") io.flush()
  return crm.addL( p, a..":"..io.read() )
end

function storeAttrAry( ary, a )
  io.write("{"..a.."}".." > ") io.flush()
  local d = io.read()
  for i=1,#ary do
    crm.addL( ary[i], a..":"..d )
  end
end

function push( s, n ) s[#s+1] = n return s    end
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

function help()
  flatPrint({ 
    " Return Ary  : Return Node : Take Ary    : Take Node   : Other       ",
    " all         |  f find     | .A Print    | .B          | .  p top    ",
    " trunks      | +t addTrunk | nth Idx     |  ! strAtr   | .s p stack  ",
    " childrenOf  | +b addBranch| A! !Atr2Ech |  @ fchAtr   |  clr        ",
    ' graph       | +b> " &rtrn |             |             |             ',
    " lineage     |             |             |             |             ",
    " branchesOf  |             |             |             |             " 
  })
end

function interpret(raw, words, s, a, b) --move above words
  raw = splitInput( raw )
  for ix=1,#raw do
    local chunk = raw[ix] 
    if words[chunk] ~= nil then
      words[chunk]()
    elseif tonumber(chunk) ~= nil then
      table.insert(s, tonumber(chunk))
    --[[
    elseif metaWords[chunk] ~= nil then
      metaWords[chunk](raw)
    ]]
    else
      table.insert( s, chunk )
    end
  end
end

crm.open("data.db")
local stack = {}
local A = {}
local B = 0
local state = true
local words = 
{
-- Return Array
  ['a']  = function() A = crm.entries()  end, 
  ['t']  = function() A = crm.trunks()   end, 
  ['b']  = function() A = crm.branches() end, 
  ['c:'] = function() A = crm.childrenOf(B) end, 
  ['p:'] = function() B = crm.parentOf(drops(stack) or B) end, 
  ['b:'] = function() A = crm.branchesOf(B) end, 
  ['t:'] = function() A = crm.taggedWith(drops(stack)) end, 
  ['g:'] = function() A = crm.graph(B) print() end, 
  ['f:'] = function() A = crm.findAll(drops(stack)) end, 
  ['t!'] = function() push( stack, crm.tag(B) ) end, 
  ['t@'] = function() push( stack, crm.tagsOf(B) ) end, 
-- Return Node( tree or branch )
  ['f']  = function() B = crm.addr(drops(stack)) end, 
  ['+t'] = function() B = crm.addT(    drops(stack) ) end, 
  ['+b'] = function()     crm.addL( B, drops(stack) ) end, 
  ['+b>']= function() B = crm.addL( B, drops(stack) ) end, 
-- Input Array
  ['nth'] = function() B = nth(stack, A) end, 
  [".A"]   = function() prettyPrint(A) end, 
  ['A!'] = function() storeAttrAry( A, drops(stack) ) end, 
-- Input Node
  ['@'] = function() push( stack, fetchAttr( drops(stack), B )) end,
  ['!'] = function() push( stack, storeAttr( drops(stack), B )) end, 
  [".B"]   = function() prettyPrint(B) end, 
-- Ease
  ['l']  = function() A = crm.lineage( B )  end, 
  ["company-summary"] = function() end, 
  ["person-summary"] = function() end,  --phone,email,address,name
--Other
  ['.']= function() prettyPrint(drops(stack)) end, 
  ['i'] = function() crm.info(stack) end, 
  ['r'] = function() print("report, catered to strategy") end, 
  ['B']    = function() B = drops(stack) end, 
--Meta
  ['kick'] = function() crm.drop()    end, 
--Data Ops
  ['+']    = function()  add(stack) end,
  ['++']   = function()  addadd(stack) end,
  ["drop"] = function() drop(stack) end, 
  ["dup"]  = function()  dup(stack) end, 
  ["swap"] = function() swap(stack) end, 

  ['.s']   = function() flatPrint(stack) end, 
  ['clr']  = function() stack = {} A = {} B = 0 end,

  ['help'] = function() help() end, 
  ['save'] = function() crm.save('data.db') end,
  ['x']    = function()  state = false end,
  ['exit'] = function()  state = false end
}

-- Main - Loop --

print()
if arg and (#arg > 0) then
  interpret(join(arg, " "), words, stack, A, B)
else
  while state do
    prompt(stack, A, B) 
    interpret(io.read(), words, stack, A, B)
  end
end
print()

--In future restructuring: 
--Add support so command line arguments can pass cmds to prgm
--Basic Macros would also be handy
-- aka interpret( string )
