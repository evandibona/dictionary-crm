local csv = require('./lib/csv.lua')
local crm = require('./lib/crm.lua')

print("Opening file, processing into arrays...")
csv.open('csv/samples/residential-numbers.csv')

print("Loading into database...")

local state = 0

csv.keys[2] = "name2"
csv.keys[4] = "phone2"

local previousRef = ""
local many = 0
csv.forEachLine( function( l ) 
    -- name, name2, phone, phone2, address, city, state, zip
    --[[
    if l[1] then
      for n in string.gmatch(l[1], "([%a%p]+)") do
        io.write(n, " ")
      end
      io.write("  :  ")
    end
    if l[2] then
      for n in string.gmatch(l[2], "([%a%p]+)") do
        io.write(n, " ")
      end
    end
    print('\n')
    if l[3] then
      local p = string.gsub(l[3], "-", "")
      --print(p) 
    end
    if l[4] then
      local p = string.gsub(l[4], "-", "")
      --print(p) 
    end
    --]]
    local r = string.gsub((l[1] or l[2]), " ", "-").."-"..(l[6] or 'unknown')
    if r ~= previousRef then
      local p = crm.addT(r)
        if l[5] then
          crm.addL( p, "zip:"..l[8] )
          crm.addL( p, "state:"..l[7] )
          crm.addL( p, "city:"..l[6] )
          crm.addL( p, "address:"..l[5] )
        end
        if l[1] then
          crm.addL( p, string.gsub(l[1]," ","-") ) end
        if l[2] then
          crm.addL( p, string.gsub(l[2]," ","-") ) end
        if l[3] then
          crm.addL( p, "phone:"..string.gsub(l[3],"-","") ) end
        if l[4] then
          crm.addL( p, "phone:"..string.gsub(l[4],"-","") ) end
      many = many + 1
    end
    previousRef = r
  end )

  print("\tentries: ", many)

print("Done.")
crm.save('data.db')
print("File Saved.")

