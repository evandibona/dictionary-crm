crm = require("./lib/crm.lua")

crm.db = crm.slurp('data.db')

crm.forEachEntry(
  function(entry)
    if entry.isTrunk then
      print(entry.label)
    else
      print(entry.data)
    end
  end
)




--local f  = io.open("data", "a")
--  f:write(db)
--  f:close()

