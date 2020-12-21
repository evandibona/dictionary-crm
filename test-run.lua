crm = require("lib.lua")

local db = crm.slurp('data.bin')

print('----- Nodes -----')
crm.forEachNode(db, 
  function( node )
    print( node.label )
  end
)
print('-----------------\n')

crm.printChildren(db, 'mr-chapek')
crm.printChildren(db, 'MrDimon')
crm.printChildren(db, 'Microsoft-CEO')

-- Print each Leaf of a Node
-- Import a CSV as a list of leaves to the dictionary. 

--local f  = io.open("data", "a")
--  f:write(db)
--  f:close()

