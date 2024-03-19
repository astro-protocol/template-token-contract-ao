-- /////////////////////////////////////////////////////////////////////////////
-- // FILE MARKER - TABLES ///////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////

-- Extending the STD tables

-- Given a list and a filter function, it returns
-- the only the values of the table for which the
-- filter function return true
---@param list table
---@param filter_fn fun(val: unknown): boolean
---@return table
function table.filter(list, filter_fn)
  local filtered = {}

  for _, value in pairs(list) do
    if filter_fn(value) then
      table.insert(filtered, value)
    end
  end

  return filtered
end

-- Given a list it returns its keys
---@param list table
---@return table
function table.keys(list)
  local keys = {}

  for k in pairs(list) do
    table.insert(keys, k)
  end

  return keys
end

-- Given a list it returns its values
---@param list table
---@return table
function table.values(list)
  local values = {}

  for _, v in pairs(list) do
    table.insert(values, v)
  end

  return values
end

-- Given a list, a reducer function and an optional
-- initial value, it executes the reducer, which
-- handles the currently iterated value, as well
-- as the result of the previous reducer calculation
---@param list table
---@param reducer_fn fun(accumulator: unknown, currentValue: unknown): unknown
---@param initialValue? unknown
---@return unknown
function table.reduce(list, reducer_fn, initialValue)
  local accumulator = initialValue or 0

  for k, v in ipairs(list) do
    if k == 1 and not initialValue then
      accumulator = v
    else
      accumulator = reducer_fn(accumulator, v)
    end
  end

  return accumulator
end

-- Given a finder function, it returns the value
-- of the first table element for which its value
-- matches the finder function result or nil if
-- nothing matched
---@param list table
---@param find_fn fun(val: unknown): boolean
---@return unknown|nil
function table.find(list, find_fn)
  for _, v in ipairs(list) do
    if find_fn(v) then
      return v
    end
  end

  return nil
end

-- Given a value, it returns if a table contains
-- the mentioned value
---@param list table
---@param val unknown
---@return boolean
function table.includes(list, val)
  for _, v in pairs(list) do
    if v == val then return true end
  end

  return false
end

-- Given a table it prints out its content
---@param list table
---@param indentation number?
function table.print(list, indentation)
  if indentation == nil then indentation = 0 end

  if indentation == 0 then
    io.write(string.rep(" ", indentation) .. "{\n")
  end

  for k, v in pairs(list) do
    io.write(
      string.rep(" ", indentation + 2) ..
      tostring(k) ..
      " = "
    )

    if type(v) == "table" then
      if #table.keys(v) == 0 then
        io.write("{}\n")
      else
        io.write("{\n")
        table.print(v, indentation + 2)
      end
    else io.write(tostring(v) .. "\n") end
  end

  io.write(string.rep(" ", indentation) .. "}\n")
end

-- /////////////////////////////////////////////////////////////////////////////
-- // FILE MARKER - TYPE ///////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////

---@class Type
local Type = {
  -- custom name for the defined type
  ---@type string|nil
  name = nil,
  -- list of assertions to perform on any given value
  ---@type { message: string, validate: fun(val: any): boolean }[]
  conditions = nil
}

-- Execute an assertion for a given value
---@param val any Value to assert for
---@param message string? Optional message to throw
---@param no_error boolean? Optionally disable error throwing (will return boolean)
function Type:assert(val, message, no_error)
  for _, condition in ipairs(self.conditions) do
    if not condition.validate(val) then
      if no_error then
        return false
      end
      self:error(message or condition.message)
    end
  end

  if no_error then
    return true
  end
end

-- Add a custom condition/assertion to assert for
---@param message string Error message for the assertion
---@param assertion fun(val: any): boolean Custom assertion function that is asserted with the provided value
function Type:custom(message, assertion)
  -- condition to add
  local condition = {
    message = message,
    validate = assertion
  }

  -- new instance if there are no conditions yet
  if self.conditions == nil then
    local instance = {
      conditions = {}
    }

    table.insert(instance.conditions, condition)
    setmetatable(instance, self)
    self.__index = self

    return instance
  end

  table.insert(self.conditions, condition)
  return self
end

-- Add an assertion for built in types
---@param t "nil"|"number"|"string"|"boolean"|"table"|"function"|"thread"|"userdata" Type to assert for
---@param message string? Optional assertion error message
function Type:type(t, message)
  return self:custom(message or ("Not of type (" .. t .. ")"), function(val)
    return type(val) == t
  end)
end

-- Type must be userdata
---@param message string? Optional assertion error message
function Type:userdata(message)
  return self:type("userdata", message)
end

-- Type must be thread
---@param message string? Optional assertion error message
function Type:thread(message)
  return self:type("thread", message)
end

-- Type must be table
---@param message string? Optional assertion error message
function Type:table(message)
  return self:type("table", message)
end

-- Table's keys must be of type t
---@param t Type Type to assert the keys for
---@param message string? Optional assertion error message
function Type:keys(t, message)
  return self:custom(message or "Invalid table keys", function(val)
    if type(val) ~= "table" then
      return false
    end

    for key, _ in pairs(val) do
      -- check if the assertion throws any errors
      local success = pcall(function()
        return t:assert(key)
      end)

      if not success then
        return false
      end
    end

    return true
  end)
end

-- Type must be array
---@param message string? Optional assertion error message
function Type:array(message)
  return self:table():keys(Type:number(), message)
end

-- Table's values must be of type t
---@param t Type Type to assert the values for
---@param message string? Optional assertion error message
function Type:values(t, message)
  return self:custom(message or "Invalid table values", function(val)
    if type(val) ~= "table" then
      return false
    end

    for _, v in pairs(val) do
      -- check if the assertion throws any errors
      local success = pcall(function()
        return t:assert(v)
      end)

      if not success then
        return false
      end
    end

    return true
  end)
end

-- Type must be boolean
---@param message string? Optional assertion error message
function Type:boolean(message)
  return self:type("boolean", message)
end

-- Type must be function
---@param message string? Optional assertion error message
function Type:_function(message)
  return self:type("function", message)
end

-- Type must be nil
---@param message string? Optional assertion error message
function Type:_nil(message)
  return self:type("nil", message)
end

-- Value must be the same
---@param val any The value the assertion must be made with
---@param message string? Optional assertion error message
function Type:is(val, message)
  return self:custom(message
                       or "Value did not match expected value (Type:is(expected))",
                     function(v)
    return v == val
  end)
