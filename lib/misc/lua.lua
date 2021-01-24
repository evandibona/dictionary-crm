local m = {}
local width = 32
local step  = 11 
local max   = 2^40
local min   = 11000
function m.everyAscii()
  print("\n\n")
  for c=min,max do
    io.write(utf8.char(c))
    if (c%width)==0 then
      print(c)
    elseif (c%step)==0 then
      io.read("*l")
    end
  end
end

function m.limit( s, n )
  if #s > n then s = string.sub(s, 1, n) end 
  return s
end

function m.join( ary, d )
  local s = ""
  for i=1,(#ary-1) do
    s = s..ary[i]..d
  end return s..ary[#ary]
end

function m.subset( ary, a, b )
  local nary = {}
  if ( a < b ) and ( b <= #ary ) then
    for i=a,b do
      table.insert(nary, ary[i]) 
    end
  end
  return nary
end

function m.isInAry( ary, e )
  local r = false
  for i=1,#ary do
    if ary[i] == e then
      r = true
    end
  end
  return r
end

function m.addNoDup( ary, e )
  if not isInAry( ary, e ) then
    table.insert( ary, e )
    return #ary
  else
    return false
  end
end

function m.printPhone( s )
  local o = ""
  if #s > 10 then
    o = string.sub(s,1,1).."-"
    s = string.sub(s,2,#s) 
  end
  o = o..(string.sub(s,1,3).."-"..string.sub(s,4,6).."-"..string.sub(s,7,10))
  return o
end



return m
