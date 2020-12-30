crm = require("./lib/crm.lua")

local db = crm.slurp('data.db')

print('----- Nodes -----')
crm.forEachNode(db, 
  function( node )
    crm.printChildren(db, node.label)
  end
)
print('-----------------\n')

--crm.printChildren(db, 'Microsoft-CEO')

-- Print each Leaf of a Node
-- Import a CSV as a list of leaves to the dictionary. 

--local f  = io.open("data", "a")
--  f:write(db)
--  f:close()