end

-- Type must be string
---@param message string? Optional assertion error message
function Type:string(message)
  return self:type("string", message)
end

-- String type must match pattern
---@param pattern string Pattern to match
---@param message string? Optional assertion error message
function Type:match(pattern, message)
  return self:custom(message
                       or ("String did not match pattern \"" .. pattern .. "\""),
                     function(val)
    return string.match(val, pattern) ~= nil
  end)
end

-- String type must be of defined length
---@param len number Required length
---@param match_type? "less"|"greater" String length should be "less" than or "greater" than the defined length. Leave empty for exact match.
---@param message string? Optional assertion error message
function Type:length(len, match_type, message)
  local match_msgs = {
    less = "String length is not less than " .. len,
    greater = "String length is not greater than " .. len,
    default = "String is not of length " .. len
  }

  return self:custom(message or (match_msgs[match_type] or match_msgs.default),
                     function(val)
    local strlen = string.len(val)

    -- validate length
    if match_type == "less" then
      return strlen < len
    elseif match_type == "greater" then
      return strlen > len
    end

    return strlen == len
  end)
end

-- Type must be a number
---@param message string? Optional assertion error message
function Type:number(message)
  return self:type("number", message)
end

-- Number must be an integer (chain after "number()")
---@param message string? Optional assertion error message
function Type:integer(message)
  return self:custom(message or "Number is not an integer", function(val)
    return val % 1 == 0
  end)
end

-- Number must be even (chain after "number()")
---@param message string? Optional assertion error message
function Type:even(message)
  return self:custom(message or "Number is not even", function(val)
    return val % 2 == 0
  end)
end

-- Number must be odd (chain after "number()")
---@param message string? Optional assertion error message
function Type:odd(message)
  return self:custom(message or "Number is not odd", function(val)
    return val % 2 == 1
  end)
end

-- Number must be less than the number "n" (chain after "number()")
---@param n number Number to compare with
---@param message string? Optional assertion error message
function Type:less_than(n, message)
  return self:custom(message or ("Number is not less than " .. n), function(val)
    return val < n
  end)
end

-- Number must be greater than the number "n" (chain after "number()")
---@param n number Number to compare with
---@param message string? Optional assertion error message
function Type:greater_than(n, message)
  return self:custom(message or ("Number is not greater than" .. n),
                     function(val)
    return val > n
  end)
end

-- Make a type optional (allow them to be nil apart from the required type)
---@param t Type Type to assert for if the value is not nil
---@param message string? Optional assertion error message
function Type:optional(t, message)
  return self:custom(message or "Optional type did not match", function(val)
    if val == nil then
      return true
    end

    t:assert(val)
    return true
  end)
end

-- Table must be of object
---@param obj { [any]: Type }
---@param strict? boolean Only allow the defined keys from the object, throw error on other keys (false by default)
---@param message string? Optional assertion error message
function Type:object(obj, strict, message)
  if type(obj) ~= "table" then
    self:error(
      "Invalid object structure provided for object assertion (has to be a table):\n"
        .. tostring(obj))
  end

  return self:custom(message
                       or ("Not of defined object (" .. tostring(obj) .. ")"),
                     function(val)
    if type(val) ~= "table" then
      return false
    end

    -- for each value, validate
    for key, assertion in pairs(obj) do
      if val[key] == nil then
        return false
      end

      -- check if the assertion throws any errors
      local success = pcall(function()
        return assertion:assert(val[key])
      end)

      if not success then
        return false
      end
    end

    -- in strict mode, we do not allow any other keys
    if strict then
      for key, _ in pairs(val) do
        if obj[key] == nil then
          return false
        end
      end
    end

    return true
  end)
end

-- Type has to be either one of the defined assertions
---@param ... Type Type(s) to assert for
function Type:either(...)
  ---@type Type[]
  local assertions = {
    ...
  }

  return self:custom("Neither types matched defined in (Type:either(...))",
                     function(val)
    for _, assertion in ipairs(assertions) do
      if pcall(function()
        return assertion:assert(val)
      end) then
        return true
      end
    end

    return false
  end)
end

-- Type cannot be the defined assertion (tip: for multiple negated assertions, use Type:either(...))
---@param t Type Type to NOT assert for
---@param message string? Optional assertion error message
function Type:is_not(t, message)
  return self:custom(message
                       or "Value incorrectly matched with the assertion provided (Type:is_not())",
                     function(val)
    local success = pcall(function()
      return t:assert(val)
    end)

    return not success
  end)
end

-- Set the name of the custom type
-- This will be used with error logs
---@param name string Name of the type definition
function Type:set_name(name)
  self.name = name
  return self
end

-- Throw an error
---@param message any Message to log
---@private
function Type:error(message)
  error("[Type " .. (self.name or tostring(self.__index)) .. "] "
          .. tostring(message))
end

-- /////////////////////////////////////////////////////////////////////////////
-- // FILE MARKER - LOGGER /////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////

---@alias LogLevel "debug" | "info" | "warn" | "error" | "fatal"

local Logger = {}

---Initialize a logger.
---@param options { level: LogLevel }
---@return table
function Logger.init(options)

  if not options then
    options = {}
  end

  local logger = {
    level = options.level,
    write = print
  }

  ---@type table<LogLevel, number>
  logger.levels = {
    debug = 5,
    info = 4,
    warn = 3,
    error = 2,
    fatal = 1,
    off = 0,
  }

  -- Default to "error" level if no level provided
  if not options.level then
    logger.level = "error"
  end

  -- If the provided level is invalid, then do not log anything
  if not logger.levels[options.level] then
    logger.level = "off"
  end

  ---Can the given level (associated with a message) be logged
  ---@param level LogLevel
  ---@return boolean
  local function canLog(level)
    local logLevel = logger.levels[logger.level]
    local msgLevel = logger.levels[level]

    if msgLevel <= logLevel then
      return true
    end

    return false
  end

  ---Write a message with a log level tag
  ---@param level LogLevel
  local function writeWithLevel(level)

    ---Write log messages of this log level.
    ---@param message string
    ---@param ... string
    local function log(message, ...)
      if not canLog(level) then
        return
      end

      local rest = ... or "";

      if ... ~= nil then
        rest = " " .. rest
      end

      logger.write("[" .. string.upper(level) .. "] " .. (message or "") .. (rest))
    end

    return log
  end

  logger.debug = writeWithLevel("debug")
  logger.info = writeWithLevel("info")
  logger.warn = writeWithLevel("warn")
  logger.error = writeWithLevel("error")
  logger.fatal = writeWithLevel("fatal")

  return logger
