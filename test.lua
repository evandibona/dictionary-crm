local function intToStr( n ) return   string.pack(">I4", n) end
local function strToInt( s ) return string.unpack(">I4", s) end

local integer = 3

print( "*", #intToStr( integer ) )
print( "*", strToInt( intToStr( integer ) ) )

