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

function crm.getAttributes( n )
  local attr = { }
  crm.forEachChildOf( n, 
    function( c )
      if string.find(c.data, ":") then
        attr[string.match(c.data, "(.+):")] = 
             string.match(c.data, ":(.+)")
      end
    end
  )
  return attr
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
  --print("No entry matches the string: "..s)
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

function crm.parentOf( n )
  return crm.extract(n).parent
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


function crm.adjacent( node )
  node = crm.extract(node)
  if node.isTrunk then
    print("adjacent() is only valid for branches and leaves.")
  else
    return crm.childrenOf( node.parent )
  end
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

function crm.lineage( n )
  local prefix = ""
  n = crm.extract(n)
  while not n.isTrunk do
    prefix = prefix.."  "
    print("  "..n.addr, prefix..(n.data or n.label))
    n = crm.extract(n.parent)
  end
  print("  "..n.addr, prefix.." ⯄ "..(n.data or n.label))
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

return crm
