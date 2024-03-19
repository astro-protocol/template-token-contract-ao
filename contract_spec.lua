local testing = require "arweave.testing"

local STUB_PRINT = true

-- /////////////////////////////////////////////////////////////////////////////
-- // FILE MARKER - TEST SETUP /////////////////////////////////////////////////
-- /////////////////////////////////////////////////////////////////////////////

local function resetMocks(mocks)
  if mocks.ao then
    mocks.ao.send:clear()
  end
end

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

require "contract"

-- Override the hash provider's logic so we can match against the fake value
-- "some-unique-id" instead of trying to match against a real hash
Providers.hash = {
  generateId = function()
    return "some-unique-id"
  end
}

describe("Action =", function()
  test("Info", function()

    ao = mock(ao)
    Providers.output = mock(Providers.output)

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

    assert.spy(Providers.output.json).was.called_with(expectedSend.Tags)

    ao.send:clear()
  end)

  test("Balance -> returns balance", function()
    local address = testing.utils.generateAddress()
    
    _G.ao = mock(ao)
    _G.Providers.output = mock(Providers.output)

    _G.Balances = {
      [processId] = 50000,
      [address] = 190
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

    assert.spy(Providers.output.json).was.called_with(expectedSend.Tags)

    _G.ao.send:clear()
  end)

  test("Balances -> returns all balances", function()
    local anotherAddress = testing.utils.generateAddress()

    _G.ao = mock(ao)
    _G.Providers.output = mock(Providers.output)

    _G.Balances = {
      [processId] = 50000,
      [anotherAddress] = 190
    }

    local msg = {
      From = anotherAddress
    }

    Handlers.__handlers_added["Balances"](msg)

    local expectedSend = {
      Target = anotherAddress,
      Data = json.encode(Balances)
    }

    assert.spy(ao.send).was.called_with(expectedSend)

    assert.spy(Providers.output.json).was.called_with({
      [processId] = 50000,
      [anotherAddress] = 190
    })

    ao.send:clear()
  end)

  test("Burn -> goes through request and approval process", function()

    
    local burnerA = testing.utils.generateAddress()
    local burnerB = testing.utils.generateAddress()
    local requestor = testing.utils.generateAddress()
    
    _G.Providers.output = mock(Providers.output)
    _G.Providers.proposals.members.burners = {
      burnerA,
      burnerB,
    }
    _G.Providers.proposals.requirements.required_burn_approvals = 2

    _G.ao = mock(ao)
    _G.Balances.SomeRandomAddress = 200
    _G.Balances[requestor] = 190
    
    --
    -- Send the initial burn request
    --
    
    Handlers.__handlers_added["Burn"]({
      From = requestor,
      Tags = {
        Quantity = "1",
        Requestor = requestor
      }
    })

    local requestId = Providers.hash.generateId()

    -- Since there are two burn approvers, two `ao.send()` calls should
    -- occur (one for each approver)

    assert.spy(ao.send).was.called(2)
    assert.spy(ao.send).was.called_with({
      Target = processId,
      Tags = {
        Approver = burnerA,
        Action = "Burn-Request-Notice",
        ["Burn-Request-Id"] = requestId,
        Quantity = "1",
        Requestor = requestor
      }
    })
    assert.spy(ao.send).was.called_with({
      Target = processId,
      Tags = {
        Approver = burnerB,
        Action = "Burn-Request-Notice",
        ["Burn-Request-Id"] = requestId,
        Quantity = "1",
        Requestor = requestor
      }
    })

    --
    -- Send the burn approvals
    --

    Handlers.__handlers_added["Burn"]({
      From = burnerA,
      Tags = {
        ["Burn-Request-Id"] = requestId,
        ["Action-Type"] = "APPROVAL",
        ["Requestor"] = requestor
      }
    })
    
    assert.same(
      Providers.proposals.proposals.burn_requests[requestor][requestId].approvals[1],
      burnerA
    )

    Handlers.__handlers_added["Burn"]({
      From = burnerB,
      Tags = {
        ["Burn-Request-Id"] = requestId,
        ["Action-Type"] = "APPROVAL",
        ["Requestor"] = requestor
      }
    })

    assert.same(
      Providers.proposals.proposals.burn_requests[requestor][requestId].approvals[2],
      burnerB
    )

    --
    -- The requestor's balance should now be updated
    --

    -- Assert the balance is the initial balance (190) - the quantity (1)
    assert.same(Balances[requestor], 189)

    -- Assert a Debit-Notice was sent to the requestor
    assert.spy(ao.send).was.called_with({
      Target = processId,
      Tags = {
        Action = "Debit-Notice",
        Target = requestor,
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
    Providers.output = mock(Providers.output)

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
        [processId] = 50000,
        [sender] = 190,
        [receiver] = 1
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
        189
      )

      assert.same(
        Balances[receiver],
        2
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
        Target = processId,
        Tags = {
          Action = "Credit-Notice",
          Quantity = "1",
          Target = receiver
        }
      })
    end
  )

  -- test(
  --   'Action = "Transfer", Transfer-Type = "External"',
  --   function ()
  --     local from = testing.utils.generateAddress()
  --     local to = testing.utils.generateAddress()

  --     globals.set_globals({
  --       Name = "TestToken",
  --       Ticker = "A-Test",
  --       Logo = "logo",
  --       Denomination = 12,
  --       Balances = {
  --         [ao.id] = 50000,
  --         [from] = 190,
  --         [to] = 1
  --       },
  --       AuthorizedExternalTargets = {
  --         to
  --       },
  --     })

  --     -- Set up global ao object
  --     ao = fakes.ao

  --     local msg = {
  --       From = from,
  --       Target = to,
  --       Tags = {
  --         ["Transfer-Type"] = "External",
  --         Quantity = "1"
  --       }
  --     }

  --     Handlers.__handlers_added["transfer"](msg)

  --     -- This address balance should reflect the transfer result
  --     testing.asserts.equals(
  --       Balances[from],
  --       189
  --     )

  --     -- This address balance should not be modified
  --     testing.asserts.equals(
  --       Balances[to],
  --       1
  --     )

  --     testing.asserts.json_equals(
  --       ao.calls.send[1],
  --       {
  --         Target = to,
  --         Tags = {
  --           Action = "Borrow",
  --           Quantity = "1",
  --           Borrower = from,
  --           ["Token-Ticker"] = "A-Test",
  --         }
  --       }
  --     )

  --     testing.asserts.json_equals(
  --       ao.calls.send[2],
  --       {
  --         Target = to,
  --         Tags = {
  --           Action = "Debit-Notice",
  --           Quantity = "1",
  --           Recipient = to
  --         }
  --       }
  --     )

  --     testing.asserts.equals(
  --       ao.calls.log[1],
  --       "Transferred 1 A-Test"
  --     )
  --   end
  -- )
end)
