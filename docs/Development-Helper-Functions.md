# Development Helper Functions

This template comes with the following helper functions for contract owners.

__These functions only exist to ease the development process and should be removed in environments where they are not needed (e.g., MAINNET environments).__
 
## `Call.Reset()`

```lua
Call.Reset()
```

### Purpose

Resets the token info so you can load new contract code.

### Usage

## `Call.TestAll()`

### Purpose

Runs mint, burn, balance, balances, info functions in one call so you can inspect the contract's behavior.

### Usage

```lua
Call.TestAll()
```

View the `contract.lua` file for their implementation details.
