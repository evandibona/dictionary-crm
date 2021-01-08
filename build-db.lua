crm = require("./lib/crm.lua")

local _bob   = crm.addT("bob")
local _josh  = crm.addT("josh")
local _luke  = crm.addT("luke")
local _mark  = crm.addT("mark")
local _craig = crm.addT("craig")
local _paul  = crm.addT("paul")
  crm.addL(_josh,  "note:Who is this guy?")
  crm.addL(_craig, "note:He just found his way here.")
  crm.addL(_paul,  "cell:2438759098")
  crm.addL(_mark,  "note:Maybe a crazy person?")
  crm.addL(_josh,  "address: 666 Rainbows End, Suffolk, MO")
  crm.addL(_paul,  "note:Was demoted.")
  crm.addL(_josh,  "phone: 8072845655")
  crm.addL(_paul,  "address: 25 Bay St, Chicago, IL")
  crm.addL(_paul,  "action:call:Left a good voicemail, asked for his opinion.")

io.write(crm.db)