end


-- /////////////////////////////////////////////////////////////////////////////
-- // FILE MARKER - VALIDATOR //////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////

---Example Usage
---
---```lua
---local Validator = require "arweave.types.validator"
---
---local validator = Validator:init({
---  types = {
---    Quantity = Type:number("Invalid quantity (must be a number)"),
---    Sender = Type:string("Invalid type for Arweave address (must be string)"),
---  },
---})
---
---
---```
local Validator = {}

---@alias AssertionInterface { assert: fun(...) }

---Initialize a validator.
---@param options { types: table<string, AssertionInterface> }
---@return ValidatorInstance
function Validator:init(options)
  ---@class ValidatorInstance
  local instance = {
    types = options.types -- TODO: options.types should be required
  }

  ---Validate the given value using a type's validation rules.
  ---@param types_key string The key name in the `options.types` rules to use to
  ---get the validation rules for the given value.
  ---@param value any The value to validate.
  ---@return table<string, any>
  function instance:validate_type(types_key, value)
    local assertion = instance.types[types_key]

    if not assertion then
      error("No type assertion found for '" .. types_key .. "' key")
    end

    -- Assert the value's type
    assertion:assert(value)

    return self
  end

  ---Validate and return provided keys and their values from the given `pairs`.
  ---@param obj table<string, any>
  ---@param keys_to_validate nil|string[]
  ---@return table<string, any>
  function instance:validate_types(obj, keys_to_validate)
    local validatedVars = {}

    if keys_to_validate == nil then
      keys_to_validate = table.keys(options.types)
    end

    for _index, key in pairs(keys_to_validate) do
      -- Get the value to assert from the object containing it
      local value = obj[key]

      -- If all good, then add the value to the return variable
      instance.validate_type(self, key, value)

      validatedVars[key] = value
    end

    return validatedVars
  end

  return instance
end


-- /////////////////////////////////////////////////////////////////////////////
-- // FILE MARKER - GLOBAL VARS / VAR DEFS /////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////

if not json then
  local cstatus, cjson = pcall(require, "cjson")

  if cstatus then
    _G.json = cjson
  else
    _G.json = require "json"
  end
end

local hash = {}

---Generate an ID of a given length.
---@param len number (Optional) The length to make the hash. Defaults to 43.
---@return string
function hash.generateId(len)
  local id = ""

  if not len then
    len = 43
  end

  -- possible characters in a valid arweave address
  local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_-"

  while string.len(id) < len do
    -- get random char
    local char = math.random(1, string.len(chars))

    -- select and apply char
    id = id .. string.sub(chars, char, char)
  end

  return id
end

_G.ThisProcessId = ao.id

_G.Providers = {
  hash = hash,
  logger = Logger.init({
    level = "info",
    logger = {
      -- TODO: Use ao when it works
      log = print
    }
  }),
  json = json,
  output = {
    json = function(json_object)
      print(json.encode(json_object))
    end
  }
}

---@class ActionTypeAssertion
---@field field_name string
local ActionTypeAssertion = {}

---@param options { field_name: string, allowed_values: string[] }
function ActionTypeAssertion:create(options)
  self.field_name = options.field_name
  self.allowed_values = options.allowed_values
  self.allowed_values_assertions = {}

  for _i, v in pairs(options.allowed_values) do
    table.insert(self.allowed_values_assertions, Type:is(v))
  end

  return self
end

function ActionTypeAssertion:assert(value)

  for _, assertion in ipairs(self.allowed_values_assertions) do
    if pcall(function()
      return assertion:assert(value)
    end) then
      return true
    end
  end

  error("Field '" .. self.field_name .. "' is invalid. Value provided: " .. (value or "nil") .. ". Value must be one of the following: " .. table.concat(self.allowed_values, ", ") .. ".")
end

local function validate_action_type(value, allowed_values)
  Validator
  :init({
    types = {
      ["Action-Type"] = ActionTypeAssertion:create({
        field_name = "Action-Type",
        allowed_values = allowed_values
      }),
    }
  })
  :validate_type("Action-Type", value)
end

---@alias Msg { Tags: any, From: string }
---Convert handler messages to a uniform payload object expected by the handler
---functions.
---@param msg Msg The message to convert to a payload object.
---@return table payload
local function msg_to_payload(msg)
  local payload = msg.Tags or {}
  payload.From = msg.From

  return payload
end

---Wrapper to shorten `hasMatchingTag` condition call.
local function action_is(action)
  return Handlers.utils.hasMatchingTag("Action", action)
end

---Add an action to this process.
---@param action string The name of the action that gets passed via `Action = "<action>"`.
---@param fn fun(msg, env) The action's function that gets called.
local function add_action(action, fn)
  Handlers.add(action, action_is(action), function(msg, env)
    -- Normalize the payload
    local payload = msg_to_payload(msg or {})
    -- Call the handler function with the normalized payload
    return fn(payload, env)
  end)
end

local function call_action(action, tags)
  ao.send({ Target = ThisProcessId, Action = action, Tags = tags or {} })
end

-- /////////////////////////////////////////////////////////////////////////////
-- // FILE MARKER - TOKEN //////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////

---@alias TokenInfo { Name: string, Ticker: string, Logo: string, Denomination: string }
---@alias TokenBalances table<string, TokenBalance>
---@alias TokenBalance number|nil
local token = {}

---Get info about the token
---@return table TokenInfo about the token
function token.info()
  return {
    Name = Name,
    Ticker = Ticker,
    Logo = Logo or "",
    Denomination = tostring(Denomination)
  }
end

---Get the balance for the given address
---@param address string The address in question.
---@return TokenBalance balance Returns `nil` if the address does not have a
---balance, or the balance if the address has a balance.
function token.balance(address)

  -- Create the validator for this handler
  Validator
    :init({
      types = {
        -- TODO: Unify address assertions
        Address = Type
          :string("Cannot get token balance. Target address must be a string.")
          :length(43, nil, "Cannot get token balance. Target address must be 43 characters.")
          :match("[A-z0-9_-]+", "Cannot get token balance. Target address has invalid characters."),
      }
    })
    :validate_type("Address", address)

  local balance = Balances[address]

  return balance
