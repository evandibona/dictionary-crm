local misc = require('./lib/misc.lua')
local crm = {}
crm.db = ""

function crm.open( n )
  local f = io.open(n, "rb")
  if f then
    n = f:read("*a")
    f:close()
    crm.db = n
  else
    crm.db = ""
  end
end

function crm.save( n )
  local f = io.open(n, "w")
  f:write(crm.db)
  f:close()
end

local function intToStr( n ) return   string.pack(">I4", n) end
local function strToInt( s ) return string.unpack(">I4", s) end

function crm.extract( a )
  a = a + 1 or 1
  if a < #crm.db then
    local e = {}
    e.addr     = a - 1
    e.next     = strToInt( string.sub( crm.db,   a, a+3 ) )
    e.date     = strToInt( string.sub( crm.db, a+4, a+7 ) )
    e.isTrunk  = (  e.next >= 2^31  )
    if e.isTrunk then
      e.next   = e.next - 2^31
      e.label  = string.sub( crm.db, a+8, e.next  )
    else
      e.parent = strToInt( string.sub( crm.db, a+8, a+11) ) 
      e.data   = string.sub( crm.db, a+12, e.next )
    end
    e.addr = math.floor(e.addr)
    e.next = math.floor(e.next)
    return e
  else
    print("  Err: Address exceeds limits.")
  end
end

function crm.forEachEntry( f )
  local e = {}
  e.next = 0
  while e.next < #crm.db - 1 do
    e = crm.extract( e.next )
    f(e)
  end
end

function crm.forRevEntry( f )
  local es = crm.entries()
  for i = #es, 1, -1 do
    f( crm.extract(es[i]) )
  end
end

function crm.forEachFrom( start, f )
  local e = {}
  e.next = start
  while e.next < #crm.db - 1 do
    e = crm.extract( e.next )
    f(e)
  end
end

