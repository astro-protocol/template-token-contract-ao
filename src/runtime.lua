local mod = {}

---Throw an error object with a default level of `2`.
---@param message any
---@param level? number
function mod.throw(message, level)
  if level and type(level) == "number" then
    level = level + 1
  else
    level = 3
  end

  error(message, level)
end

function mod.require(module_name)
end

return mod