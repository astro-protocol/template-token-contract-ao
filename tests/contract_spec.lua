local testing = require "arweave.testing"
local aolibs = require "src.aolibs"
local output = require "src.output"

local bint = aolibs.bint
local json = aolibs.json

local STUB_PRINT = true

-- /////////////////////////////////////////////////////////////////////////////
-- // FILE MARKER - TEST SETUP /////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////

local processId = testing.utils.generateAddress()

---Create a fake `Handlers` variable that `ao` would use in the real code.
_G.Handlers = {
  ---A storage variable to hold handlers that are added via `Handlers.add()` in
  ---the real code. The `Handlers.add()` function is rewritten below, so the
  ---handler that is added by the real code gets stored here. With this setup,
  ---tests can call `Handlers.get("name_of_handler")(msg, env)` to execute the
  ---handler they want to test.
  __handlers_added = {},

  ---Get a handler that was added by the code being tested.
  ---@param name string The name of the handler. The name is the `name` argument
  ---passed to `Handlers.add()`.
  ---@return HandlerFunction
  get = function(name)
    return Handlers.__handlers_added[name]
  end,

  ---A rewrite of the original implementation so handlers can be stored in this
  ---fake global `Handlers` variable.
  add = function(name, condition, func)
    Handlers.__handlers_added[name] = func
  end,

  ---A stub of the original implementation. These tests do not care about
  ---executing this condition. They just need it to exist so `nil` errors do not
  ---show up.
  utils = {
    hasMatchingTag = function(name, value)
      return true
    end
  }
}

_G.ao = {
  id = processId,
  send = function(args)
    return args
  end,

  log = function(args)
    return args
  end
}
---Reset all mocks
---@param mocks any
local function resetMocks(mocks)
  if mocks.ao then
    mocks.ao.send:clear()
  end
end

if STUB_PRINT then
  print = stub(_G, "print")
end

-- /////////////////////////////////////////////////////////////////////////////
-- // FILE MARKER - IMPORT FILE TO TEST ////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////

require "contract_example"

_G.Name = "T0K3N"
_G.Ticker = "CT"

-- /////////////////////////////////////////////////////////////////////////////
-- // FILE MARKER - TESTS //////////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////

describe("Action =", function()
  test("Info", function()

    ao = mock(ao)
    output = mock(output)

    local msg = {
      From = "0x1337"
    }

    Handlers.__handlers_added["Info"](msg)

    local expectedSend = {
      Target = msg.From,
      Tags = {
        Name = Name,
        Ticker = Ticker,
        Denomination = "12",
        Logo = ""
      }
    }

    assert.spy(ao.send).was.called_with(expectedSend)

    assert.spy(output.json).was.called_with(expectedSend.Tags)

    resetMocks({ ao = ao })
  end)

  test("Balance -> returns balance", function()
    local address = testing.utils.generateAddress()
    
    _G.ao = mock(ao)
    _G.output = mock(output)

    _G.Balances = {
      [processId] = bint("50000"),
      [address] = bint("190"),
    }

    local msg = {
      From = address,
      Tags = {
        Address = address
      }
    }

    Handlers.__handlers_added["Balance"](msg)

    local expectedSend = {
      Target = address,
      Data = "190",
      Tags = {
        Balance = "190",
        Target = address,
        Ticker = Ticker
      }
    }

    assert.spy(ao.send).was.called_with(expectedSend)

    assert.spy(output.json).was.called_with({
      Balance = bint("190"),
      Target = address,
      Ticker = Ticker
    })

    resetMocks({ ao = ao })
  end)

  test("Balances -> returns all balances", function()
    local anotherAddress = testing.utils.generateAddress()

    _G.ao = mock(ao)
    _G.output = mock(output)

    _G.Balances = {
      [processId] = bint("50000"),
      [anotherAddress] = bint("190"),
    }

    local msg = {
      From = anotherAddress
    }

    Handlers.__handlers_added["Balances"](msg)

    assert.spy(ao.send).was.called_with({
      Target = anotherAddress,
      Data = json.encode(Balances)
    })

    assert.spy(output.json).was.called_with({
      [processId] = bint("50000"),
      [anotherAddress] = bint("190"),
    })

    resetMocks({ ao = ao })
  end)

  test("Burn -> burns tokens", function()
    local caller = testing.utils.generateAddress()
    
    _G.output = mock(output)
    _G.ao = mock(ao)
    _G.Balances.SomeRandomAddress = bint("200")
    _G.Balances[caller] = bint("180")

    
    Handlers.__handlers_added["Burn"]({
      From = caller,
      Tags = {
        Quantity = "1",
      }
    })

    -- Assert the balance is the initial balance (190) minus the quantity (1)
    assert.same(bint("179"), Balances[caller])

    -- Assert a Debit-Notice was sent to the caller
    assert.spy(ao.send).was.called_with({
      Target = caller,
      Tags = {
        Action = "Debit-Notice",
        Quantity = "1"
      }
    })

    resetMocks({ ao = ao })
  end)

  test("Mint -> errors when minter address is unauthorized",
        function()
    local qty = "18000000000000"
    local target = testing.utils.generateAddress()
    local minter = testing.utils.generateAddress()
    local depositTxId = testing.utils.generateAddress()

    ProposalAuthorities = {
      minters = {
        minter
      }
    }

    ao = mock(ao)
    output = mock(output)

    local msg = {
      From = target,
      Tags = {
        ["Deposit-Tx-Id"] = depositTxId,
        ["Fee-Winston"] = "3600000000000",
        ["Fee-USD"] = "57.82",
        ["Currency-From-USD-Price"] = "289.08",
        Target = target,
        Quantity = qty
      }
    }

    local env = {
      Process = {
        Id = processId
      }
    }

    local success, res = pcall(function()
      Handlers.__handlers_added["Deposit"](msg, env)
    end, processId, target, qty)
  end)

  test(
    "Transfer (Action-Type = 'INTERNAL')",
    function ()
      local sender = testing.utils.generateAddress()
      local receiver = testing.utils.generateAddress()

      _G.Balances = {
        [processId] = bint(50000),
        [sender] = bint(190),
        [receiver] = bint(1),
      }

      -- Set up global ao object
      _G.ao = mock(ao)

      local msg = {
        From = sender,
        Tags = {
          ["Action-Type"] = "INTERNAL",
          Recipient = receiver,
          Quantity = "1"
        }
      }

      Handlers.__handlers_added["Transfer"](msg)

      assert.same(
        Balances[sender],
        bint(189)
      )

      assert.same(
        Balances[receiver],
        bint(2)
      )

      -- assert.spy(ao.send).was.called_with({
      --   Target = processId,
      --   Tags = {
      --     Action = "Debit-Notice",
      --     Quantity = "1",
      --     Target = receiver
      --   }
      -- })

      assert.spy(ao.send).was.called_with({
        Target = receiver,
        Tags = {
          Action = "Credit-Notice",
          Quantity = "1",
          Sender = sender,
        }
      })
    end
  )
end)
