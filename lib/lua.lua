local crm = {}

local function intToStr( n ) return string.pack(">I4", n)   end
local function strToInt( s ) return string.unpack(">I4", s) end

local function getN( n ) return 0 end -- These two fx's are going to hold
local function getL( n ) return 0 end -- what is now in "pullNext"
local function pullNext( d, i )
  i = i + 1 or 1
  local adr = strToInt( string.sub( d, i, i + 3 ) )
  local node = false
  if adr >= 2^31 then 
    adr = adr - 2^31 
    node = true
  end
  return { adr, node }
end

local function deconstruct( e )
  local nA = pullNext( e, 0 )
  entry = {
    ["next"] = nA[1], 
    ["node"] = nA[2],
    ["date"] = strToInt( string.sub( e, 5, 8 ) ), 
    ["location"] = ( nA[1] - #e )
  }
  if entry['node'] then
    entry['label'] = string.sub( e, 9, #e )
  else
    entry['parent'] = strToInt( string.sub( e, 9, 12 ) )
  end
  return entry
end

local function forEachEntry( d, f )
  local i = { 0, 0 }
  local e = ""
  while i[1] < #d do
    i[2] = i[1]
    i[1] = pullNext( d, i[1] )[1]
    e = string.sub( d, i[2]+1, i[1] )
    f(deconstruct(e))
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
  local nodes = { }
end


return crm
