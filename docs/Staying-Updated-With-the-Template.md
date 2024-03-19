# Staying Updated With the Template

## Things to Note

- This method is just an example of how you can stay updated with the template (you are free to choose your own way)
- This method assumes you have cloned the repo locally
- This method assumes your mainline branch is `main`
- This method assumes you have not split the `contract.lua` file into separate files
- This method adds new remote address to your clone under the name `template`

## Steps

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
    git fetch --all

    git merge --squash --no-commit template/main --allow-unrelated-histories
    ```

1. Fix any merge conflicts and commit the changes.

    ```
    git commit -m "chore(template): pull new changes"
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
