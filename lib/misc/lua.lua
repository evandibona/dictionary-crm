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

return m
