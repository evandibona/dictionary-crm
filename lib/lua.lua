local crm = {}

local function intToStr( n ) return string.pack(">I4", n)   end
local function strToInt( s ) return string.unpack(">I4", s) end

local function pullEntry( d, i )
  i = i + 1 or 1
  local entry = {}
  entry["next"] = strToInt( string.sub( d, i, i+3 ) )
  entry["node"] = ( entry["next"] >= 2^31 )
  entry["date"] = strToInt( string.sub( d, i+4, i+7 ) )
  entry["location"] = ( entry["next"] - i )
  if entry["node"] then
    entry["next"] = entry["next"] - 2^31
    entry['label'] = string.sub( d, i+8, entry["next"] )
  else
      entry["parent"] = strToInt( string.sub ( d, i+8, i+11 ) )
      entry["data"] = string.sub( d, i+12, entry["next"] )
  end
  return entry
end

local function forEachEntry( d, f )
  local entry = pullEntry( d, 0 )
  while entry['next'] < #d do
    f(entry)
    entry = pullEntry( d, entry["next"] )
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
  local loc = 0 
  forEachEntry( data, 
    function( entry )
      if label == entry['label'] then
        loc = entry['location']
      end
    end
  )
  return loc
end

function crm.printTree( data )
  forEachEntry( data, 
    function( entry ) 
      if entry['node'] then
        print( entry['label'] )
      else
        print( entry['data'] )
      end
    end 
  )
end


return crm
