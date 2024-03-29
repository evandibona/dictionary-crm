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
--[[

Upon startup with no database file present, have a micro wizard
or note about it. For example, 
No database file detected. Data fetch instructions will fail. 
  If you would like to import a backup -->
  If you want to start a new db then:  db-shortname +t

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
        os.date( "%I.%p %a %b %e, '%y", a.date ), -- DATE date Date fmt here.
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
    elseif a.attr == 'first' then sorted.first = a.data
    elseif a.attr == 'last' then sorted.first = a.data
    end
  end
  return sorted
end

local function summary( t ) 
  local tree = getAttributes(t)
  local lbl = tree.company 
    or crm.extract(t).label or crm.extract( t ).data
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

    if emp.first or emp.last then
      emp.fname = ", "..(emp.first or "").." "
        ..(emp.last or "")
    end

    print("", enm..", "..emp.title..(emp.fname or ""))
    if emp.state and emp.city then
      print("\t  "..emp.state..", "..emp.city)
    end
    if #emp.phones > 0 then
      print("", "  "..table.concat(emp.phones, "  "))
    end
    if #emp.notes > 0 then
      for k=1,#emp.notes do
        print("", "  "..emp.notes[k][2])
      end
    end
  end
  print()
  if #tree.notes > 0 then
    for k=1,#tree.notes do
      print("  "..tree.notes[k][1].."  🞂 "..tree.notes[k][2])
    end
  end
  print("\n\n")
end

function log()
  -- last 20 notes, last 20 events
  -- Or all notes & events from today. 
  -- Or the most recent one from every tree. 
  local events = crm.findAll("e:")
  for i=1,#events do
    local event = crm.extract(events[i])
    print( 
      os.date( "%I:%M%p  %a, %b %e", event.date ),
      crm.split(event.data)[2], 
      "\n")
  end
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

function eQuot( q )
  interpret(q, words, stack, A, B)
end
function forEachE( a, q )
  for i=1,#a do
    push( a[i] )
    interpret(q, words, stack, A, B)
  end
end


function push( n )  stack[#stack+1] = n     end
function dup ()     push( stack[#stack] ) end
function drop()     stack[#stack] = nil     end
function drops() local e = stack[#stack] drop() return e end
function add()      push( drops() + drops() ) end
function adds( )    stack[#stack] = stack[#stack] + stack[#stack-1] end
function swap()     local x = drops() local y = drops() push(x) push(y) end
function top()      return stack[#stack]   end
function sec()      return stack[#stack-1] end

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
  raw = splitInput( raw ) -- return status, don't execute if quotes used.
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
  [':']  = function() crm.addL(B, sec()..':'..drops()) drop() end,
  [':+'] = function() crm.addL(B, sec()..':'..drops()) end,
  [':}'] = function() forEachE(A, drops()) end,
-- Return Array, Collect
  ['}']  = function() stack = makeAry(stack) end, 
  ['a']  = function() A = crm.entries()  end, 
  ['t']  = function() A = crm.trunks()   end, 
  ['b']  = function() A = crm.branches() end, 
  ['f:'] = function() A = crm.findAll(drops()) end, 
  ['b:'] = function() A = crm.branchesOf(B) end, 
  ['c:'] = function() A = crm.childrenOf(B) end, 
  ['p:'] = function() A = parentsOf(A) end, 
  ['L:'] = function() A = lineagesOf(A) end,
  ['l:'] = function() A = crm.lineageOf( B )  end, 
  ['#:'] = function() A = crm.taggedWith(drops()) end, 
  ['@:'] = function() A = crm.withAttr(drops()) end, 
  ['1:'] = function() 
    local a={} for i=1,#A do table.insert(a,A[i][1]) end A=a end, 
  ['2:'] = function() 
    local a={} for i=1,#A do table.insert(a,A[i][2]) end A=a end, 
-- Return Refine Array Set [[ For later implementation. ]]
  [':f'] = function() A = crm.findAll(drops(), 0, A) end,
  ['f::']= function() A = crm.findAll(drops(), B) end, 
  [':n:']= function() A = aMinusA( drops(), A ) end,
  ['sub']= function() swap() A = misc.subset( A, drops(), drops() ) end, 
-- Return Node( tree or branch )
  ['f']  = function() B = crm.findAll(drops())[1] end, 
  ['+t'] = function() B = crm.addT(    drops() ) end, 
  ['+b'] = function()     crm.addL( B, drops() ) end, 
  ['+b>']= function() B = crm.addL( B, drops() ) end, 
  ['p']  = function() B = crm.parentOf(B) end, 
  ['@'] = function() push( crm.fetchAttr( drops(), B )) end,
  ['..'] = function() B = crm.parentOf(B) end, 
-- Input Array
  -- ['nth'] = function() outByType( A[drops()] ) end,
  ['nth']= function()     push( A[drops()] ) end,
  ['.a']  = function() flatPrint(A) end, 
  ['.A']  = function() prettyPrint(A) end, 
  [':g']  = function() for i=1,#A do prettyPrint(crm.graph(A[i])) end end,
-- Input Node
  ['o'] = function() summary(B) end, --overview
-- Ease
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
  ['|']    = function() A = crm.joinLists( A, drops() ) end, 
  ['sort'] = function() table.sort(A) end, 
  ['rdup'] = function() A = misc.removeDups(A) end, 
  ['swap'] = function() swap() end, 
  ['flip'] = function() A = flip(A) end, 

  ['log']  = function() log() end, 
  ['_']    = function() push( getStr() ) end, 
  ['.']    = function() prettyPrint(drops() or B) end, 
  ['.B']   = function() prettyPrint(B) end, 
  ['.s']   = function() flatPrint(stack) end, 
  ['clr']  = function() stack = {} A = {} B = 0 end,

-- Experimental DB Management --

--Meta
  ['kick']    = function() crm.drop()    end, 
  ['rebuild'] = function() crm.rebuild() end, 
  ['break']   = function() crm.breakdown( B ) end, 
  ['nix']     = function() crm.nix( drops() or B ) end, 

-- -- -- -- -- -- -- -- -- -- --

  ['save'] = function() crm.save(ext.fname or 'data.db') end,
  ['x']    = function()  state = false end,
  ['exit'] = function()  state = false end
}

-- Main - Loop --

print()
if arg and (#arg > 0) then        -- This needs to be tested and worked out. 
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