end


---Get all balances.
---@return Balances Balances
function token.balances()
  if Balances == nil then
    error("_G['Balances'] has not been set")
  end

  return Balances
end

---Get the total supply of funds in this vault.
---@return integer
function token.total_supply()
  if Balances == nil then
    error("_G['Balances'] has not been set")
  end
  
  return table.reduce(
    table.values(Balances),
    function (acc, val) return acc + val end
  ) or 0
end

-- Calculate the integer amount of tokens using the token decimals
-- (balances are stored with the *10^decimals* multiplier)
---@param val number Main unit qty of tokens
---@return number
function token.to_sub_units(val)
  return val * (10 ^ Denomination)
end

---Burn tokens.
---@param target string The target address tokens are being burned from.
---@param quantity number The number of tokens to burn.
function token.burn(target, quantity)
  -- Validate the inputs
  Validator
    :init({
      types = {
        Target = Type
          :string("Cannot burn tokens. Target address must be a string.")
          :length(43, nil, "Cannot burn tokens. Target address must be 43 characters.")
          :match("[A-z0-9_-]+", "Cannot burn tokens. Target address has invalid characters."),
        Quantity = Type:number("Cannot burn tokens. Burn quantity must be a number.")
          :integer("Cannot burn tokens. Burn quantity must be an integer.")
          :greater_than(0, "Cannot burn tokens. Burn quantity must be greater than 0."),
      }
    })
    :validate_type("Target", target)
    :validate_type("Quantity", quantity)

  assert(Balances[target] ~= nil, "No balance for address '" .. target .. "' found")

  -- TODO: Figure out what burning more than the address' balance means. Should
  -- this be a thing? Can an address go negative?
  assert(Balances[target] >= quantity, "Cannot burn more than balance")

  local newBalance = Balances[target] - quantity

  Balances[target] = newBalance
end

---Transfer tokens from one address to another.
---@param sender string The address sending the tokens.
---@param receiver string The address receiving the tokens.
---@param quantity number The amount being sent.
function token.transfer(sender, receiver, quantity)

  local validator = Validator:init({
    types = {
      Sender = Type
        :string("Cannot transfer tokens. Provided 'Sender' address must be a string.")
        :length(43, nil, "Cannot transfer tokens. Provided 'Sender' address must be 43 characters.")
        :match("[A-z0-9_-]+", "Cannot transfer tokens. Provided 'Sender' address has invalid characters."),
      Receiver = Type
        :string("Cannot transfer tokens. Provided 'Receiver' address must be a string.")
        :length(43, nil, "Cannot transfer tokens. Provided 'Receiver' address must be 43 characters.")
        :match("[A-z0-9_-]+", "Cannot transfer tokens. Provided 'Receiver' address has invalid characters."),
      Quantity = Type:number("Cannot transfer tokens. Provided 'Quantity' must be a number.")
        :integer("Cannot transfer tokens. Provided 'Quantity' must be an integer.")
        :greater_than(0, "Cannot transfer tokens. Provided 'Quantity' must be greater than 0."),
    }
  })

  -- Validate addresses
  validator
    :validate_type("Sender", sender)
    :validate_type("Receiver", receiver)

  -- Sender and receiver addresses should be different to prevent minting to the
  -- same address
  assert(sender ~= receiver, "Cannot transfer tokens. Sender address cannot be the same as the Receiver address.")

  validator:validate_type("Quantity", quantity)

  -- Sender should have enough tokens to make the transfer
  assert(Balances[sender] ~= nil, "Cannot transfer tokens. No balance for Sender address '" .. sender .. "' found.")
  assert(Balances[sender] >= quantity, "Cannot transfer tokens. Sender address '" .. sender .."' has insufficient balance.")

  -- move qty
  Balances[receiver] = (Balances[receiver] or 0) + quantity
  Balances[sender] = Balances[sender] - quantity
end

---Mint new tokens.
---@param target string The target address receiving the tokens.
---@param quantity number The number of tokens to mint.
function token.mint(target, quantity)
  -- Validate the inputs
  Validator
    :init({
      types = {
        Target = Type
          :string("Cannot mint tokens. Target address must be a string.")
          :length(43, nil, "Cannot mint tokens. Target address must be 43 characters.")
          :match("[A-z0-9_-]+", "Cannot mint tokens. Target address has invalid characters."),
        Quantity = Type:number("Cannot mint tokens. Mint quantity must be a number.")
          :integer("Cannot mint tokens. Mint quantity must be an integer.")
          :greater_than(0, "Cannot mint tokens. Mint quantity must be greater than 0."),
      }
    })
    :validate_type("Target", target)
    :validate_type("Quantity", quantity)

  -- Create an initial balance for the address if none exists yet
  if Balances[target] == nil then
    Balances[target] = 0
  end

  local newBalance = Balances[target] + quantity

  Balances[target] = newBalance
end

---@alias Balances table<string, number>
---@alias Name string
---@alias Ticker string
---@alias Denomination number
---@alias Logo string
---
---@alias TokenOptions { globals: { Balances: Balances, Name: string, Ticker: string, Denomination: number, Logo?: string } }
---Initialize the token
---@param options TokenOptions
function token.init(options)

  local globals = options.globals

  -- Validate the globals

  Validator
    :init({
      types = {
        Name = Type:string("Field `options.globals.Name` must be a string"),
        Ticker = Type:string("Field `options.globals.Ticker` must be a string"),
        Denomination = Type
          :number("Field `options.globals.Denomination` must be number")
          :integer("Field `options.globals.Denomination` must be integer")
          :greater_than(0, "Field `options.globals.Denomination` must be greater than 0"),
        Balances = Type:custom("Field `options.globals.Balances` must be an key-value pair object", function(v)
          if type(v) == "table" then
            return true
          end

          return false
        end),
      }
    })
    :validate_types(globals)

  if Balances ~= nil then
    error("Cannot initialize token. _G['Balances'] is already defined.")
  end

  if Ticker ~= nil then
    error("Cannot initialize token. _G['Ticker'] is already defined.")
  end

  if Denomination ~= nil then
    error("Cannot initialize token. _G['Denomination'] is already defined.")
  end

  Balances = globals.Balances
  Ticker = globals.Ticker
  Denomination = globals.Denomination

  if Name ~= globals.Name then
    Name = globals.Name
  end

  if globals.Logo ~= nil then
    Logo = globals.Logo
  end
