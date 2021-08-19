local csv = require('./lib/csv.lua')
local crm = require('./lib/crm.lua')

print("Opening file, processing into arrays...")
csv.open('import.csv')
crm.open("data.db")

print("Loading into database...")
--print(#csv.lines, "...", #csv.keys)

local tree = ""

csv.allByKey(function( i, key, e)
  local function aL( a, k, d )
    return crm.addL(a,k..":"..d) end
  if key == 'label' then
    print(e.." ❥")
    tree = crm.addT(e)
  elseif key=='company'  then aL(tree, key, e)
  elseif key=='city'     then aL(tree, key, e)
  elseif key=='state'    then aL(tree, key, e)
  elseif key=='phone'    then aL(tree, key, e)
  elseif e  =='small' then crm.addL(tree, "tags:small")
  elseif key=='employee' then tree = crm.addL(tree, e)
  elseif key=='title'    then aL(tree, key, e)
  end
end)

print("Done.")
crm.save('data.db')
print("File Saved.")
