# Deployment Examples

## Overview

In the `deno.json` file, there is a `tasks.deploy` command that calls a `./scripts/deploy` file. The `./scripts/deploy` file is ignored, so you can create your own `./scripts/deploy` file and use it by running:

```
deno task deploy
```

## Using `ao-deploy`

### Things to Note

- You can view the documentation for `ao-deploy` at https://www.npmjs.com/package/ao-deploy
- This assumes you have Node v20.x+ installed and can run `npx` commands
- This assumes you have Deno 1.40.x+ installed and can run `deno` commands

### Steps

1. Create a `./scripts/deploy` script with the following contents:

    ```
    #! /usr/bin/env bash

    (
      echo -e "\n\n[ Deploy process using ao-deploy started ]\n\n"

      npx ao-deploy contract.lua
    )
    ```

1. (Last step) Run your `./scripts/deploy` script:

    ```
    deno task deploy
    ```

    The `./scripts/deploy` script you created should have been used to deploy your contract.