end

-- /////////////////////////////////////////////////////////////////////////////
-- // FILE MARKER - PROPOSALS //////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////

local Proposals = {}

---Types:
---@alias Proposals { burn_requests: table<string, table<string, BurnRequest>> }
---@alias ProposalOptions { burners: string[], minters: string[], required_burn_approvals: number, required_mint_approvals: number, required_burn_approvals: number }

---Initialize proposals
---@param options ProposalOptions
function Proposals.init(options)
  local mod = {
    members = {
      burners = options.burners,
      minters = options.minters,
    },
    proposals = {
      burn_requests = {},
      mint_requests = {},
    },
    requirements = {
      required_burn_approvals = options.required_burn_approvals,
      required_mint_approvals = options.required_mint_approvals,
    },
  }

  ---@alias BurnRequest { id: string, requestor: string, quantity: number, approvals: table<string, string>, approved: boolean }
  ---@param requestor string
  ---@param quantity number
  ---@return BurnRequest
  function mod.create_burn_request(requestor, quantity)
    return {
      id = Providers.hash.generateId(),
      requestor = requestor,
      quantity = quantity,
      approvals = {},
      approved = false
    }
  end
  
  ---Get a burn request
  ---@param proposal_type "burn" | "mint"
  ---@param requestor string The requestor's address
  ---@param id string The burn request's ID
  ---@return BurnRequest|nil
  function mod.get_proposal(proposal_type, requestor, id)
    local fieldName = proposal_type .. "_requests"
    return mod.proposals[fieldName][requestor][id]
  end

    ---Can the given address burn tokens?
  ---@param address string The address in question.
  ---@return boolean
  function mod.can_burn(address)
    local approver = nil
  
    for k, approverAddress in pairs(mod.members.burners) do
      if address == approverAddress then
        approver = approverAddress
        break
      end
    end
  
    assert(approver ~= nil, "Address '" .. address .. "' unauthorized to burn tokens")
  
    return true
  end
  
  ---Can the given address mint tokens?
  ---@param address string The address in question.
  ---@return boolean
  function mod.can_mint(address)
    local approver = nil
  
    for k, approverAddress in pairs(mod.members.minters) do
      if address == approverAddress then
        approver = approverAddress
        break
      end
    end
  
    assert(approver ~= nil, "Address '" .. address .. "' unauthorized to mint tokens")
  
    return true
  end
  
  ---Add a new burn proposal
  ---@param requestor string The address making the request.
  ---@param quantity number The amount of funds to burn.
  function mod.add_burn_request(requestor, quantity)
    local validator = Validator:init({
      types = {
        Requestor = Type
          :string("Cannot add Burn request. Burn request 'Requestor' address must be a string.")
          :length(43, nil, "Cannot add Burn request. Burn request 'Requestor' address must be 43 characters.")
          :match("[A-z0-9_-]+", "Cannot add Burn request. Burn request 'Requestor' address has invalid characters."),
        Quantity = Type:number("Cannot add Burn request. Burn request 'Quantity' must be a number.")
          :integer("Cannot add Burn request. Burn request 'Quantity' must be an integer.")
          :greater_than(0, "Cannot add Burn request. Burn request 'Quantity' must be greater than 0."),
      }
    })

    validator:validate_types({
      Requestor = requestor,
      Quantity = quantity,
    }, {
      "Quantity",
      "Requestor",
    })
  
    -- TODO: Burn approvers need a separate authority
    local _, canBurn = pcall(function()
      mod.can_burn(requestor)
    end)
  
    if canBurn == true then
      assert("[Not Implemented] Burn approvers cannot burn their own tokens")
    end
  
    -- Create storage for the requestor if needed
    if not mod.proposals.burn_requests[requestor] then
      mod.proposals.burn_requests[requestor] = {}
    end
  
    local request = mod.create_burn_request(requestor, quantity)
  
    mod.proposals.burn_requests[requestor][request.id] = request
  
    return request
  end
  
  ---Approve a burn request
  ---@param approver string The address assigned to approve the burn requet.
  ---@param requestor string The address requesting the burn request.
  ---@param burn_request_id string The burn request's assigned ID.
  function mod.approve_burn_request(approver, requestor, burn_request_id)
  
    mod.can_burn(approver) -- Errors if approver cannot burn
  
    local exists = mod.proposals.burn_requests[requestor][burn_request_id]
  
    assert(exists ~= nil, "Burn request with ID '" .. burn_request_id .. "' does not exist for address '" .. requestor .. "' ")
  
    -- Add the approver's address to the burn request
    local approvalsLen = #mod.proposals.burn_requests[requestor][burn_request_id].approvals+1
  
    mod.proposals.burn_requests[requestor][burn_request_id].approvals[approvalsLen] = approver;
  
    -- Update the burn request if it has the required number of approvals
    local numApprovals = #mod.proposals.burn_requests[requestor][burn_request_id].approvals
    if numApprovals >= mod.requirements.required_burn_approvals then
      mod.proposals.burn_requests[requestor][burn_request_id].approved = true
    end
  end

  return mod
end

-- /////////////////////////////////////////////////////////////////////////////
-- // FILE MARKER - TRANSFERS //////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////

local transfers = {}

function transfers.add_external_targets(targets)
  if not AuthorizedExternalTargets then
    AuthorizedExternalTargets = {}
  end

  for _index, target in pairs(targets) do
    AuthorizedExternalTargets[target] = target
  end
end

function transfers.remove_external_targets(targets)
  if not AuthorizedExternalTargets then
    AuthorizedExternalTargets = {}
  end

  for _index, target in pairs(targets) do
    AuthorizedExternalTargets[target] = nil
  end
end