function crm.forEachUntil( f )
  local b = false
  local e = {}
  e.next = 0
  while (e.next < #crm.db - 1) and (not b) do
    e = crm.extract( e.next )
    b = f(e)
  end
  return b
end


function crm.forEachChildOf( node, f )
  local children = crm.childrenOf( node )
  for i=1,#children do
    f(crm.extract(children[i]))
  end
end

function crm.addT( ref, t )
  adr = #crm.db
  t = t or os.time()
  local nxt = 2^31 + #crm.db
        nxt = nxt + 8 + #ref
  crm.db = crm.db..intToStr( nxt )
  crm.db = crm.db..intToStr(  t  )
  crm.db = crm.db..ref
  return adr
end

function crm.addL( par, dat, t )
  adr = #crm.db
  t = t or os.time()
  local nxt = #crm.db + 12 + #dat
  crm.db = crm.db..intToStr( nxt )
  crm.db = crm.db..intToStr(  t  )
  crm.db = crm.db..intToStr( par )
  crm.db = crm.db..dat
  return adr
end

local function looseMatch( a, b )
  b = string.sub(b, 1, #a)
  return a == b
end

function crm.addr( s )
  return crm.forEachUntil(
    function( e )
      if looseMatch(s, (e.label or e.data)) then
        return e.addr
      end
    end
  )
end

---- Array Returns ----

function crm.entries()
  local es = {}
  crm.forEachEntry(
    function( e )
      table.insert(es, e.addr)
    end
  )
  return es
end

function crm.trunks()
  local ts = {}
  crm.forEachEntry(
    function( e )
      if e.isTrunk then
        table.insert(ts, e.addr)
      end
    end
  )
  return ts
end

function crm.branches()
  local bs = {}
  crm.forEachEntry(
    function( e )
      if not e.isTrunk and not string.find(e.data or e.label, ":") then
        table.insert(bs, e.addr)
      end
    end
  )
  return bs
end

function crm.branchesOf( node )
  local  br = {}
  local  ch = crm.childrenOf( node )
  for i=1,#ch do
    local c = crm.extract(ch[i])
    if not string.find(c.data,":") then
      table.insert(br, c.addr)
    end
  end
  return br
end

function crm.indexTrunks()
  local ts = {}
  crm.forEachEntry(
    function( e )
      if e.isTrunk then
        ts[e.label] = e.addr
      end
    end
  )
  return ts
end

function crm.fullChildrenOf( node )
  local ch = {}
  crm.forEachEntry(
    function( e )
      if not e.isTrunk then
        if node == e.parent then
          ch[#ch+1] = e.addr
        end
      end
    end
  )
  return ch
end

function crm.childrenOf( node )
  local ch = {}
  crm.forEachFrom( node, 
    function( e )
      if not e.isTrunk then
        if node == e.parent then
          ch[#ch+1] = e.addr
        end
      end
    end
  )
  return ch
end

function crm.branchesOf( node )
  local  br = {}
  local  ch = crm.childrenOf( node )
  for i=1,#ch do
    local c = crm.extract(ch[i])
    if not string.find(c.data,":") then
      table.insert(br, c.addr)
    end
  end
  return br
end

function crm.parentOf( n )
  return crm.extract(n).parent or n
end

function crm.originOf( n )
  local e = extract(n)
  while not e.isTrunk do
    e = crm.extract(e.parent)
  end
  return e.addr
end

function crm.findAll( s, n, ary )
  local all = {}
  s = s or ""
  local function fx( e )
      if looseMatch(s, (e.label or e.data)) then
        table.insert(all, e.addr)
      end
    end
  if not n then       crm.forEachEntry( fx )
  elseif not ary then crm.forEachChildOf( n, fx ) 
  else for i=1,#ary do fx( crm.extract(ary[i]) ) end
  end
  return all
end

---- CLI F(x)'s (Mostly) ---- Offload to other library?

function crm.split( str )
  local mid = string.find( str, ":" )
  return { string.sub(str, 1, mid-1),
           string.sub(str, mid+1, #str) }
end

function crm.attributesOf( n )
  local attr = { }
  crm.forEachChildOf( n, 
    function( c )
      if string.match(c.data, ":") then
        table.insert( attr, c.addr )
      end
    end
  )
  return attr
end

function crm.tagsOf( n )
  local ary = crm.attributesOf( n )
  local tags = ""
  for i=1,#ary do
    local e = crm.extract(ary[i]) 
    local s = crm.split(e.data)
    if s[1] == "tags" then
      tags = s[2] 
    end
  end
  return splitCsv(tags)
end

function crm.fetchAttr( a, p ) --<-- Relocate this to lib/crm 
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

function crm.storeAttr( p, b, a )
  return crm.addL( p, a..':'..b )
end

function storeAttrAry( ary, atr, d )
    for i=1,#ary do
      if type(ary[i]) == 'number'then
        crm.addL( ary[i], atr..":"..d )
      end
    end
end


function crm.taggedWith( tag )
  local sec = { }
  crm.forRevEntry(
    function( e )
      if string.find(e.data or "","tags:") then
        local ln = { e.parent, crm.split(e.data)[2] }
        misc.addNoDup(sec, ln)
      end
    end
  )
  ary = { }
  for i=1,#sec do
    local e = sec[i]
    if string.find(e[2], tag) then
      misc.addNoDup(ary, e[1])
    end
  end
  return ary
end

function crm.graph( n )
  local children = crm.childrenOf( n )
  for i = 1,#children do
    local c = crm.childrenOf( children[i] )
    if #c > 0 then
      children[i] = crm.graph( children[i] )
    end
    io.write('.') io.flush()
  end
  print()
  return { n, children }
end

function crm.lineage( n )
  local lng = { n }
  n = crm.extract(n)
  while not n.isTrunk do
    n = crm.extract( n.parent )
    table.insert( lng, 1, n.addr )
  end
  return lng
end

function crm.info( node )
  node = crm.extract( node )
  local str = node.label or node.data
  if #str > 64 then str = string.sub(str, 1, 61).."..." end
  print(node.addr.." : "..str.." : "..node.next)
end

function crm.last()
  local l = {}
  crm.forEachEntry(
    function( e ) l = e.addr end
  )
  return l
end

function crm.drop()
  local l = crm.last()
  crm.db = string.sub( crm.db, 1, l )
end

function crm.prune( chopThese )
  local set = { }
  for eye, keeper in pairs( keep ) do
    local lvl = #crm.lineage(keeper)
    if not set[lvl] then set[lvl] = { } end
    local inr = set[lvl]
    table.insert(inr, keeper)
    set[lvl] = inr
  end
-- The basic challenge is: I need to be able to drop the occasional tree
-- But I also need to be able to prune the occasional branch. 

  return set
end

local function construct( s )
  -- Take the raw data in the form of an array, and populate the database 
  -- from it. 
  s = 
  {
    { 
      { 'tree1', 1611835782 }, 
      { 'tree2', 1611805978 }, 
    }, 
    { 
      { 'tree1', 'branch1', 1611806778 }, 
      { 'tree2', 'branch2', 1611869167 }, 
      { 'tree2', 'branch3', 1611815078 }, 
    }, 
    { 
      { 'branch1', 'leaf1', 1611847641 }, 
      { 'tree1',   'leaf2', 1611847770 }, 
      { 'branch3', 'leaf3', 1611798242 }, 
      { 'branch3', 'leaf4', 1611830105 }, 
      { 'branch3', 'leaf5', 1611835768 }, 
    }, 
  }

  for ix, lvl in pairs( s ) do
    for a=1,ix do io.write("  ") end io.flush()
    for i, entry in pairs( lvl ) do
      if #entry==2 then
        print( crm.addT(entry[1], entry[2]) )
      elseif #entry==3 then
        print( crm.addL( crm.addr(entry[1]), entry[2], entry[3] ) )
      end
    end
  end
end

function crm.dropReconstruct( A )
  local struct = { }
  local stack  = crm.trunks() -- >>123>> first in, first out
  local nstack = crm.trunks()
  local lvl = 1
  while #stack > 0 do
    for i=1,#stack do
      print( '::::::>', i, stack[i] )
      local e = crm.extract(stack[i])
      print( e.label or e.data )
      print( table.remove(nstack) )
    end
    stack = nstack
  end
end

function crm.keepReconstruct( A )
end

function crm.rebuildFrom( )
  print()
  local new = { }
  table.sort(keepers, function(i,j) return i > j end)

  while #keepers > 0 do
    local e = crm.extract(table.remove(keepers))
    if e.isTrunk then
      table.insert(new, { e.label, e.date })
    else
      local p = crm.extract(e.parent)
      p = p.label or p.data
      table.insert(new, { p, e.data, e.date })
    end
  end
  --- Don't do any of the checking for children or parents above. 
  --- If a parent doesn't exist below, just leave it off. 

  crm.db = ""
  for i,keeper in pairs(new) do
    if #keeper == 2 then
      crm.addT(keeper[1], keeper[2])
    else
      if crm.addr(keeper[1]) then
        crm.addL(crm.addr(keeper[1]), keeper[2], keeper[3])
      end
    end
  end
end 

return crm
