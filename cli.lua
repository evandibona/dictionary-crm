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

function getInput(s)
  io.write("  "..s.." > ")
  io.flush()
  return io.read()
end

function max( str )
  if #str > 72 then
    str = string.sub(str,1,72)
  end return str end

function subset( a, b, ary )
  local nary = {}
  if ( a < b ) and ( b <= #ary ) then
    for i=a,b do
      table.insert(nary, ary[i]) 
    end
  end
  return nary
end

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
    local num = math.tointeger(tonumber(a))
    if num then
      local e = crm.extract(num) 
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
      push( num or a )
    end
  end
  prettyInner(a)
end

function summary( e ) -- Create phone prettifier in misc, move string stuff too
  print('\t\t', string.upper(pullAttr(e, 'company')), '\n' )
  print('\tphone', pullAttr(e,'phone'),pullAttr(e,'city'),pullAttr(e,'address'))
  print('\n', pullAttr(e, 'description'))
  print("c:"..#crm.branchesOf(e))
end

function pullAttr( n, a ) --<-- Also relocate
  a = fetchAttr(a, n)
  if a then
    a = crm.split(crm.extract(a).data)[2]
  end
  return a or "unavailable"
end

function fetchAttr( a, p ) --<-- Relocate this to lib/crm 
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

function storeAttr( p, b, a )
  return crm.addL( p, a..':'..b )
end

function storeAttrAry( ary, atr, d )
    for i=1,#ary do
      if type(ary[i]) == 'number'then
        crm.addL( ary[i], atr..":"..d )
      end
    end
end

function makeAry(s) 
  local a = {}
  local i = #s
  while i > 0 do
    if s[i] == '{' then
      table.remove(s, i)
      i = 0
    else
      table.insert(a, s[i])
      table.remove(s, i)
      i = i - 1
    end
  end
  table.insert(s, a)
  return s
end

function push( n )  stack[#stack+1] = n     end
function dup ()     push( stack[#stack] ) end
function drop()     stack[#stack] = nil     end
function add()      push( drops() + drops() ) end
function swap()     local x = drops() local y = drops() push(x) push(y) end
function drops( s ) local e = stack[#stack] drop() return e end
function adds( )    stack[#stack] = stack[#stack] + stack[#stack-1] end

function slice( ary, n )
  print("not implemented")
  -- Get inner table 'n' times, until level == n. 
  -- Then remove all entries that are tables. 
  return ary
end

function outByType( data )
  local t = type(data)
  if     t=='string'  then push( data )
  elseif t=='number'  then B = data
  elseif t=='table'   then A = data
  end
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
stack = {}
A = {}
B = 0
state = true
words = 
{
-- Return Array, Collect
  ['}']  = function() stack = makeAry(stack) A = drops() end, 
  ['a']  = function() A = crm.entries()  end, 
  ['t']  = function() A = crm.trunks()   end, 
  ['b']  = function() A = crm.branches() end, 
  ['f:'] = function() A = crm.findAll(drops()) end, 
  ['t:'] = function() A = crm.taggedWith(drops()) end, 
  ['b:'] = function() A = crm.branchesOf(B) end, 
  ['c:'] = function() A = crm.childrenOf(B) end, 
-- Return Refine Array Set [[ For later implementation. ]]
  [':f'] = function() swap() A = crm.findIn(drops(), drops(), A)  end, 
  [':t'] = function() end, 
  [':a'] = function() end, 
  ['sub']= function() swap() A = subset( drops(), drops(), A ) end, 
-- Return Node( tree or branch )
  ['f']  = function() B = crm.addr(drops()) end, 
  ['+t'] = function() B = crm.addT(    drops() ) end, 
  ['+b'] = function()     crm.addL( B, drops() ) end, 
  ['+b>']= function() B = crm.addL( B, drops() ) end, 
  ['p']  = function() B = crm.parentOf(drops() or B) end, 
-- Input Array
  ['nth'] = function() outByType( A[drops()] ) end,
  ['nth.'] = function()     push( A[drops()] ) end,
  [".a"]  = function() flatPrint(A) end, 
  [".A"]  = function() prettyPrint(A) end, 
  [':!']  = function() swap() storeAttrAry(A, drops(), drops() ) end, 
  [':@']  = function() print("Is this feature necessary?") end, 
-- Input Node
  ['@'] = function() push( fetchAttr( drops(), B )) end,
  ['!'] = function() push( storeAttr(B, drops(), drops()) ) end,
  ['q'] = function() prettyPrint(crm.childrenOf(B)) end, 
  ['w'] = function() summary(B) end, 
-- Ease
  ['l']  = function() A = crm.lineage( B )  end, 
  ['g'] = function() prettyPrint( crm.graph(B) ) end, 
  ["person-summary"] = function() end,  --phone,email,address,name
--Other
  ['B']    = function() B = drops() end, 
  ["'"]    = function() push( tostring(drops()) ) end, 
--Meta
  ['kick'] = function() crm.drop()    end, 
--Data Ops
  ['+']    = function()  add() end,
  ['++']   = function()  adds() end,
  ["drop"] = function() drop() end, 
  ["dup"]  = function()  dup() end, 
  ["swap"] = function() swap() end, 
  ["input"]= function() push(getInput(drops())) end,
  ['slice']= function() A = slice(A, drops()) end, 

  ['.']    = function() prettyPrint(drops()) end, 
  [".B"]   = function() prettyPrint(B) end, 
  ['.s']   = function() flatPrint(stack) end, 
  ['clr']  = function() stack = {} A = {} B = 0 end,

  ['rebuild'] = function() crm.rebuildFrom(A) words['clr']() end, 

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

-- User Friendliness --
-- An empty enter could generate a 2 line summary of everything.
--   tags used
-- Reduce trim,addNoDup, and others to misc library. 
-- flatten function
-- Difference of sets, aka all trunks that are not tagged by __
  -- Implement as each one that returns arrays, has a positive and neg option.
--

