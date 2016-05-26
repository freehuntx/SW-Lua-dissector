function string.splitBySize(str, size)
  local split = {}

  for i=1, math.ceil(string.len(str)/size), 1 do
    table.insert(split, string.sub(str, (i-1)*size+1, i*size))
  end

  return split
end

function string.splitByBreak(str)
  local t = {}
  local function helper(line) table.insert(t, line) return "" end
  helper((str:gsub("(.-)\r?\n", helper)))
  return t
end