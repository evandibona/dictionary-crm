local csv = {}

function csv.processLine( line )
  local state = 0
  local ary = {}
  local i = 1
  for ix=1,#line do
    local char = string.sub(line,ix,ix)
    if char == '"' then
      state = 1 - state 
    elseif (state==0) and (char==',') then
      i = i + 1
    else
      if ary[i]==nil then ary[i] = "" end
      ary[i] = ary[i]..char
    end
  end
  return ary
end

function csv.file2Lines( name )
  local lines = {}
  local i = 1
  for line in io.lines(name) do
    lines[i] = line
    i = i + 1
  end
  return lines
end

function csv.findKey( keys, term )
  for i=1,#keys do
    if keys[i]==term then
      return i
    end
  end
end

return csv
