crm = require("lib.lua")

local db = crm.slurp('data.bin')

print('----- Nodes -----')
crm.forEachNode(db, 
  function( node )
    print( node.label )
  end
)
print('-----------------')

local ceoLoc = crm.locN(db, 'Microsoft-CEO')

crm.forEachLeaf(db, 
  function( entry )
    print(entry['next'])
  end
)

-- Print each Leaf of a Node
-- Import a CSV as a list of leaves to the dictionary. 

--local f  = io.open("data", "a")
--  f:write(db)
--  f:close()

