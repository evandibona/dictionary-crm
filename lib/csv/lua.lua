local csv = {}

local function trimLine( l )
  if string.byte(l, #l) == 13 then 
    l = string.sub(l, 1, #l-1)  
  end
  return l
end

local function processLine( line )
  line = trimLine( line )
  local state = false
  local ary = {}
  local i = 1
  for ix=1,#line do
    local char = string.sub(line,ix,ix)
    if char == '"' then
      state = not state 
    elseif (not state) and (char==',') then
      i = i + 1
    else
      if ary[i]==nil then ary[i] = "" end
      ary[i] = ary[i]..char
    end
  end
  return ary
end

local function fileToLines( name )
  local lines = {}
  local i = 1
  for line in io.lines(name) do
    lines[i] = line
    i = i + 1
  end
  return lines
end

function csv.findKey( keys, term )
  for i=1,#keys do
    if keys[i]==term then
      return i
    end
  end
end

csv.lines = {}
csv.keys  = {}

function csv.forEachLineI( f )
  for i = 1, #csv.lines do
    f( i, csv.lines[i] )
  end
end
function csv.forEachLine( f )
  for i = 1, #csv.lines do
    f( csv.lines[i] )
  end
end

function csv.open( n )
  csv.lines = fileToLines( n )
  csv.forEachLineI(
    function( i, v )
      csv.lines[i] = processLine( v )
    end
  )
  csv.keys = csv.lines[1]
  table.remove(csv.lines, 1)
end

function csv.allByKey( f )
  csv.forEachLineI( function( iy, line )
    for ix=1,#line do
      if line[ix] then
        f( iy, csv.keys[ix], line[ix] )
      end
    end
  end )
end

function csv.lineByKey( n, f )
  local l = csv.lines[n]
  for i=1, #l do
    if l[i] then
      f( csv.keys[i], l[i] )
    end
  end
end


return csv
