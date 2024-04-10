local testing = require "arweave.testing"
local aolibs = require "src.aolibs"
local output = require "src.output"
local extensions = require "src.extensions.mod"

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

ao = mock(ao)
output = mock(output)

describe("#template_example Action =", function()

  before_each(function ()
    ---Reset all mocks
    ao.send:clear()
    output.json:clear()
  end)

  test("Info -> returns token info", function()

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
  end)

  test("Balance -> returns balance", function()
    local address = testing.utils.generateAddress()

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
      Balance = "190",
      Target = address,
      Ticker = Ticker
    })
  end)

  test("Balances -> returns all balances", function()
    local anotherAddress = testing.utils.generateAddress()

    _G.Balances = {
      [processId] = bint("50000"),
      [anotherAddress] = bint("190"),
    }

    local msg = {
      From = anotherAddress
    }

    Handlers.__handlers_added["Balances"](msg)

    local balancesAsStrings = {
      [processId] = tostring(bint("50000")),
      [anotherAddress] = tostring(bint("190")),
    }

    local sorted = extensions.tables.sort(balancesAsStrings)

    assert.spy(ao.send).was.called_with({
      Target = anotherAddress,
      Data = json.encode(sorted)
    })

    assert.spy(output.json).was.called_with(sorted)
  end)

  test("Mint -> mints tokens", function()
    local caller = THIS_PROCESS_ID
    local target = testing.utils.generateAddress()
    
    _G.Balances.SomeRandomAddress = bint("200")
    _G.Balances[target] = bint("180")

    Handlers.__handlers_added["Mint"]({
      From = caller,
      Tags = {
        Target = target,
        Quantity = "1",
      }
    })

    -- Assert the balance is the initial balance (180) plus the quantity (1)
    assert.same(bint("181"), Balances[target])

    assert.spy(ao.send).was.called_with({
      Target = caller,
      Data = "Successfully minted 1 CT to '" .. target .. "'"
    })

    -- Assert a Credit-Notice was sent to the caller
    assert.spy(ao.send).was.called_with({
      Target = target,
      Tags = {
        Action = "Credit-Notice",
        Sender = caller,
        Quantity = "1"
      }
    })

    local response = extensions.tables.sort({
      target = target,
      balance_new = tostring(bint("181")),
      balance_old = tostring(bint("180")),
    })

    assert.spy(output.json).called(1)

    assert.spy(output.json).was.called_with(response)
  end)

  test("Burn -> burns tokens", function()
    local caller = testing.utils.generateAddress()
    
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

    local response = extensions.tables.sort({
      target = caller,
      balance_new = tostring(bint("179")),
      balance_old = tostring(bint("180")),
    })

    assert.spy(output.json).called(1)

    assert.spy(output.json).was.called_with(response)
  end)

  test(
    "Transfer -> transfers tokens (send less than balance)",
    function ()
      local sender = testing.utils.generateAddress()
      local receiver = testing.utils.generateAddress()

      _G.Balances = {
        [processId] = bint(50000),
        [sender] = bint(190),
        [receiver] = bint(1),
      }

      local msg = {
        From = sender,
        Tags = {
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

      assert.spy(ao.send).was.called_with({
        Target = sender,
        Tags = {
          Action = "Debit-Notice",
          Quantity = "1",
          Recipient = receiver
        }
      })

      assert.spy(ao.send).was.called_with({
        Target = receiver,
        Tags = {
          Action = "Credit-Notice",
          Quantity = "1",
          Sender = sender,
        }
      })

      local response = extensions.tables.sort({
        recipient_balance_new = tostring(bint("2")),
        recipient_balance_old = tostring(bint("1")),
        sender_balance_new = tostring(bint("189")),
        sender_balance_old = tostring(bint("190")),
      })

      assert.spy(output.json).was.called(1)
  
      assert.spy(output.json).was.called_with(response)
    end
  )

  test(
    "Transfer -> transfers tokens (send total balance)",
    function ()
      local sender = testing.utils.generateAddress()
      local receiver = testing.utils.generateAddress()

      _G.Balances = {
        [processId] = bint(50000),
        [sender] = bint(199),
        [receiver] = bint(3),
      }

      local msg = {
        From = sender,
        Tags = {
          Recipient = receiver,
          Quantity = "199"
        }
      }

      Handlers.__handlers_added["Transfer"](msg)

      -- The sender's balance should be 199 - 199
      assert.same(
        Balances[sender],
        bint(0)
      )

      -- The recipient's balance should be 199 + 3
      assert.same(
        Balances[receiver],
        bint(202)
      )

      -- There should be no "Debit-Notice" call

      assert.spy(ao.send).was.called_with({
        Target = sender,
        Tags = {
          Action = "Debit-Notice",
          Quantity = "199",
          Recipient = receiver
        }
      })

      -- There should be not "Credit-Notice" call

      assert.spy(ao.send).was.called_with({
        Target = receiver,
        Tags = {
          Action = "Credit-Notice",
          Quantity = "199",
          Sender = sender,
        }
      })

      local response = extensions.tables.sort({
        recipient_balance_new = tostring(bint("202")),
        recipient_balance_old = tostring(bint("3")),
        sender_balance_new = tostring(bint("0")),
        sender_balance_old = tostring(bint("199")),
      })

      assert.spy(output.json).was.called(1)
  
      assert.spy(output.json).was.called_with(response)
    end
  )

  test(
    "Transfer -> transfers tokens (send more than balance)",
    function ()
      local sender = testing.utils.generateAddress()
      local receiver = testing.utils.generateAddress()

      _G.Balances = {
        [processId] = bint(50000),
        [sender] = bint(199),
        [receiver] = bint(3),
      }

      local msg = {
        From = sender,
        Tags = {
          Recipient = receiver,
          Quantity = "200"
        }
      }

      local status, err = pcall(function()
        return Handlers.__handlers_added["Transfer"](msg)
      end)

      local jsonError = json.decode(err)

      assert(not status)
      assert.same(jsonError.action, "Transfer")
      assert.same(jsonError.message, "Cannot transfer tokens. From address '" .. sender .. "' has insufficient balance.")

      -- The sender's balance should not change
      assert.same(
        Balances[sender],
        bint(199)
      )

      -- The recipient's balance should not change
      assert.same(
        Balances[receiver],
        bint(3)
      )

      -- There should be no "Debit-Notice" call

      assert.spy(ao.send).was.not_called_with({
        Target = sender,
        Tags = {
          Action = "Debit-Notice",
          Quantity = "1",
          Recipient = receiver
        }
      })

      -- There should be not "Credit-Notice" call

      assert.spy(ao.send).was.not_called_with({
        Target = receiver,
        Tags = {
          Action = "Credit-Notice",
          Quantity = "1",
          Sender = sender,
        }
      })

      local response = extensions.tables.sort({
        recipient_balance_new = tostring(bint("202")),
        recipient_balance_old = tostring(bint("3")),
        sender_balance_new = tostring(bint("0")),
        sender_balance_old = tostring(bint("199")),
      })
  
      assert.spy(output.json).was.called(0)

      assert.spy(output.json).not_called_with(response)
    end
  )
end)
