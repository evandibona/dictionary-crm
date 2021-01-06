local crm = {}
crm.db = ""

local function intToStr( n ) return   string.pack(">I4", n) end
local function strToInt( s ) return string.unpack(">I4", s) end

function crm.extract( a )
  a = a + 1 or 1
  if a < #crm.db then
    local e = {}
    e.addr     = a - 1
    e.next     = strToInt( string.sub( crm.db,   a, a+3 ) )
    e.date     = strToInt( string.sub( crm.db, a+4, a+7 ) )
    e.isTrunk  = (  e['next'] >= 2^31  )
    if e.isTrunk then
      e.next   = e['next'] - 2^31
      e.label  = string.sub( crm.db, a+8, e['next']  )
    else
      e.parent = strToInt( string.sub( crm.db, a+8, a+11) ) 
      e.data   = string.sub( crm.db, a+12, e['next'] )
    end
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

function crm.forEachNode( d, f )
  local entry = {['next']=0}
  while entry['next'] < #d-1 do
    entry = pullEntry( d, entry['next'] )
    if entry['node'] then
      f( entry )
    end
  end
end

function crm.forEachLeaf( d, f )
  local entry = {['next']=0}
  while entry['next'] < #d-1 do
    entry = pullEntry( d, entry['next'] )
    if not entry['node'] then
      f( entry )
    end
  end
end

function crm.addN( data, node )
  local i = #data
  local nextA = 2^31 + i
        nextA = nextA + 8 + #node[2]

  data = data..intToStr( nextA )      -- Next
  data = data..intToStr( node[1] )    -- Date / Time
  data = data..node[2]

  return data
end

function crm.addL( data, leaf )
  local i = #data
  local nextA = i + 12 + #leaf[3]
  data = data..intToStr( nextA )    --Next
  data = data..intToStr( leaf[1] )  --Date
  data = data..intToStr( leaf[2] )  --Node
  data = data..leaf[3]              --Data
  return data
end

function crm.locN( data, label )
  local loc = nil
  crm.forEachNode( data, 
    function( entry )
      if entry['label'] == label then
        loc = entry['loc']
      end
    end
  )
  return loc
end

function crm.printChildren( d, node )
  local nLoc = crm.locN(d, node )
  print( "#"..node )

  crm.forEachLeaf(d, 
    function( entry )
      if nLoc == entry['parent'] then
        print('  * '..entry['data'])
      end
    end
  )
end


function crm.slurp( l )
  local f  = io.open( l )
  local db = ""
  if f then
    db = f:read("*a")
    f:close()
  else
    print("\tFile does not exist.")
  end
  return db
end

function crm.save( n, d )
  local f = io.open( n, 'w' )
  f:write(d)
  f:close()
end

return crm
