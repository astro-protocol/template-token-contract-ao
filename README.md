# Token Contract Template

## Developer Guides

### Staying Updated With the Template

#### Things to Note

- This method is just an example of how you can stay updated with the template (you are free to choose your own way)
- This method assumes you have cloned the repo locally
- This method assumes your mainline branch is `main`
- This method assumes you have not split the `contract.lua` file into separate files
- This method adds new remote address to your clone under the name `template`

#### Steps

1. Add a new remote address to your localy clone.

    ```
    git remote add template git@github.com:astro-protocol/template-token-contract-ao.git
    ```

1. Check out your mainline branch (e.g., `main`).

    ```
    git checkout main
    ```

1. Create a new branch named `template` (from your mainline branch).

    ```
    git checkout -b template
    ```

1. Pull new template changes down from the `template` remote address.

    ```
    git pull template
    ```

1. Check out your mainline branch.

    ```
    git checkout main
    ```

1. (Last step) Merge the template changes into your mainline branch to update your mainline branch.

    ```
    git merge --no-ff template
    ```

Your mainline branch's `contract.lua` file should now have the latest changes from the template.

## Helper Functions

This template comes with the following helper functions for contract owners. They only exist to ease the development process and should be removed in environments where they are not needed (e.g., MAINNET environments).
 
### `Call.Reset()`

```lua
Call.Reset()
```

#### Purpose

Resets the token info so you can load new contract code.

#### Usage

### `Call.TestAll()`

#### Purpose

Runs mint, burn, balance, balances, info functions in one call so you can inspect the contract's behavior.

#### Usage

```lua
Call.TestAll()
```

View the `contract.lua` file for their implementation details.

## API

### `Balance(address)`

Get a balance for an address in this contract.

#### Example Calls

- If you are sending a message to this contract, you can use the following:

   ```lua
   Send({
      Target = "[this contract's ID (assigned when deployed in ao)]",
      Action = "Balance",
      Tags = {
         Address = "[the address in question]",
      },
   })
   ```

- If you are the contract owner, you can use the following shortened call:

   ```lua
   Call.Balance("[the address in question]")
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

#### Example Calls

- If you are sending a message to this contract, you can use the following:

   ```lua
   Send({
      Target = "[this contract's ID (assigned when deployed in ao)]",
      Action = "Balances",
   })
   ```

- If you are the contract owner, you can use the following shortened call:

   ```lua
   Call.Balances()
   ```

#### Example Result `Output.data` Value

```
{
   "3mSK9FexnTCgGs7gLIo0VoRYU-IS81nTh3n3wkE_e9Y": 0,
   "p55NAQO-m8zmssDIn6m4naZBbUlPxYfk_SSFEohhvCs": 1
}
```

### `Burn`

TBC

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
         Sender = "[the address sending tokens]",
         Receiver = "[the address receiving tokens]",
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
         Sender = "[the address sending tokens]",
         Receiver = "[the address receiving tokens]",
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