---Transfer funds from one adddress in this process to address in another
---process.
---@param sender string The address sending the funds.
---@param receiver string The address receiving the funds.
---@param process string The ID of the process holding a balance for the
---receiver.
---@param quantity number The amount being sent.
function transfers.transfer_externally(sender, receiver, process, quantity)

  -- Check if the target is authorized to receive transfers from this process
  local authResult = table.find(
    AuthorizedExternalTargets,
    function (val)
      return val == process
    end
  )

  assert(authResult ~= nil, "Process '" .. process .. "' not authorized to receive transfers")

  local validator = Validator:init({
    types = {
      Sender = Type
        :string("Cannot process external transfer. Transfer 'Sender' address must be a string.")
        :length(43, nil, "Cannot process external transfer. Transfer 'Sender' address must be 43 characters.")
        :match("[A-z0-9_-]+", "Cannot process external transfer. Transfer 'Sender' address has invalid characters."),
      Receiver = Type
        :string("Cannot process external transfer. Transfer 'Receiver' address must be a string.")
        :length(43, nil, "Cannot process external transfer. Transfer 'Receiver' address must be 43 characters.")
        :match("[A-z0-9_-]+", "Cannot process external transfer. Transfer 'Receiver' address has invalid characters."),
      Process = Type
        :string("Cannot process external transfer. Transfer 'Process' must be a string."),
      Quantity = Type:number("Cannot process external transfer. Tranfser 'Quantity' must be a number.")
        :integer("Cannot process external transfer. Tranfser 'Quantity' must be an integer.")
        :greater_than(0, "Cannot process external transfer. Tranfser 'Quantity' must be greater than 0."),
    }
  })

  -- Validate addresses
  validator
    :validate_type("Sender", sender)
    :validate_type("Receiver", receiver)
    :validate_type("Quantity", quantity)
    :validate_type("Process", process)

  -- validate if the user has enough tokens
  assert(Balances[sender] ~= nil, "Cannot process external transfer. No balance for address '" .. sender .. "' found.")
  assert(Balances[sender] >= quantity, "Cannot process external transfer. Sender address '" .. sender .."' has insufficient balance.")

  Balances[sender] = Balances[sender] - quantity
end

---Types
---@alias TransferOptions { authorized_external_targets: string[] }

---Initialize transfers
---
--- Globals
---
--- - AuthorizedExternalTargets - A list of addresses that this process can transfer tokens to
---
---@param options TransferOptions
function transfers.init(options)
  transfers.add_external_targets(options.authorized_external_targets or {})
end

-- /////////////////////////////////////////////////////////////////////////////
-- // FILE MARKER - VAULT //////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////

---@class VaultItem
---@field id string
---@field type string
---@field owner string
---@field status "locked" | "unlocked"
---@field items any
---@field date_created integer
---@field date_deleted nil|integer
local VaultItem = {}

---@class CurrencyItem : VaultItem
---@field type "currency"

---@class KV
local KV = {}

function KV:create()
  ---@class KVInstance
  ---@field private storage table<string, VaultItem[]>
  local instance = {
    storage = {}
  }

  ---Generate a unique ID for the given item.
  ---@param item VaultItem
  ---@return string
  local function unique_id(item)
    local time = os.time()
    local id = Providers.hash.generateId() .. ":" .. time

    while instance.storage[item.owner][id] ~= nil do
      id = Providers.hash.generateId() .. ":" .. time
    end

    return id
  end

  ---Add a currency item to the vault.
  ---@param item { owner: string, quantity: number, currency_id: string, status: nil | "locked" | "unlocked" } The currency item in question.
  ---@return VaultItem
  function instance:add_currency_item(item)
    local owner = item.owner

    local storage = self.storage[owner]

    -- Ensure the owner has storage
    if storage == nil then
      self.storage[owner] = {}
    end

    local id = unique_id(item)

    ---@type CurrencyItem
    local currencyItem = {
      id = id,
      type = "currency",
      quantity = item.quantity,
      currency_id = item.currency_id,
      date_created = os.time(),
      date_deleted = nil,
    }

    self.storage[owner][id] = currencyItem

    return self.storage[owner][id]
  end

  ---Get an item from the vault associated with the given owner and ID.
  ---@param owner string The vault item's owner address.
  ---@param id string The vault item's ID (assigned when it was created).
  ---@return VaultItem
  function instance:get_item(owner, id)
    local vault = self.storage[owner]

    if vault == nil then
      error("Owner '" .. owner .. "' does not have any vault items")
    end

    local items = #table.keys(vault)

    if items <= 0 then
      error("Owner '" .. owner .. "' does not have any vault items")
    end

    local item = vault[id]

    if item == nil then
      error("Owner '" .. owner .. "' does not have a vault item with ID '" .. id .. "'")
    end

    return item
  end
  
  return instance
end

_G.Vault = KV:create()


-- /////////////////////////////////////////////////////////////////////////////
-- // FILE MARKER - EMIT ///////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////

local emit = {}

---Send the token info.
---@param to string The address this message is being sent to.
---@param info Info The token info.
function emit.info(to, info)
  ao.send({
    Target = to,
    Tags = info
  })
end

---Send the balance of the given balance address.
---@param to string The address this message is being sent to.
---@param balance_address string The address the balance belongs to.
---@param balance nil|number The balance in question.
---@param ticker string The coin's ticker symbol (e.g., "AR" for Arweave).
function emit.balance(to, balance_address, balance, ticker)
  ao.send({
    Target = to,
    Data = tostring(balance),
    Tags = {
      Balance = tostring(balance),
      Target = balance_address,
      Ticker = ticker,
    }
  })
end

---Send all of the balances.
---@param to string The address this message is being sent to.
---@param balances table<string, number> All of the balances in this process.
function emit.balances(to, balances)
  ao.send({
    Target = to,
    Data = json.encode(balances),
  })
end

---Send Debit-Notice Action to a Target
---@param to string
---@param debited_from string
---@param quantity string
function emit.debit_notice(to, debited_from, quantity)
  ao.send({
    Target = to,
    Tags = {
      Action = "Debit-Notice",
      Target = debited_from,
      Quantity = quantity
    }
  })
end

---Send a Burn-Request-Notice Action to a Target
---@param requestId string A unique request ID for this requestors request
---@param requestor string The address requesting to burn its tokens
---@param approvers string[] The addresses where the notice is being sent to
---@param quantity string The amount of tokens the requestor wants to burn
function emit.burn_request_notice(requestId, requestor, approvers, quantity)
  for _index, approverAddress in pairs(approvers) do
    ao.send({
      Target = ThisProcessId,
      Tags = {
        Approver = approverAddress,
        Action = "Burn-Request-Notice",
        ["Burn-Request-Id"] = requestId,
        Requestor = requestor,
        Quantity = quantity
      }
    })
  end
end

---Send a Credit-Notice Action to a Target
---@param to string
---@param credited_to string
---@param quantity string
function emit.credit_notice(to, credited_to, quantity)
  ao.send({
    Target = to,
    Tags = {
      Action = "Credit-Notice",
      Target = credited_to,
      Quantity = quantity
    }
  })
