# Actions

The Actions module is located in [`src/actions.lua`](../src/actions.lua).

## Overview

This module standardizes incoming messages (aka the `msg` argument in action handler definitions) from the network by converting all messages to a `payload` object. This module does a few things as soon as a `msg` argument received:

- Defines a `payload` object using `msg.Tags`
- Defines a `payload.Caller` field using `msg.From` for semantics
- Defines a `payload.Quantity` field as a `Bint` if a `msg.Tags.Quantity` value is received
- Defines a `payload._Message` using the orignal incoming message to be used as a reference if needed

For implementation details, see the `msg_to_payload()` function in the [`src/actions/mod.lua`](../actions/mod.lua) file.

## Actions APIs

### `actions.add(action: string, fn: fun(payload))`

__Description__

Use this function to add a new action to your contract.

__Params__

- `action`: The name of the action. This is what callers will use to call your action (e.g., `Send({ Target = ao.id, Action = {action} })`).
- `fn`: Your action's handler function. The `payload` argument will be the `payload` object described above in the [Overview](#overview) section.

__Example Usage__

```lua
local actions = require "src.actions"

actions.add("Greet", function(payload)

  print("Hello")

end)

-- Callers can call your action by providing "Greet" as the action in their message. For example:
--
--   Send({ Target = ao.id, Action = "Greet" })
--
```
