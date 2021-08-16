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

function m.flatten( s, n )
  s = m.limit(s, n)
  while #s < n do
    s = s.." "
  end
  return s
end

function m.limits( s, n, x )
  s = m.limit(s, x)
  s = string.format("%"..n.."s", s)
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
  if b > #ary then b = #ary end
  if ( a <= b ) then
    for i=a,b do
      table.insert(nary, ary[i]) 
    end
  elseif a == b then
    nary = { ary[b] }
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
  if not m.isInAry( ary, e ) then
    table.insert( ary, e )
    return #ary
  else
    return false
  end
end

function m.removeDups( ary )
  table.sort(ary)
  local ay = {}
  local a, b = 0, 1
  while b <= #ary do
    a=a+1 b=b+1
    if ary[a] ~= ary[b] then
      table.insert(ay,ary[a])
    end 
  end return ay
end

function m.formatPhone( s )
  local o = ""
  if #s > 10 then
    o = string.sub(s,1,1).."-"
    s = string.sub(s,2,#s) 
  end
  o = o..(
    " ("..string.sub(s,1,3)..") "..
    string.sub(s,4,6).."-"..string.sub(s,7,10)  )
  return o
end



return m
