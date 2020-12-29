local csv = require('./lib/csv.lua')
local f   = csv.open('csv/dibona_assoc.csv')
print(f.read_header())
