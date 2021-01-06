crm = require("./lib/crm.lua")

crm.db = ""

crm.addT("bob")
crm.addT("josh")
  crm.addL(crm.addr("josh"), "note:Who is this guy?")
  crm.addL(crm.addr("josh"), "address: 666 Rainbows End, Suffolk, MO")
  crm.addL(crm.addr("josh"), "phone: 8072845655")
crm.addT("luke")
crm.addT("mark")
  crm.addL(crm.addr("mark"), "note:Maybe a crazy person?")
crm.addT("craig")
  crm.addL(crm.addr("craig"), "note:He just found his way here.")

local index = crm.indexTrunks()

crm.forEachEntry( 
  function( e )
    print(e.addr)
  end
)

crm.forRevEntry( 
  function( e )
    print(e.addr)
  end
)





--local f  = io.open("data", "a")
--  f:write(db)
--  f:close()