end

-- /////////////////////////////////////////////////////////////////////////////
-- // HANNDLER FUNCTIONS ///////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////
-- //
-- // These handler functions are not written with the ao handler defintions
-- // so they can be reused if needed.
-- //

local handlers = {}

---@alias BurnRequestPayload { Requestor: string, Quantity: number }
---Create a new Burn request
---@param payload BurnRequestPayload
function handlers.create_new_burn_request(payload)

  -- Create the validator for this handler
  local validator = Validator:init({
    types = {
      Requestor = Type
        :string("Cannot create Burn request. Field 'Requestor' must be a string.")
        :length(43, nil, "Cannot create Burn request. Field 'Requestor' must be 43 characters.")
        :match("[A-z0-9_-]+", "Cannot create Burn request. Field 'Requestor' has invalid characters."),
      Quantity = Type:number("Cannot create Burn request. Burn request 'Quantity' must be a number.")
        :integer("Cannot create Burn request. Burn request 'Quantity' must be an integer.")
        :greater_than(0, "Cannot create Burn request. Burn request 'Quantity' must be greater than 0."),
    }
  })

  -- Validate the payload
  ---@type BurnRequestPayload
  local valid = validator:validate_types(payload, {
    "Requestor",
    "Quantity",
  })

  local request = Providers.proposals.add_burn_request(valid.Requestor, valid.Quantity)

  -- Notify the approvers
  emit.burn_request_notice(
    request.id,
    request.requestor,
    Providers.proposals.members.burners,
    tostring(request.quantity)
  )
end

---@alias BurnApprovalPayload { From: string, Requestor: string, ["Burn-Request-Id"]: string }
---Handle a burn approval.
---@param payload BurnApprovalPayload
function handlers.handle_burn_approval(payload)

  -- Create the validator for this handler
  local validator = Validator:init({
    types = {
      From = Type:type("string", "Cannot process burn approval. Field 'From' must be a string.")
        :length(43, nil, "Cannot process burn approval. Field 'From' must be 43 characters.")
        :match("[A-z0-9_-]+", "Cannot process burn approval. Field 'From' contains invalid characters (only A-Z, a-z, 0-9, _, and - are allowed)."),
      ["Burn-Request-Id"] = Type:type("string", "'Burn-Request-Id' must be a string"),
      Requestor = Type:type("string", "Cannot process burn approval. Field 'Requestor' must be a string.")
        :length(43, nil, "Cannot process burn approval. Field 'Requestor' must be 43 characters.")
        :match("[A-z0-9_-]+", "Cannot process burn approval. Field 'Requestor' contains invalid characters (only A-Z, a-z, 0-9, _, and - are allowed)."),
    }
  })

  -- Validate the payload
  ---@type BurnApprovalPayload
  local valid = validator:validate_types(payload, {
    "From",
    "Burn-Request-Id",
    "Requestor",
  })

  -- TODO: Burners should have different approval authorities
  Providers.proposals.approve_burn_request(
    valid.From,
    valid.Requestor,
    valid["Burn-Request-Id"]
  )

  local request = Providers.proposals.get_proposal("burn", valid.Requestor, valid["Burn-Request-Id"])

  assert(request ~= nil, "Could not find burn request with ID '" .. valid["Burn-Request-Id"] .. "'")

  -- Burn the tokens if all approvals are present
  if request.approved then
    local requestor = request.requestor
    token.burn(requestor, request.quantity)
    emit.debit_notice(ThisProcessId, requestor, tostring(request.quantity))
    Providers.logger.info("Burned " .. tostring(request.quantity) .. " " .. Ticker .. " from address '" .. requestor .. "'")
  end
end

---@alias MintPayload { From: string, Target: string, Quantity: number }
---Mint new coins (aka increase the supply)
---@param payload MintPayload
function handlers.mint(payload)

  -- Create the validator for this handler
  local validator = Validator:init({
    types = {
      From = Type:string("Cannot mint tokens. Field 'From' must be a string.")
        :length(43, nil, "Cannot mint tokens. Field 'From' must be 43 characters.")
        :match("[A-z0-9_-]+", "Cannot mint tokens. Field 'From' contains invalid characters (only A-Z, a-z, 0-9, _, and - are allowed)."),
    }
  })

  -- Validate the payload
  ---@type MintPayload
  local valid = validator:validate_types(payload, {
    "From",
  })

  -- Errors out if the caller cannot mint
  Providers.proposals.can_mint(valid.From)

  token.mint(payload.Target, payload.Quantity)
end

---@alias TransferInternalPayload { Sender: string, Receiver: string, Quantity: number }
---Handle internal transfers. That is, transfer funds between addresses that are
---only in this process.
---@param payload TransferInternalPayload
function handlers.handle_transfer_internally(payload)
  token.transfer(payload.Sender, payload.Receiver, payload.Quantity)
  emit.debit_notice(ThisProcessId, payload.Sender, tostring(payload.Quantity))
  emit.credit_notice(ThisProcessId, payload.Receiver, tostring(payload.Quantity))
  Providers.logger.info("Transferred " .. tostring(payload.Quantity) .. " " .. Ticker .. " from '" .. payload.Sender.. "' to receiver '" .. payload.Receiver .. "'")
end

---TODO
---@alias TransferExternalPayload { Sender: string, Receiver: string, Quantity: number, Process: string }
---Transfer tokens externally. That is, transfer funds from one address in this
---process to another address in another process.
---@param payload TransferExternalPayload
function handlers.handle_transfer_externally(payload)
  transfers.transfer_externally(payload.Sender, payload.Receiver, payload.Process, payload.Quantity)
  Providers.logger.info("Transferred " .. tostring(payload.Quantity) .. " " .. Ticker .. " from '" .. payload.Sender .."' to process '" .. payload.Process .. "' and receiver '" .. payload.Receiver .. "'")
end

