#!/usr/bin/lua5.3

-- Nothing too special right now. 
-- This is simply a script to spit out
-- All of the trunks as formatted companies
-- So that they can be printed. 

local csv = require('./lib/csv.lua')
local crm = require('./lib/crm.lua')
local misc =require('./lib/misc.lua')

crm.open("data.db")

local trees = crm.trunks()

local function nabAtr(a, p)
  local atr = crm.fetchAttr(a, p)
  if atr then
    return 
      crm.split( crm.extract(atr).data )[2]
    else return ""
  end
end

local function printNotes( p )
end

local function getAttributes( p )
  local sorted    = { }
    sorted.notes  = { }
    sorted.phones = { }
  local atrs = crm.attributesOf( p )
  for i=1,#atrs do
    local  a = crm.extract( atrs[i] )
      a.attr = crm.split( a.data )[1]
      a.data = crm.split( a.data )[2]
    if a.attr == "note" then
      table.insert(sorted.notes, {
        os.date( "%I:%M %p  %a %b,%d", a.date ),
        a.data
      })
    elseif a.attr == "phone" then
     table.insert(sorted.phones,  
       '('..string.sub(a.data,1,3)..')'
       ..string.sub(a.data,4,6)
       ..'-'..string.sub(a.data,7,10))
    elseif a.attr == 'company' then sorted.company = a.data
    elseif a.attr == 'title' then sorted.title = a.data
    elseif a.attr == 'state' then sorted.state = a.data
    elseif a.attr == 'city' then sorted.city = a.data
    end
  end
  return sorted
end

local cstart = 1
local cend = 3
  if cend > #trees then cend = #trees end
print("\n\n\n\n\n\n")
print("\t","-------------------------")
print("\t","|      Phone Time!      |")
print("\t","|    "..(cend-cstart).."+ calls to make   |")
print("\t","-------------------------")
print()

for i=cstart,cend do 
  local t = trees[i]
  local tree = getAttributes(t)
  local lbl = tree.company or crm.extract( t ).label
  print( "  "..misc.flatten( lbl, 29 ), 
    (tree.city or "")..", "..(tree.state or ""))
  if #tree.phones > 0 then
    print( "", "  "..table.concat(tree.phones, "  ") )
  end

  local emps = crm.branchesOf( t )
  for ie=1,#emps do
    local emp = getAttributes( emps[ie] )
    local enm = crm.extract( emps[ie] ).data
      emp.title = emp.title or ""

    print("", enm..", "..emp.title)
    if emp.state and emp.city then
      print("\t  "..emp.state..", "..emp.city)
    end
    if #emp.phones > 0 then
      print("", "  "..table.concat(emp.phones, "  "))
    end
    if #emp.notes > 0 then
      for k=1,#emp.notes do
        print("", "  ".. 
          emp.notes[k][2], "\n", "    ".. 
          emp.notes[k][1])
      end
    end
  end
  print()

end

  --print( tree.label, nabAtr("city", t)..", "..nabAtr("state", t) )
