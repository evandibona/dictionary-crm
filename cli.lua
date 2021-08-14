#!/usr/bin/lua5.3

local csv  = require('./lib/csv.lua')
local crm  = require('./lib/crm.lua')
local misc = require('./lib/misc.lua')
local scrW = 58
local ext  = { }

--[[
  I want this to be plug and play. I don't want it to require a separate set
  up for each individual db and subject matter it handles. 
  That said, being able to craft specific scripts for each domain is also 
  important. 
  So the best solution (I think) will be to package each domain into its own
  directory. With a Lua script, database, and various backups. 

  Should I remove the interpret from command line arguments?
  I think so. Besides, can't I use a pipe?

  First, I still need to handle the repacking. My idea needs to be tried. 
--]]

local usefulSymbols = "︙🞂🞍🞜‒❥●│├─"

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
  io.write(#(a or { }).." 《")
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

function flatPrint( a )
  print()
  for i=1,#a do
    if type(a[i])=='table' then
      print("     table<"..#a[i]..">")
    else
      print("  "..misc.limit((#a-i+1).."  "..a[i], scrW))
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
      print(adr..misc.limit( prefix..(e.label or e.data), scrW ))
    elseif type(a)=='string' then
      print(misc.limit( prefix..a, scrW ))
    elseif type(a)=='table' then
      if #a > 0 then
        prefix = prefix.."  "
      end
      for i=1,#a do
        prettyInner(a[i])
      end
      if #a > 0 then
        prefix = string.sub(prefix, 1, #prefix-2)
      end
    else
      push( num or a )
    end
  end
  prettyInner(a)
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
  table.insert(s, flip(a))
  return s
end

function getAttributes( p )
  local sorted    = { }
    sorted.notes  = { }
    sorted.phones = { }
  local atrs = crm.attributesOf( p )
  for i=1,#atrs do
    local  a = crm.extract( atrs[i] )
      a.attr = crm.split( a.data )[1]
      a.data = crm.split( a.data )[2]
    if a.attr == "note" then
      table.insert(sorted.notes, {
        os.date( "%I:%M %a", a.date ),
        a.data
      })
    elseif a.attr == "phone" then
     table.insert(sorted.phones,  
       '('..string.sub(a.data,1,3)..')'
       ..string.sub(a.data,4,6)
       ..'-'..string.sub(a.data,7,10))
    elseif a.attr == 'company' then sorted.company = a.data
    elseif a.attr == 'title' then sorted.title = a.data
    elseif a.attr == 'state' then sorted.state = a.data
    elseif a.attr == 'city' then sorted.city = a.data
    end
  end
  return sorted
end

local function summary( t ) 
  local tree = getAttributes(t)
  local lbl = tree.company or crm.extract( t ).label
  print()
  print( "  "..misc.flatten( lbl, 29 ), 
    (tree.city or "")..", "..(tree.state or ""))
  if #tree.phones > 0 then
    print( "", "  "..table.concat(tree.phones, "  ") )
  end

  local emps = crm.branchesOf( t )
  for ie=1,#emps do
    local emp = getAttributes( emps[ie] )
    local enm = crm.extract( emps[ie] ).data
      emp.title = emp.title or ""

    print("", enm..", "..emp.title)
    if emp.state and emp.city then
      print("\t  "..emp.state..", "..emp.city)
    end
    if #emp.phones > 0 then
      print("", "  "..table.concat(emp.phones, "  "))
    end
    if #emp.notes > 0 then
      for k=1,#emp.notes do
        print("", "  ".. 
          emp.notes[k][2], "\n", "    ".. 
          emp.notes[k][1])
      end
    end
  end
  print()
  if #tree.notes > 0 then
    for k=1,#tree.notes do
      print(tree.notes[k][1]
        .."  "..tree.notes[k][2])
    end
  end
  print("\n\n")
end

function parentsOf( a )
  local ps = { }
  for i=1,#a do
    table.insert(ps, { crm.parentOf(a[i]), { a[i] } })
  end
  return ps
end

function lineagesOf( a )
  local ls = { }
  for i=1,#a do
    local lin = crm.lineageOf(a[i])
    table.insert(ls, { table.remove(lin,1), lin })
  end
  return ls
end

function flip(ary)
  yra = {}
  for i=#ary, 1, -1 do
    yra[#yra+1] = ary[i]
  end
  return yra
end

function aMinusA(a, b)
  local i = 0
  while(i<#a) do
    i=i+1
    local j = 0
    while(j<#b) do
      j=j+1
      if a[i]==b[j] then 
        table.remove(b,j)
        table.remove(a,i) i=i-1
        j = #b end
    end
  end
  return a
end

function aMinusAaa(a, b)
  print()
  local c = {}
  for i=1,#a do
    local j = 0
    repeat
      j = j+1
      io.write(a[i]..b[j]..":: ")
      if a[i]==b[j] then 
        io.write("*")
        table.insert(c,a[i])
        j = #b end
    until(j==#b)
    io.flush()
    print()
  end
  return c
end


function push( n )  stack[#stack+1] = n     end
function dup ()     push( stack[#stack] ) end
function drop()     stack[#stack] = nil     end
function add()      push( drops() + drops() ) end
function swap()     local x = drops() local y = drops() push(x) push(y) end
function drops( s ) local e = stack[#stack] drop() return e end
function adds( )    stack[#stack] = stack[#stack] + stack[#stack-1] end

function getStr( prompt )
  local prompt = prompt or ""
  io.write('\n'..prompt..'> ') 
  io.flush() 
  return io.read() 
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

function interpret(raw, words, s, a, b) --move above words
  raw = splitInput( raw )
  for ix=1,#raw do
    local chunk = raw[ix] 
    if ext[chunk] ~= nil then
      ext.A, ext.B, ext.S = a, b, s
      ext.crm, ext.misc, ext.csv = crm, misc, csv
      ext[chunk]()
    elseif words[chunk] ~= nil then
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

stack = {}
A = {}
B = 0
state = true
words = 
{

-- Ease of Use
  ['company'] = function() crm.addL(B, 'company:'..getStr('company')) end,
  ['address'] = function() crm.addL(B, 'address:'..getStr('address')) end,
  ['phone'] =   function() crm.addL(B, 'phone:'..getStr('phone')) end,
  ['state'] =   function() crm.addL(B, 'state:'..getStr('state')) end,
  ['title'] =   function() crm.addL(B, 'title:'..getStr('title')) end,
  ['name' ] =   function() crm.addL(B, 'first:'..getStr('first')) 
                           crm.addL(B,  'last:'..getStr( 'last')) end,
  ['city'] =    function() crm.addL(B, 'city:'..getStr('city')) end,
  ['note'] =    function() crm.addL(B, 'note:'..getStr('note')) end,
  ['url'] =     function() crm.addL(B, 'url:'..getStr('url')) end,
-- Return Array, Collect
  ['}']  = function() stack = makeAry(stack) end, 
  ['a']  = function() A = crm.entries()  end, 
  ['t']  = function() A = crm.trunks()   end, 
  ['b']  = function() A = crm.branches() end, 
  ['f:'] = function() A = crm.findAll(drops()) end, 
  ['t:'] = function() A = crm.taggedWith(drops()) end, 
  ['b:'] = function() A = crm.branchesOf(B) end, 
  ['c:'] = function() A = crm.childrenOf(B) end, 
  ['p:'] = function() A = parentsOf(A) end, 
  ['l:'] = function() A = lineagesOf(A) end,
  ['@:'] = function() print("NI:_attributesOf()") end, 
  ['1:'] = function() 
    local a={} for i=1,#A do table.insert(a,A[i][1]) end A=a end, 
  ['2:'] = function() 
    local a={} for i=1,#A do table.insert(a,A[i][2]) end A=a end, 
-- Return Refine Array Set [[ For later implementation. ]]
  [':f'] = function() A = crm.findAll(drops(), 0, A) end,
  [':n:']= function() A = aMinusA( drops(), A ) end,
  ['sub']= function() swap() A = misc.subset( A, drops(), drops() ) end, 
-- Return Node( tree or branch )
  ['f']  = function() B = crm.findAll(drops())[1] end, 
  ['+t'] = function() B = crm.addT(    drops() ) end, 
  ['+b'] = function()     crm.addL( B, drops() ) end, 
  ['+b>']= function() B = crm.addL( B, drops() ) end, 
  ['p']  = function() B = crm.parentOf(B) end, 
  ['..'] = function() B = crm.parentOf(B) end, 
-- Input Array
  -- ['nth'] = function() outByType( A[drops()] ) end,
  ['nth']= function()     push( A[drops()] ) end,
  ['.a']  = function() flatPrint(A) end, 
  ['.A']  = function() prettyPrint(A) end, 
  [':!']  = function() swap() crm.storeAttrAry(A, drops(), drops() ) end, 
  [':g']  = function() for i=1,#A do prettyPrint(crm.graph(A[i])) end end,
-- Input Node
  ['@'] = function() push( crm.fetchAttr( drops(), B )) end,
  ['!'] = function() push( crm.storeAttr(B, drops(), drops()) ) end,
  ['o'] = function() summary(B) end, --overview
-- Ease
  ['l']  = function() A = crm.lineageOf( B )  end, 
  ['g'] = function() prettyPrint( crm.graph(B) ) end, 
  ['person-summary'] = function() end,  --phone,email,address,name
--Other
  ['B']     = function() B = drops() end, 
  ['A.']    = function() push( A ) end, 
  ["'"]     = function() push( tostring(drops()) ) end, 
--Stack Ops
  ['+']    = function()  add() end,
  ['++']   = function() adds() end,
  ['drop'] = function() drop() end, 
  ['dup']  = function()  dup() end, 
--Ary Ops
  ['A']    = function() A = drops() end, 
  ['>']    = function() B = A[#A] A[#A] = nil end, 
  ['<']    = function() A[#A+1] = B B = nil end, 
  ['A>']   = function() push( A ) A = { } end,
  ['alf']  = function() table.sort(A) end, 
  ['rdup'] = function() A = misc.removeDups(A) end, 
  ['swap'] = function() swap() end, 
  ['flip'] = function() A = flip(A) end, 

  ['_']    = function() push( getStr() ) end, 
  ['.']    = function() prettyPrint(drops() or B) end, 
  ['.B']   = function() prettyPrint(B) end, 
  ['.s']   = function() flatPrint(stack) end, 
  ['clr']  = function() stack = {} A = {} B = 0 end,

-- Experimental DB Management --

--Meta
  ['kick'] = function() crm.drop()    end, 
  ['-r'] = function() crm.dropReconstruct( A ) end, 
  ['+r'] = function() crm.keepReconstruct( A ) end, 
  ['rebuild'] = function() crm.rebuildFrom(A) words['clr']() end, 

-- -- -- -- -- -- -- -- -- -- --

  ['aa'] = ext.aye, 
  ['bb'] = function() ext.bee() end, 
  ['cc'] = function() ext.cee() end, 

  ['save'] = function() crm.save(ext.fname or 'data.db') end,
  ['x']    = function()  state = false end,
  ['exit'] = function()  state = false end
}

-- Main - Loop --

print()
if arg and (#arg > 0) then
  ext = require(arg[1]..".lua")
  ext.fname = arg[1].."/data.db"
  crm.open(ext.fname)
else
  crm.open("data.db")
end

while state do
  prompt(stack, A, B) 
  interpret(io.read(), words, stack, A, B)
end

print()


-- The Big To Do --

-- Log Displays
  -- All Notes, All Events

-- User Friendliness --
--   tags used
-- flatten function
-- Difference of sets, aka all trunks that are not tagged by __
  -- Implement as each one that returns arrays, has a positive and neg option.

-- At some point redesign this so that anything pushed to B
--  pops it down into the stack. 

-- next  Array element after the found one. 

-- Pretty Printing needs to all be isolated to a library. 
-- Definitely need an inline way of handling long strings. 
  -- _ has its limits
-- "crm.split()" needs to be changed to misc.split
-- Search by content, not just data. 
-- Create array of content of a specific tag. 
--    note :@:   or   note @:
-- define f as finding the first entry which matches. 
-- Change +b so that it defaults to _ if the stack is empty. 
-- get good at listing employees, aka, branches and their leaves.
-- get good at displaying a company log. Events and Notes with times.
-- make sure Tags, Events, and Notes all have words to manage them.
-- Word for 'nullifying' an entry.
--  Date zeroed, gets ignored on rebuild. 
-- Work on the other 2 uses of the findAll function
-- All of these array operations need their own library


---
--- TURN PRETTY-PRINT INTO AN ITERATOR IN CRM
---
-- That way it can simplify graph, prettyPrint, and allow
-- for the simple navigation of search results. 


