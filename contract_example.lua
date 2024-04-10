local actions = require "src.actions.mod"
local contract_defaults = require "contract_defaults"

actions.add("Balance", contract_defaults.actions.balance)

actions.add("Balances", contract_defaults.actions.balances)

actions.add("Burn", contract_defaults.actions.burn)

actions.add("Info", contract_defaults.actions.info)

actions.add("Mint", contract_defaults.actions.mint)

actions.add("Transfer", contract_defaults.actions.transfer)
