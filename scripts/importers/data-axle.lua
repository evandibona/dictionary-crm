local csv = require('./lib/csv.lua')
local crm = require('./lib/crm.lua')

print("Opening file, processing into arrays...")
csv.open('csv/samples/nc-manufacturing.csv')
-- 
-- 15 is first-name-1

print("Loading into database...")

local state = 0

function progress( n, s )
  n = math.floor( n / (1024*25) )
  n = n*25
  if (n>10) and (s~=n) then
    print( "\t"..n.." kilobytes..." )
  end
  return n
end

csv.forEachLine(
  function( v ) 
    local p = crm.addT( v[1] )
    crm.addL(p, "tags:cold")
    for i=2,14 do
      if v[i] then
        crm.addL(p, csv.keys[i]..":"..v[i] )
      end
    end
    for i=15,214,4 do
      if v[i] or v[i+1] or v[i+2]  then
        local first = v[i]
        local last  = v[i+1]
        local title = v[i+2]
        local label = string.lower(first).."-"..string.lower(last)
        label = string.gsub( label, " ", "-" )

        local e = crm.addL( p, label )
        if first then crm.addL( e, "first:"..first ) end
        if last  then crm.addL( e,  "last:"..last  ) end
        if title then crm.addL( e, "title:"..title ) end
      end
    end
    state = progress( #crm.db, state )
  end
)

print("Done.")
crm.save('data.db')
print("File Saved.")

--[[
csv.lineByKey(1331, function( k, v)
    if #v > 32 then v = string.sub(v, 1, 32) end
    print(k.." : \t\t"..v)
end)
--]]
