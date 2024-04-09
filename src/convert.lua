local runtime = require "src.runtime"
local assertions = require "src.assertions"
local aolibs = require "src.aolibs"

local mod = {}

---@class Converter
local Converter = {}

function Converter.init(v)
  ---@class ConverterInstance
  local instance = {
    conversion_fn = nil,
    failure_message = nil,
  }

  ---Change the given quantity to a Bint.
  ---@return Bint
  function instance.to_bint()

    local defaultMessage = "Could not convert value to Bint"
    local failureMessage = instance.failure_message or defaultMessage

    if not v then
      runtime.throw("Cannot convert nil to Bint")
    end
  
    ---@return Bint
    local status, value = pcall(function()
      return aolibs.bint(v)
    end)

    assertions.is_bint(value, failureMessage)

    return value
  end

  ---@param failure_message? any
  ---@return ConverterInstance
  function instance.with_failure_message(failure_message)
    instance.failure_message = failure_message

    return instance
  end

  function instance.as_table()

    ---Convert the table's values to strings.
    ---@return table
    instance.values_to_strings = function()

      local tableToConvert = v
      local ret = {}

      for i, value in pairs(tableToConvert) do
        ret[i] = tostring(value)
      end

      return ret
    end

    return instance
  end

  return instance
end

function mod.value(v)
  return Converter.init(v)
end
function mod.table(v)
  return Converter.init(v).as_table()
end

return mod