---@alias BalancePayload { From: string, Target: string }
---@param payload BalancePayload
function handlers.balance(payload)

  -- Create the validator for this handler
  local validator = Validator:init({
    types = {
      From = Type
        :string("Cannot get balance. Field 'From' must be a string.")
        :length(43, nil, "Cannot get balance. Field 'From' must be 43 characters.")
        :match("[A-z0-9_-]+", "Cannot get balance. Field 'From' has invalid characters."),
      Target = Type
        :string("Cannot get balance. Balance 'Target' must be a string.")
        :length(43, nil, "Cannot get balance. Balance 'Target' must be 43 characters.")
        :match("[A-z0-9_-]+", "Cannot get balance. Balance 'Target' has invalid characters."),
    }
  })

  -- Validate the payload
  ---@type BalancePayload
  local valid = validator:validate_types(payload, {
    "Target",
    "From",
  })


  local bal = token.balance(valid.Target)

  emit.balance(valid.From, valid.Target, bal, Ticker)

  Providers.output.json({
    Target = valid.Target,
    Balance = tostring(bal),
    Ticker = Ticker,
  })
end

---@alias InfoPayload { From: string }
---@alias Info { Balances: Balances, Ticker: Ticker, Name: Name, Denomination: Denomination }
function handlers.info(payload)
  local tokenInfo = token.info()
  emit.info(payload.From, tokenInfo)
  Providers.output.json(tokenInfo)
end

---@alias BalancesPayload { From: string }
function handlers.balances(payload)
  local balances = token.balances()
  emit.balances(payload.From, balances)
  Providers.output.json(balances)
end

-- /////////////////////////////////////////////////////////////////////////////
-- // FILE MARKER - ACTIONS ////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////


add_action("Balance", function(payload)
  -- If Target is not provided, then return the sender's balance
  if payload.Target == nil then
    payload.Target = payload.From
  end

  return handlers.balance(payload)
end)


add_action("Balances", function(payload)
  return handlers.balances(payload)
end)

add_action("Burn", function(payload)
  -- We are assuming the payload has a `Quantity` field
  payload.Quantity = tonumber(payload.Quantity)

  -- We are assuming the payload has an `Action-Type` field
  local actionType = payload["Action-Type"] or "NEW_REQUEST"

  -- Validate the action type so we know where to delegate the action to
  validate_action_type(actionType, { "NEW_REQUEST", "APPROVAL" })

  -- Withdrawal approvers will call this same `Action = "Withdraw"` handler,
  -- but must provide `["Action-Type"] = "APPROVAL"` denoting they want to
  -- withdrawal requests
  if actionType == "APPROVAL" then
    handlers.handle_burn_approval(payload)
    return
  end

  -- Default to creating a new withdrawal request
  handlers.create_new_burn_request(payload)
end)

add_action("Mint", function(payload)
  -- We are assuming the payload has a `Quantity` field
  payload.Quantity = tonumber(payload.Quantity)

  return handlers.mint(payload)
end)

add_action("Info", function(payload)
  return handlers.info(payload)
end)

add_action("Transfer", function(payload)
  -- We are assuming the payload has a `Quantity` field
  payload.Quantity = tonumber(payload.Quantity)

  -- We are assuming the payload has an `Action-Type` field
  local actionType = payload["Action-Type"] or "INTERNAL"

  -- Validate the action type so we know where to delegate the action to
  validate_action_type(actionType, { "INTERNAL", "EXTERNAL" })

  if actionType == "EXTERNAL" then
    handlers.handle_transfer_externally(payload)
  end

  -- Default action
  if actionType == "INTERNAL" then
    handlers.handle_transfer_internally(payload)
    return
  end
end)

add_action("Reset", function()
  Balances = nil
  Denomination = nil
  Name = nil
  Ticker = nil

  Providers.output.json({
    Balances = Balances or "nil",
    Denomination = Denomination or "nil",
    Name = Name or "nil",
    Ticker = Ticker or "nil"
  })
end)

add_action("Test-All", function()
  -- Should result in 20 tokens for this process
  handlers.mint({
    From = ThisProcessId,
    Target = ThisProcessId,
    Quantity = 20,
  })

  handlers.create_new_burn_request({
    Requestor = ThisProcessId,
    Quantity = 1,
  })

  handlers.balance({ Address = ThisProcessId })

  handlers.balances()

  handlers.info()

  -- Should result in 18 tokens for this process
  -- Shoudl result in 2 tokens for the Receiver address
  handlers.handle_transfer_internally({
    Sender = ThisProcessId,
    Receiver = "p55NAQO-m8zmssDIn6m4naZBbUlPxYfk_SSFEohhvCs",
    Quantity = 2,
  })
end)

-- /////////////////////////////////////////////////////////////////////////////
-- // FILE MARKER - OWNER-ONLY HANDLER CALLS ///////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////
-- 
-- The calls below can only be used by the owner of this contract. They exist to
-- help development, testing, and debugging efforts by shortening time it takes
-- to call actions in this contract.
--
-- THESE CALLS SHOULD BE REMOVED IN MAINNET ENVIRONMENTS SINCE THEY ARE ONLY
-- INTENDED TO BE USED DURING DEVELOPMENT, TESTING, AND DEBUGGING.
--

_G.Call = {}

function _G.Call.Balance(address)
  call_action("Balance", { Address = address })
end

function _G.Call.Balances()
  call_action("Balances")
end

function _G.Call.Burn(target, quantity)
  call_action("Burn", { Target = target, Quantity = quantity })
end
function _G.Call.Info()
  call_action("Info")
end

function _G.Call.Mint(target, quantity)
  call_action("Mint", { Target = target, Quantity = quantity })
end

function _G.Call.Transfer(sender, receiver, quantity, process)

  -- If a process was provided, then the transfer is intended to go to an
  -- external process, so we specify and use the EXTERNAL transfer flow.
  if process ~= nil then
    call_action("Transfer", {
      ["Action-Type"] = "EXTERNAL",
      Sender = sender,
      Receiver = receiver,
      Process = process,
      Quantity = quantity
    })

    return
  end

  -- If a process is not provided, then we default to internal transfers
  call_action("Transfer", {
    ["Action-Type"] = "INTERNAL",
    Sender = sender,
    Receiver = receiver,
    Quantity = quantity
  })
end

function _G.Call.Reset()
  call_action("Reset")
end

-- /////////////////////////////////////////////////////////////////////////////
-- // FILE MARKER - INIT ///////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////

token.init({
  globals = {
    Name = "",
    Ticker = "",
    Balances = {},
    Denomination = 12,
  }
})

transfers.init({
  authorized_external_targets = {
  }
})

Providers.proposals = Proposals.init({
  burners = {
  },
  minters = {
  },
  required_burn_approvals = 1,
  required_mint_approvals = 1,
})

