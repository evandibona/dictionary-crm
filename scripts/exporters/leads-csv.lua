#!/usr/bin/lua5.3

-- Nothing too special right now. 
-- This is simply a script to spit out
-- All of the trunks as formatted companies
-- So that they can be printed. 

local csv = require('./lib/csv.lua')
local crm = require('./lib/crm.lua')

crm.open("data.db")

local trunks = crm.trunks()

local function nabAtr(a, p)
  return 
  crm.split(
    crm.extract(
      crm.fetchAttr(a, p)
    ).data
  )[2]
end

for i=1,100,1 do
  local trunk = trunks[i]

  local company = nabAtr('company', trunk)
  local phone = nabAtr('phone', trunk)
  local line = ""

  line = company..", "..phone

  local children = crm.childrenOf(trunk)
  local ccnt = 0
  for i=1,#children,1 do
    if #crm.childrenOf(children[i]) > 1 then
      local first = nabAtr('first', children[i])
      local last  = nabAtr('last', children[i])
      local rank =  nabAtr('title', children[i])
      line = line..", "..first.." "..last..", "..rank
      ccnt = ccnt + 2
      if ccnt > 2 then ccnt = 0 break end
    end
  end
  csv.appendLine( line )
    csv.appendLine("") csv.appendLine("")
    csv.appendLine("")
  print(i.."/100")
end

csv.writeNew("tested.csv")

-- Attributes to Keep: 
--    * company
--    * phone
--    * all employees and position
