local assertions = require "src.assertions"
local aolibs = require "src.aolibs"
local Type = require "arweave.types.type"
local Validator = require "arweave.types.validator"
local runtime = require "src.runtime"

local bint = aolibs.bint
local json = aolibs.json

---Globals set by this module
---
---@alias Balances table<string, Bint>
---@alias Name string
---@alias Ticker string
---@alias Denomination number
---@alias Logo string

local mod = {}

local balances = {}

---Initialize a token.
---
---@alias TokenOptions { globals: { Balances: Balances, Name: string, Ticker: string, Denomination: number, Logo?: string } }
---
---@param options TokenOptions
---@returns TokenInstance
function mod:init(options)

  local globals = options.globals or {}

  ---@class TokenInstance
  local instance = {}

  -- Validate the globals

  Validator
    :init({
      types = {
        Name = Type:string("Cannot create token. Field `options.globals.Name` must be a string"),
        Ticker = Type:string("Cannot create token. Field `options.globals.Ticker` must be a string"),
        Denomination = Type
          :number("Cannot create token. Field `options.globals.Denomination` must be number")
          :integer("Cannot create token. Field `options.globals.Denomination` must be integer")
          :greater_than(0, "Cannot create token. Field `options.globals.Denomination` must be greater than 0"),
        Balances = Type:custom("Cannot create token. Field `options.globals.Balances` must be of type table<string, string>", function(v)
          if type(v) == "table" then
            return true
          end

          return false
        end),
      }
    })
    :validate_types(globals)

  Balances = Balances or globals.Balances
  Ticker = Ticker or globals.Ticker
  Denomination = Denomination or globals.Denomination

  if Name ~= globals.Name then
    Name = globals.Name
  end

  if globals.Logo ~= nil then
    Logo = globals.Logo
  end

  ---@alias TokenInfo { Name: string, Ticker: string, Logo: string, Denomination: string }
  ---
  ---Get info about the token.
  ---
  ---@return TokenInfo TokenInfo Info about the token.
  function instance:info()
    return {
      Name = Name,
      Ticker = Ticker,
      Logo = Logo or "",
      Denomination = tostring(Denomination)
    }
  end

  ---Get the balance for the given address
  ---
  ---@param address string The address in question.
  ---@return Bint|nil balance Returns `nil` if the address does not have a
  ---balance, or the balance if the address has a balance.
  function instance:balance(address)

    -- Create the validator for this handler
    Validator
      :init({
        types = {
          Address = Type:string("Cannot get token balance. Target address must be a string.")
        }
      })
      :validate_type("Address", address)

    local ret = Balances[address]

    return ret
  end

  ---Get all balances.
  ---
  ---@return Balances Balances
  function instance:balances()
    return Balances or {}
  end

  ---Get the total supply of funds in this vault.
  ---
  ---@return integer
  function instance:total_supply()
    local balances = Balances or {}

    local total = bint("0")

    for _i, value in ipairs(balances) do
      ---@cast value Bint
      ---Disabling next line because `__add` exists on `bint`
      ---@diagnostic disable-next-line
      total = bint.__add(total, value)
    end

    return total
  end

  ---Calculate the integer amount of tokens using the token decimals
  ---(balances are stored with the *10^decimals* multiplier)
  ---
  ---@param val number Main unit qty of tokens
  ---@return number
  function instance:to_sub_units(val)
    return val * (10 ^ Denomination)
  end

  ---Burn tokens.
  ---
  ---@param target string The target address tokens are being burned from.
  ---@param quantity Bint The number of tokens to burn.
  ---@return { balance_old: Bint, balance_new: Bint }
  function instance:burn(target, quantity)
    -- Validate the inputs
    Validator
      :init({
        types = {
          Target = Type:string("Cannot burn tokens. Target address must be a string."),
        }
      })
      :validate_type("Target", target)

    assertions.is_bint(quantity, "Cannot burn tokens. Quantity must be of type Bint.")

    local bintTargetBalance = Balances[target]
      
    -- Target should exist
    assertions.is_not_nil(bintTargetBalance, "Cannot burn tokens. No balance for address '" .. target .. "' found.")
      
    -- Target should have enough tokens to burn
    assert(bintTargetBalance >= quantity, "Cannot burn " .. tostring(quantity) .. " " .. Ticker .. ". Target address '" .. target .."' has insufficient balance: " .. tostring(bintTargetBalance) .. ".")

    -- Track the current balance of the target

    local balanceOld = Balances[target]

    -- Decrease the balance for the target

    ---Disabling next line because `__sub` exists on `bint`
    ---@diagnostic disable-next-line
    Balances[target] = bint.__sub(Balances[target], quantity)

    return {
      balance_old = balanceOld,
      balance_new = Balances[target],
    }
  end

  ---Transfer tokens from one address to another.
  ---
  ---@param sender string The address sending the tokens.
  ---@param recipient string The address receiving the tokens.
  ---@param quantity Bint The amount being sent.
  ---@returns { recipient_balance_new: string; recipient_balance_old: string; sender_balance_new: string; sender_balance_old: string; }
  function instance:transfer(sender, recipient, quantity)
    Validator
      :init({
        types = {
          Sender = Type:string("Cannot mint tokens. Target address must be a string."),
          Recipient = Type:string("Cannot mint tokens. Target address must be a string."),
        }
      })
      :validate_type("Sender", sender)
      :validate_type("Recipient", recipient)

    -- From and receiver addresses should be different to prevent minting to the
    -- same address
    assertions.is_not_same(sender, recipient, "Cannot transfer tokens. From address cannot be the same as the Recipient address.")

    assertions.is_bint(quantity, "Cannot mint tokens. Quantity must be of type Bint.")

    -- From should have enough tokens to make the transfer
    assertions.is_not_nil(Balances[sender], "Cannot transfer tokens. No balance for From address '" .. sender .. "' found.")

    local bintSenderBalance = Balances[sender]

    ---Disabling next line because `__le` exists on `bint`
    ---@diagnostic disable-next-line
    if bint.__lt(bintSenderBalance, quantity) then
      runtime.throw("Cannot transfer tokens. From address '" .. sender .."' has insufficient balance.")
    end

    -- Ensure the recipient has a balance

    Balances[recipient] = Balances[recipient] or bint("0")

    -- Track the current balances for participants

    local senderBalanceOld = Balances[sender]
    local recipientBalanceOld = Balances[recipient]

    -- Increase the balance for the recipient

    ---Disabling next line because `__add` exists on `bint`
    ---@diagnostic disable-next-line
    Balances[recipient] = bint.__add(Balances[recipient], quantity)

    -- Decrease the balance for the sender

    ---Disabling next line because `__add` exists on `bint`
    ---@diagnostic disable-next-line
    Balances[sender] = bint.__sub( Balances[sender], quantity)

    -- Send the information that was mutated to the caller

    return {
      recipient_balance_new = Balances[recipient],
      recipient_balance_old = recipientBalanceOld,
      sender_balance_new = Balances[sender],
      sender_balance_old = senderBalanceOld,
    }
  end

  ---Mint new tokens.
  ---
  ---@param target string The target address receiving the tokens.
  ---@param quantity Bint The number of tokens to mint.
  ---@return { balance_old: Bint, balance_new: Bint }
  function instance:mint(target, quantity)
    Validator
      :init({
        types = {
          Target = Type:string("Cannot mint tokens. Target address must be a string."),
        }
      })
      :validate_type("Target", target)

    assertions.is_bint(quantity, "Cannot mint tokens. Quantity must be of type bint.")

    -- Ensure the target has a balance

    Balances[target] = Balances[target] or bint("0")

    -- Track the current balance of the target

    local balanceOld = Balances[target]

    -- Increase the balance for the target

    ---Disabling next line because `__add` exists on `bint`
    ---@diagnostic disable-next-line
    Balances[target] = bint.__add(Balances[target], quantity)

    return {
      balance_old = balanceOld,
      balance_new = Balances[target],
    }
  end

  return instance

end

return mod