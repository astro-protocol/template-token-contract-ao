local mod = {}

---Send a "successfully minted" message.
---
---@param to string The address this message is going to.
---@param token_receiver string The address that received tokens.
---@param quantity string The quantity minted.
---@param ticker_symbol string The token's ticker symbol.
function mod.mint_success(to, token_receiver, quantity, ticker_symbol)
  ao.send({
    Target = to,
    Data = "Successfully minted " .. quantity .. " " .. ticker_symbol .. " to " .. "'" .. token_receiver .."'"
  })
end

function mod.mint_not_allowed(to, caller, message_id, quantity, ticker_symbol)
  ao.send({
    Target = to,
    Action = "Mint-Error",
    ["Message-Id"] = message_id,
    Error = "Unauthorized 'Mint " .. quantity .. " " .. ticker_symbol .. "' call from address '" .. caller .. "'"
  })
end

---Send a Credit-Notice action.
---
---See the Token blueprint below for the Credit-Notice schema.
---https://cookbook_ao.g8way.io/guides/aos/blueprints/token.html
---
---@param recipient string The address the tokens are being sent to. This is
---also the address this message is being sent to.
---@param sender string The address sending the credit.
---@param quantity string The amount of tokens being credited.
function mod.credit_notice(recipient, sender, quantity)
  ao.send({
    Target = recipient,
    Tags = {
      Action = "Credit-Notice",
      Sender = sender,
      Quantity = quantity
    }
  })
end

---Send a Debit-Notice action for cases where there is a recipient of the funds
---being debited.
---
---See the Token blueprint below for the Debit-Notice schema.
---https://cookbook_ao.g8way.io/guides/aos/blueprints/token.html
---
---@param to string The address this message is being sent to.
---@param recipient string The address recieiving the credit.
---@param quantity string The amount of tokens being credited.
function mod.debit_notice_with_recipient(to, recipient, quantity)
  ao.send({
    Target = to,
    Tags = {
      Action = "Debit-Notice",
      Recipient = recipient,
      Quantity = quantity
    }
  })
end

---Send a Debit-Notice action to an address.
---
---See the Token blueprint below for the Debit-Notice schema.
---https://cookbook_ao.g8way.io/guides/aos/blueprints/token.html
---
---@param to string The address this message is being sent to.
---@param quantity string The amount of tokens being credited.
function mod.debit_notice(to, quantity)
  ao.send({
    Target = to,
    Tags = {
      Action = "Debit-Notice",
      Quantity = quantity
    }
  })
end

---Send the token info.
---
---@param to string The address this message is being sent to.
---@param info TokenInfo The token info.
function mod.token_info(to, info)
  ao.send({
    Target = to,
    Tags = info
  })
end

---Send the balance of the given balance address.
---
---@param to string The address this message is being sent to.
---@param balance_address string The address the balance belongs to.
---@param balance nil|string The balance in question.
---@param ticker string The coin's ticker symbol (e.g., "AR" for Arweave).
function mod.token_balance(to, balance_address, balance, ticker)
  ao.send({
    Target = to,
    Data = balance,
    Tags = {
      Balance = balance,
      Target = balance_address,
      Ticker = ticker,
    }
  })
end

---Send all of the balances.
---
---@param to string The address this message is being sent to.
---@param balances string All of the balances in this process as a JSON string.
function mod.token_balances(to, balances)
  ao.send({
    Target = to,
    Data = balances,
  })
end

return mod