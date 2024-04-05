# Token Contract

## Developer Guides

- [Development Helper Functions](./docs/Development-Helper-Functions.md)
- [Staying Updated With the Template](./docs/Staying-Updated-With-the-Template.md)

## API

### `Balance(address)`

Get a balance for an address in this contract.

#### Example Calls

```lua
Send({
   Target = "[this contract's ID (assigned when deployed in ao)]",
   Action = "Balance",
   Tags = {
      Address = "[the address in question]",
   },
})
```

#### Example Result `Output.data` Value

```
{
   "Address": "3mSK9FexnTCgGs7gLIo0VoRYU-IS81nTh3n3wkE_e9Y",
   "Balance": 1,
   "Ticker": "0x1667-W"
}
```

### `Balances()`

Get all balances for all addresses in this contract.

#### Example Call

```lua
Send({
   Target = "[this contract's ID (assigned when deployed in ao)]",
   Action = "Balances",
})
```

#### Example Result `Output.data` Value

```
{
   "3mSK9FexnTCgGs7gLIo0VoRYU-IS81nTh3n3wkE_e9Y": "1000000000000",
   "p55NAQO-m8zmssDIn6m4naZBbUlPxYfk_SSFEohhvCs": "2000000000000",
}
```

### `Burn`



### `Info`

Get the token information contained in this contract.

#### Example Calls

- If you are sending a message to this contract, you can use the following:

   ```lua
   Send({
      Target = "[this contract's ID (assigned when deployed in ao)]",
      Action = "Info",
   })
   ```

- If you are the contract owner, you can use the following shortened call:

   ```lua
   Call.Info()
   ```

#### Example Result `Output.data` Value

```
{
   "Name": "0x1667-W",
   "Ticker": "0x1667-W",
   "Denomination": "12",
   "Logo": "",
}
```

### `Mint`

Mint new tokens in this contract.

#### Example Calls

- If you are sending a message to this contract, you can use the following:

   ```lua
   Send({
      Target = "[this contract's ID (assigned when deployed in ao)]",
      Action = "Mint",
      Tags = {
         Target = "[the address in question]",
         Quantity = "[the number of tokens to mint (as a string)]"
      }
   })
   ```

- If you are the contract owner, you can use the following shortened call:

   ```lua
   Call.Mint("[the address in question]", "[the number of tokens to mint (as a string)]")
   ```

#### Example Result `Output.data` Value

_This call does not result in an `Output.data` value._

### `Transfer`

Transfer tokens internall or externally.

- Internal transfers are transfers between addresses in this contract.
- External transfers are transfers from one address in this process to another address in another process.

#### Example Calls (Internal Transfers)

- If you are sending a message to this contract, you can use the following:

   ```lua
   Send({
      Target = "[this contract's ID (assigned when deployed in ao)]",
      Action = "Transfer",
      Tags = {
         Recipient = "[the address receiving tokens]",
         Quantity = "[the number of tokens to transfer]"
      }
   })
   ```

- If you are the contract owner, you can use the following shortened call:

   ```lua
   Call.Transfer(
      "[the address sending tokens]",
      "[the address receiving tokens]",
      "[the number of tokens to transfer (as a string)]"
   )
   ```

#### Example Result `Output.data` Value (Internal Transfers)

_This call does not result in an `Output.data` value._

#### Example Calls (External Transfers)

- If you are sending a message to this contract, you can use the following:

   _Note: The only difference between this call and the internal call is this call adds an `["Action-Type"] = "EXTERNAL"` tag._

   ```lua
   Send({
      Target = "[this contract's ID (assigned when deployed in ao)]",
      Action = "Transfer",
      Tags = {
         ["Action-Type"] = "EXTERNAL",
         Recipient = "[the address receiving tokens]",
         Quantity = "[the number of tokens to transfer]"
      }
   })
   ```

- If you are the contract owner, you can use the following shortened call:

   _Note: The only difference between this call and the internal call is this call provides a fourth argument (`[the ID of the external process]`)._

   ```lua
   Call.Transfer(
      "[the address sending tokens]",
      "[the address receiving tokens]",
      "[the number of tokens to transfer (as a string)]",
      "[the ID of the external process]"
   )
   ```

#### Example Result `Output.data` Value (External Transfers)

_This call does not result in an `Output.data` value._
