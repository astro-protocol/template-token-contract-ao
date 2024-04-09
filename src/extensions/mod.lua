local runtime = require "src.runtime"

local mod = {
  tables = {}
}

---Taken from https://www.lua.org/pil/19.3.html
function mod.tables.pairs_by_keys(t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end

function mod.tables.sort(t)
  if not t then
    return {}
  end

  if type(t) ~= "table" then
    runtime.throw("Cannot sort non-table value")
  end
  
  local ret = {}

  for i, v in mod.tables.pairs_by_keys(t) do
    ret[i] = v
  end

  return ret
end

return mod
