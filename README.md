![Holograph - Render 16](https://user-images.githubusercontent.com/21043504/188220186-9c7f55e0-143a-41b4-a6b8-90e8bd54bfd9.png)

# Holograph Protocol

This project contains the latest version of the Holograph Protocol.

---

**This project uses [asdf](https://asdf-vm.com/) for tool versions management.**

---

## First-run

If this is your first time running the project. Some initial steps will need to be taken to prepare the project.

1. Run `asdf install` to have the correct tool versions.
2. Install dependencies with `yarn install`.
3. Initialize the project with `yarn run init` _(this will copy sample environment configs)_.

---

## Building

All smart contracts source code is located in the `src` directory.

Files from the `src` directory are automatically built into the `contracts` directory each time that **hardhat** compiles the contracts.

To manually run just the build task use `yarn run build`.

**How to run project locally**

1. Build the latest version of the contracts via `yarn run clean-compile` _(alternatively you can just run `yarn run compile`)_.
2. Start the localhost ganache instances via `yarn run ganache-x2` _(this will run two instances simultaneously inside of one command)_. **_Make sure to run this command in a separate terminal window._**
3. Deploy the smart contracts via `yarn run deploy`.
4. Run all tests via `yarn run test`.

_If you need the smart contracts ABI files for dApp integrations, use `yarn run abi` to get a complete list of all ABI's inside of the `abi` directory._

---

## Making Changes

**Before pushing your work to the repo, make sure to prepare your code**

At the current moment, style formatting is not directly enforced, but it will be in the future.

In preparation for that, please make use of the `yarn run prettier:fix` command to format the codebase into a universal style.
