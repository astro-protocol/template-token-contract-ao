local actions = require "src.actions"
local aolibs = require "src.aolibs"
local emit = require "src.emit"
local logger = require "src.logger"
local output = require "src.output"
local Token = require "src.token"

local json = aolibs.json

local token = Token:init({
  globals = {
    Name = "",
    Ticker = "",
    Balances = {},
    Denomination = 12,
  }
})

THIS_PROCESS_ID = ao.id

-- /////////////////////////////////////////////////////////////////////////////
-- // HANNDLER FUNCTIONS ///////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////
-- //
-- // These handler functions are not written with the ao handler defintions
-- // so they can be reused if needed.
-- //

local handlers = {}

---@alias BurnPayload { Caller: string; Quantity: Bint }
---@param payload BurnPayload
---@return { balance_old: Bint, balance_new: Bint }
function handlers.burn_tokens(payload)
  return token:burn(payload.Caller, payload.Quantity)
end

---@alias BalancePayload { Caller: string, Target: string }
---@param payload BalancePayload
---@return Bint|nil
function handlers.get_token_balance(payload)

  -- If Target is not provided, then return the sender's balance
  if payload.Target == nil then
    payload.Target = payload.Caller
  end

  return token:balance(payload.Target)
end

---@alias BalancesPayload { Caller: string }
---@param payload BalancesPayload
---@return table<string, Bint> Balances The balances table.
function handlers.get_token_balances(payload)
  return token:balances()
end

function handlers.get_token_info()
  return token:info()
end

---@alias MintPayload { Caller: string; Target: string, Quantity: Bint }
---@param payload MintPayload
---@return { balance_old: Bint, balance_new: Bint }
function handlers.mint_tokens(payload)
  return token:mint(payload.Target, payload.Quantity)
end

---@alias TransferPayload { Caller: string, Recipient: string, Quantity: Bint }
---@param payload TransferPayload
function handlers.transfer_tokens(payload)
  return token:transfer(payload.Caller, payload.Recipient, payload.Quantity)
end

-- /////////////////////////////////////////////////////////////////////////////
-- // FILE MARKER - ACTIONS ////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////

---@param payload BalancePayload
actions.add("Balance", function(payload)
  local balance = handlers.get_token_balance(payload)

  local balanceAsString = tostring(balance or "nil") -- should this be nil?

  emit.token_balance(payload.Caller, payload.Target, balanceAsString, Ticker)

  output.json({ Target = payload.Target, Balance = balance, Ticker = Ticker })
end)

---@param payload BalancesPayload
actions.add("Balances", function(payload)
  local balances = handlers.get_token_balances(payload) or {}

  emit.token_balances(payload.Caller, json.encode(balances))
  
  output.json(balances)
end)

---@param payload BurnPayload
actions.add("Burn", function(payload)
  local balances = handlers.burn_tokens(payload)

  local stringQuantity = tostring(payload.Quantity)

  emit.debit_notice(payload.Caller, stringQuantity)
  
  logger.info("Burned " .. tostring(payload.Quantity) .. " " .. Ticker .. " from '" .. payload.Caller .. "'")

  output.json({
    balance_new = tostring(balances.balance_new),
    balance_old = tostring(balances.balance_old),
  })
end)

---@param payload { Caller: string }
actions.add("Info", function(payload)
  local info = handlers.get_token_info()

  emit.token_info(payload.Caller, info)

  output.json(info)
end)

---@param payload MintPayload
actions.add("Mint", function(payload)
  local balances = handlers.mint_tokens(payload)

  local stringQuantity = tostring(payload.Quantity)

  emit.mint_success(THIS_PROCESS_ID, payload.Target, stringQuantity, Ticker)

  logger.info("Minted " .. stringQuantity .. " " .. Ticker .. " to '" .. payload.Target .. "'")

  output.json({
    balance_new = balances.balance_new,
    balance_old = balances.balance_old,
  })
end)

actions.add("Transfer", function(payload)
  local memberBalances = handlers.transfer_tokens(payload)

  local stringQuantity = tostring(payload.Quantity)

  emit.debit_notice_with_recipient(payload.Caller, payload.Recipient, stringQuantity)
  emit.credit_notice(payload.Recipient, payload.Caller, stringQuantity)

  logger.info("Transferred " .. stringQuantity .. " " .. Ticker .. " from '" .. payload.Caller.. "' to '" .. payload.Recipient .. "'")

  output.json(memberBalances)
end)
