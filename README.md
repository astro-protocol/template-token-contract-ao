# Token Contract

## Developer Guides

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

Burn tokens assigned to your address.

#### Example Calls

```lua
Send({
  Target = "[this contract's ID (assigned when deployed in ao)]",
  Action = "Burn",
  Tags = {
    Quantity = "[the number of tokens to mint (as a string)]"
  }
})
```

#### Example Result `Output.data` Value

```
{
  target = "3mSK9FexnTCgGs7gLIo0VoRYU-IS81nTh3n3wkE_e9Y",
  balance_new = "1000000000000",
  balance_old = "2000000000000",
}
```

### `Info`

Get the token information contained in this contract.

#### Example Calls

```lua
Send({
  Target = "[this contract's ID (assigned when deployed in ao)]",
  Action = "Info",
})
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

Mint new tokens and assign them to an address.

#### Example Calls

```lua
Send({
  Target = "[this contract's ID (assigned when deployed in ao)]",
  Action = "Mint",
  Tags = {
    Target = "[the address receiving the tokens]",
    Quantity = "[the number of tokens to mint (as a string)]"
  }
})
```

#### Example Result `Output.data` Value

```
{
  target = "3mSK9FexnTCgGs7gLIo0VoRYU-IS81nTh3n3wkE_e9Y",
  balance_new = "2000000000000",
  balance_old = "1000000000000",
}
```

### `Transfer`

Transfer tokens from your address to another address.

#### Example Calls

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

#### Example Result `Output.data` Value (Internal Transfers)

```
{
  recipient_balance_new = "2000000000000",
  recipient_balance_old = "1000000000000",
  sender_balance_new = "1000000000000",
  sender_balance_old = "2000000000000",
}
```
