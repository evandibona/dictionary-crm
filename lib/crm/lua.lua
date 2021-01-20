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

local function limit( s, n )
  if #s > n then s = string.sub(s, 1, n) end 
  return s
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

function crm.findAll( s )
  local all = {}
  crm.forEachEntry(
    function( e )
      if looseMatch(s, (e.label or e.data)) then
        table.insert(all, e.addr)
      end
    end)
  return all
end

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

---- CLI F(x)'s (Mostly) ---- Offload to other library?

function crm.printEntries( ary )
  for i=1,#ary do
    local e = crm.extract(ary[i])
    if e.isTrunk then
      io.write("● "..e.addr.." : ")
    else
      io.write("  ∙ "..e.addr.." : ")
    end
    print(e.label or e.data)
  end
end

function crm.split( str )
  return { string.match(str, "(.+):"), 
           string.match(str, ":(.+)") }
end

local function splitCsv( str )
  local split = { }
  local tmp = ""
  for i=1,#str do
    local c = string.sub(str,i,i)
    if c == ',' then
      table.insert(split,tmp)
      tmp = ""
    else
      tmp = tmp..c
    end
  end
  table.insert(split,tmp)
  return split
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

function isDup( t, n )
  local o = false
  n = n[1]
  for i=1,#t do
    if t[i][1] == n then o = true end
  end
  return o
end

function crm.taggedWith( tag )
  local sec = { }
  crm.forRevEntry(
    function( e )
      if string.find(e.data or "","tags:") then
        local ln = { e.parent, crm.split(e.data)[2] }
        if not isDup( sec, ln ) then
          table.insert(sec, ln)
        end
      end
    end
  )
  ary = { }
  for i=1,#sec do
    local e = sec[i]
    if string.find(e[2], tag) then
      table.insert(ary, e[1])
    end
  end
  return ary
end

local function printPhone( s )
  local o = ""
  if #s > 10 then
    o = string.sub(s,1,1).."-"
    s = string.sub(s,2,#s) 
  end
  o = o..(string.sub(s,1,3).."-"..string.sub(s,4,6).."-"..string.sub(s,7,10))
  return o
end

function crm.summarize( node )
  print('\n')
  node = crm.extract( node )
  local attr = crm.getAttributes( node.addr )
  if attr['company'] then
    print('\n\t\t', attr['company'])
    print("Address:      ", 
      attr['address'], '    ', attr['city']..', '..attr['state']) 
    print("Phone #: ", printPhone(attr['phone']), 
      "\t\tEmail: ", attr['email'])
    print("Website:      ", attr['website'])
  elseif attr['first'] then
    print(attr['first'], attr['last'])
    print(attr['phone'], attr['email'])
  end
  local ch = crm.childrenOf( node.addr )
  print( "\n  ---- Recent Additions: ----" )
  if #ch < 7 then
    crm.printEntries( ch )
  else
    for i = #ch, #ch-6, -1 do
      local e = crm.extract(ch[i])
      print( e.addr.." : ", os.date( "%H:%M  %a %b %d, %Y", e.date ), 
        limit(e.data,33) )
    end
  end
end

function crm.diagram( node )
  local n = crm.extract(node)
  print( n.addr..' ● '..( n.label or n.data ) )
  local chilluns = crm.childrenOf( node )
  for i=1,#chilluns do
    local c = crm.extract(chilluns[i])
    local granchilluns = crm.childrenOf( c.addr )
    if #granchilluns == 0 then
      print(c.addr,'   ‒❥ '..limit(c.data,60) )
    else
      print(c.addr,'   -- '..limit(c.data,60) )
      for ix=1, #granchilluns do
        local gc = crm.extract( granchilluns[ix] )
        print(gc.addr,'     ❥ '..limit(gc.data,60) )
      end
    end
  end
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
  local lng = { }
  n = crm.extract(n)
  while not n.isTrunk do
    n = crm.extract( n.parent )
    table.insert( lng, 1, n.addr )
  end
  return lng
end

function crm.print( n )
  crm.printEntries( { n } )
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

---- REBUILD DATABASE ----
-- Purpose, to exclude entries from the database. 
-- By extension move branches from one trunk to another. 

-- One solution: Parent labels must be tracked. 
-- That may be the key to avoiding fancy graphs. 

local function isInAry( ary, e )
  local r = false
  for i=1,#ary do
    if ary[i] == e then
      r = true
    end
  end
  return r
end

local function addNoDup( ary, e )
  if not isInAry( ary, e ) then
    table.insert( ary, e )
    return #ary
  else
    return false
  end
end

function crm.rebuildFrom( keepers )
  print()
  local new = { }
  local old = crm.entries() 

  while #keepers > 0 do
    local e = crm.extract(table.remove(keepers))
    local c = crm.childrenOf(e.addr) 
    if e.isTrunk then
      table.insert(new, { e.label, e.date })
    else
      local p = crm.extract(e.parent)
      p = p.label or p.data
      table.insert(new, { p, e.data, e.date })
    end
    if #c > 0 then
      for i=#c,1,-1 do
        table.insert(keepers, c[i])
      end
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
