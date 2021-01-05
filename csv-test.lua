local csv = require('./lib/csv.lua')
local crm = require('./lib/crm.lua')

--[[
for line in io.lines('csv/dibona_assoc.csv') do
  print(line..'\n')
end
--]]

-- Process A New CSV 
--(the library is for quickly scripting an import, not for handling the whole thing)

local csvLines = csv.file2Lines('csv/dibona_assoc-new.csv')
local csvKey = csv.processLine(csvLines[1])
local db = ""

for ix=2,#csvLines do
  local split  = csv.processLine(csvLines[ix])
  local epoch  = split[csv.findKey(csvKey, 'epoch')]
  local parent = #db
  for i=1,#split do
    if i==1 then
      db = crm.addN(db, {epoch, split[i]})
      print(split[1]..", added on: "..os.date("%I:%M:%p %a in %B", epoch))
    elseif csvKey[i]=='epoch' then
    else 
      --Generate Leaf
      db = crm.addL(db, {epoch, parent, split[i]})
    end
  end
end

local f  = io.open("data.db", "w")
  f:write(db)
  f:close()

