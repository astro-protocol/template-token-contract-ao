local runtime = require "src.runtime"

local mod = {}

local function msg_to_str(msg)
  if type(msg) ~= "string" then
    msg = ""
  end

  return msg
end

---Assert that the given value is a `Bint`.
---@param value? Bint
---@param msg? string
function mod.is_bint(value, msg)
  msg = msg_to_str(msg)

  local hasBintFields = true

  if not value then
    hasBintFields = false
  end

  if not type(value) == "table" then
    hasBintFields = false
  end

  if not value.tobase then
    hasBintFields = false
  end

  if not value.__le then
    hasBintFields = false
  end

  if not value.__lt then
    hasBintFields = false
  end

  if not hasBintFields then
    runtime.throw(msg)
  end
end

---Assert that the given values are not the same.
---@param a any
---@param b any
---@param msg? string
function mod.is_not_same(a, b, msg)
  msg = msg_to_str(msg)

  if a == b then
    runtime.throw(msg)
  end
end

---Assert that the given value is not `nil`?
---@param v any
---@param msg any
function mod.is_not_nil(v, msg)
  msg = msg_to_str(msg)

  if v == nil then
    runtime.throw(msg)
  end
end

return mod