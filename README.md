<div align="center">
  <a href="https://holograph.xyz"><img alt="Holograph" src="https://user-images.githubusercontent.com/21043504/188220186-9c7f55e0-143a-41b4-a6b8-90e8bd54bfd9.png" width=600></a>
  <br />
  <h1>Holograph Protocol</h1>
</div>
<p align="center">
</p>

## Description

Holograph provides omnichain NFT infrastructure for the web3 ecosystem. Holograph Protocol enables the creation, deployment, minting, & bridging of omnichain NFTs with complete data integrity.

## Development

### Getting started

1. This project uses [asdf](https://asdf-vm.com/) for versions management. Install following plugins
   - Install [asdf Node plugin](https://github.com/asdf-vm/asdf-nodejs): `asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git`
   - Install [asdf yarn plugin](https://github.com/twuni/asdf-yarn): `asdf plugin-add yarn`
1. Run `asdf install` after to have the correct tool versions.
1. Install dependencies with `yarn install`.
1. Initialize the project with `yarn run init` _(this will copy sample environment configs)_.

### Building

All smart contracts source code is located in the `src` directory.

Files from the `src` directory are automatically transpiled into the `contracts` directory each time that **hardhat** compiles the contracts.

To manually run just the build task use `yarn run build`.

### Compiling, Testing, and Deploying (Locally)

1. Build the latest version of the contracts via `yarn run clean-compile` _(alternatively you can just run `yarn run compile`)_.
2. Start the localhost ganache instances via `yarn run ganache-x2` _(this will run two instances simultaneously inside of one command)_. **_Make sure to run this command in a separate terminal window._**
3. Deploy the smart contracts via `yarn run deploy`.
4. Run all tests via `yarn run test`.

_If you need the smart contracts ABI files for dApp integrations, use `yarn run abi` to get a complete list of all ABI's inside of the `abi` directory._

### Making Changes

**Before pushing your work to the repo, make sure to prepare your code**

Please make use of the `yarn run prettier:fix` command to format the codebase into a universal style.

## Directory Structure

<pre>
root

├── <a href="./config">config</a>: Network configuration files
├── <a href="./contracts">contracts</a>: Smart contracts that power the Holograph protocol
├── <a href="./deploy">deploy</a>: Deployment scripts for the smart contracts uses <a href="https://hardhat.org/">Hardhat</a> and <a href="https://github.com/wighawag/hardhat-deploy">Hardhat Deploy</a>
├── <a href="./deployments">deployments</a>: Deployment build files that include contract addresses on each network
├── <a href="./scripts">scripts</a>: Scripts and helper utilities
├── <a href="./src">src</a>: Source contracts that get dynamically transpiled down into the finalized output <a href="./contracts">contracts</a>
└── <a href="./test">test</a>: Hardhat tests for the smart contracts
</pre>

## Branching Model and Releases

### Active Branches

| Branch                                                                     | Status                                                                             |
| -------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| [mainnet](https://github.com/holographxyz/holograph-protocol/tree/mainnet) | Accepts PRs from `testnet` or `release/x.x.x` when we intend to deploy to mainnet. |
| [testnet](https://github.com/holographxyz/holograph-protocol/tree/testnet) | Accepts PRs from `develop` that are ready to be deployed to testnet.               |
| [develop](https://github.com/holographxyz/holograph-protocol/tree/develop) | Accepts PRs from `feature/xyz` branches that are experimental or in testing stage. |
| release/x.x.x                                                              | Accepts PRs from `testnet`.                                                        |

### Overview

We generally follow [this Git branching model](https://nvie.com/posts/a-successful-git-branching-model/).
Please read the linked post if you're planning to make frequent PRs into this repository.

### The `mainnet` branch

The `mainnet` branch contains the code for our latest "stable" mainnet releases.
Updates from `mainnet` always come from the `testnet` branch.
We only ever update the `mainnet` branch when we intend to deploy code that has been tested on testnets to all mainnet networks supported by the Holograph protocol.
Our update process takes the form of a PR merging the `testnet` branch into the `mainnet` branch.

### The `testnet` branch

The `testnet` branch continas the code that is the latest stable testnet release for all supported networks. This branch is deployed and circulated for beta users of the protocol. Updates are merged in from the `develop` branch once they're ready for broad usage.

### The `develop` branch

Our primary development branch is [`develop`](https://github.com/holographxyz/holograph-protocol/tree/testnet).
`develop` contains the most up-to-date software that is being tested via experimental network deployments.

## Contributing

Read through [CONTRIBUTING.md](./CONTRIBUTING.md) for a general overview of our contribution process.

## Official Links

- [Website](https://holograph.xyz)
- [App](https://app.holograph.xyz)
- [Docs](https://docs.holograph.xyz)
- [Discord](https://discord.com/invite/holograph)
- [Twitter](https://twitter.com/holographxyz)
- [Mirror](https://mirror.xyz/holographxyz.eth)

## License

Files under this repository are licensed under [Holograph Limited Public License](https://github.com/holographxyz/holograph-protocol/blob/testnet/LICENSE.md) (H-LPL) 1.0.0 unless otherwise stated.
