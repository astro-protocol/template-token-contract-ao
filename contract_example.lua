local actions = require "src.actions.mod"
local aolibs = require "src.aolibs"
local emit = require "src.emit"
local extensions = require "src.extensions.mod"
local logger = require "src.logger"
local output = require "src.output"
local runtime = require "src.runtime"
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
  if payload.Caller ~= THIS_PROCESS_ID then
    runtime.throw("Unauthorized 'Mint' call from address '" .. payload.Caller .. "'")
  end

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

  local balanceAsString = tostring(balance or 0)

  emit.token_balance(payload.Caller, payload.Target, balanceAsString, Ticker)

  output.json({ Target = payload.Target, Balance = balanceAsString, Ticker = Ticker })
end)

---@param payload BalancesPayload
actions.add("Balances", function(payload)
  local balances = handlers.get_token_balances(payload) or {}

  local balancesAsStrings = {}

  for address, balance in extensions.tables.pairs_by_keys(balances) do
    balancesAsStrings[address] = tostring(balance)
  end

  local sorted = extensions.tables.sort(balancesAsStrings)

  emit.token_balances(payload.Caller, json.encode(sorted))
  
  output.json(balancesAsStrings)
end)

---@param payload BurnPayload
actions.add("Burn", function(payload)
  local balances = handlers.burn_tokens(payload)

  local stringQuantity = tostring(payload.Quantity)

  emit.debit_notice(payload.Caller, stringQuantity)
  
  logger.info("Burned " .. tostring(payload.Quantity) .. " " .. Ticker .. " from '" .. payload.Caller .. "'")

  output.json({
    target = payload.Caller,
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
  local addressBalances = handlers.mint_tokens(payload)

  local stringQuantity = tostring(payload.Quantity)

  emit.mint_success(payload.Caller, payload.Target, stringQuantity, Ticker)
  emit.credit_notice(payload.Target, payload.Caller, stringQuantity)

  logger.info("Minted " .. stringQuantity .. " " .. Ticker .. " to '" .. payload.Target .. "'")

  output.json({
    target = payload.Target,
    balance_new = tostring(addressBalances.balance_new),
    balance_old = tostring(addressBalances.balance_old),
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
