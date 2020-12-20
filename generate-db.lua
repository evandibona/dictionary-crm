crm = require("lib.lua")

node1 = { 1605848654, "MrDimon" }
node2 = { 1606241133, "Microsoft-CEO" }
node3 = { 1607241840, "mr-chapek" }

--Node 1
  leaf1_1 = { 1605879060, 0, "name:Jamie Dimon" }
  leaf1_2 = { 1605909060, 0, 
              "note:He had a professional job for 2 years before "..
              "college. Michael A. Neal and other members of the board "..
              "with JP Morgan would be a fine place to start I believe."
  }
  leaf1_3 = { 1605927120, 0, "company:JP Morgan Chase" }
--Node 2
  leaf2_1 = { 1606241133, 0, "name:Satya Nadella" }
  leaf2_2 = { 1606270123, 0, "company:Microsoft" }
  leaf2_3 = { 1606291751, 0, 
              "note:This dude just looks weak. And after "..
              "some reading that appears to be a brilliant cover. "..
              "because he has made some crazy acquisitions."
  }
--Node 3
  leaf3_1 = { 1607251899, 0, "name:Bob Chapek" }
  leaf3_2 = { 1607260021, 0, "company:The Walt Disney Company" }
  leaf3_3 = { 1607260840, 0, 
              "note:Seems to be a pretty typical CEO, still in "..
              "the shadow of Bob Iger."
  }

local db = ""
        db = crm.addN(db, node1)
        db = crm.addN(db, node2)
        db = crm.addN(db, node3)

leaf1_1[2] = crm.locN(db, "MrDimon"        )
leaf2_1[2] = crm.locN(db, "Microsoft-CEO"  )
leaf3_1[2] = crm.locN(db, "mr-chapek"      )
print( leaf3_1[2] )

leaf1_2[2] = leaf1_1[2]
leaf2_2[2] = leaf2_1[2]
leaf3_2[2] = leaf3_1[2]

leaf1_3[2] = leaf1_1[2]
leaf2_3[2] = leaf2_1[2]
leaf3_3[2] = leaf3_1[2]

db = crm.addL(db, leaf1_1)
db = crm.addL(db, leaf1_2)
db = crm.addL(db, leaf1_3)
db = crm.addL(db, leaf2_1)
db = crm.addL(db, leaf2_2)
db = crm.addL(db, leaf2_3)
db = crm.addL(db, leaf3_1)
db = crm.addL(db, leaf3_2)
db = crm.addL(db, leaf3_3)

-- Save to File 

local f  = io.open("data.bin", "a")
  f:write(db)
  f:close()

