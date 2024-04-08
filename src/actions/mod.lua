local aolibs = require "src.aolibs"
local convert = require "src.convert"
local runtime = require "src.runtime"

local mod = {}

---@alias IncomingMessage { Tags: table<string, string>, From: string }
---Convert handler messages to a uniform payload object expected by the handler
---functions.
---@param msg IncomingMessage The message to convert to a payload object.
---@return table payload
local function msg_to_payload(msg)
  ---@type table<string, any>
  local payload = msg.Tags or {}

  payload.From = msg.From

  -- Define 'From' as 'Caller' for semantics
  payload.Caller = msg.From

  -- All quantity values should be handled as bint, so try to do that as soon as
  -- a quantity value is received
  if payload.Quantity ~= nil then
    payload.Quantity = convert
      .value(payload.Quantity)
      .with_failure_message("Could not convert field 'Quantity' to Bint")
      .to_bint()
  end

  -- Keep the original message intact if needed
  payload.__Message = msg

  return payload
end

---Wrapper to shorten `hasMatchingTag` condition call.
---
---@param action string
---@return boolean|fun(message: Message):boolean|"break"|"continue"|"skip"
local function action_is(action)
  return Handlers.utils.hasMatchingTag("Action", action)
end

---Add an action to this process.
---
---@param action string The name of the action that gets passed via `Action = "<action>"`.
---@param fn fun(msg, env) The action's function that gets called.
function mod.add(action, fn)
  if not Handlers then
    runtime.throw("Cannot create handler action. _G['Handlers'] does not exist")
  end

  Handlers.add(action, action_is(action), function(msg, env)
    -- Normalize the payload
    local payload = msg_to_payload(msg or {})
    
    -- Call the handler function with the normalized payload
    local status, err = pcall(function()
      return fn(payload, env)
    end)

    local shouldThrow = false

    if err and not status then
      shouldThrow = true
    end

    if DEBUG_ENABLED == true and shouldThrow then
      print(debug.traceback())
    end

    if SEND_AO_ERROR_MESSAGES == true and shouldThrow then
      ao.send({
        Target = msg.From,
        Action = action,
        ['Message-Id'] = msg.Id,
        Error = err.message
      })
    end

    if shouldThrow then
      error({
        action = action,
        message = err.message or err,
        payload = payload
      }, 2)
    end

    print(status)
  end)
end

return mod
