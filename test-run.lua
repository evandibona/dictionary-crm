crm = require("./lib/crm.lua")
csv = require("./lib/csv.lua")

-- Main - Loop --

local joe = crm.addT("joe")
  crm.addL( joe, "first:Joe" )
  crm.addL( joe, "last:Mann" )
  crm.addL( joe, "email:asdf@asdf.com" )
  crm.addL( joe, "phone:1231231234" )

crm.drop()
crm.summarize( joe )
crm.addL( joe, "note:He's a thief!" )
crm.addL( joe, "note:He's a pirate!" )
crm.summarize( joe )

