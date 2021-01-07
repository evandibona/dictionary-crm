crm = require("./lib/crm.lua")

crm.slurp("data.db")

crm.addT("mr-clean")
crm.addT("mr-clean")
crm.addT("mr-clean")
crm.addT("mr-clean")

crm.printEntries( crm.trunks() )

