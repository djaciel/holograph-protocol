<div align="center">
  <a href="https://holograph.xyz"><img alt="Holograph" src="https://user-images.githubusercontent.com/21043504/188220186-9c7f55e0-143a-41b4-a6b8-90e8bd54bfd9.png" width=600></a>
  <br />
  <h1>Holograph Protocol</h1>
</div>
<p align="center">
</p>

## Table of Contents

- [Description](#description)
- [Specification](#specification)
- [Architecture](#architecture)
- [Development](#development)
- [Directories](#directory-structure)
- [Branching](#branching-model-and-releases)
- [Contributing](#contributing)
- [Links](#official-links)
- [License](#license)

## Description

Holograph provides omnichain NFT infrastructure for the web3 ecosystem. Holograph Protocol enables the creation, deployment, minting, & bridging of omnichain NFTs with complete data integrity.

## Specification

Please reference the [documentation](https://docs.holograph.xyz/holograph-protocol/technical-specification) for the full technical specification of the protocol

## Architecture

### Core

#### HolographGenesis

Genesis will be deployed on all blockchains that run and support Holograph Protocol. All main components will be deployed via Genesis. Future blockchains will have a Genesis deployment as well.

#### HolographFactory

Factory enables developers to submit a signed version of the following elements to deploy a “Holographed” smart contract on the blockchain:

- primary deployment chain
- token type (ERC-20, ERC-721, etc.)
- event subscriptions
- custom smart contract bytecode
- custom initialization code

Any additional blockchains that developers want to support can have the same signed data submitted to Factory, allowing for the creation of an identical “Holographed” contract.
The primary job of Factory is to:

- allow propagation of exact data across all blockchains
- ensure a proper standard is selected and used
- ensure all deployments succeed and work as expected
- ensure that security is enforced and impenetrable

#### HolographRegistry

Registry is a central on-chain location where all Holograph data is stored. Registry keeps a record of all currently supported standards. New standards can be introduced and enabled as well. Any properly deployed Holographed contracts are also stored as reference. This allows for a definitive way to identify whether a smart contract is secure and properly Holographed. Verifying entities will be able to identify a Holographed contract to ensure the highest level of security and standards.

#### HolographBridge

Bridge is a universal smart contract that functions as the primary entry and exit point for any Holographed tokens to and from all supported blockchains. Bridge validates and ensures integrity and standard enforcement for every Bridge-In and Bridge-Out request. Additionally, Bridge implements a universal standard for sending tokens across blockchains by abstracting away complexities into sub-modules that remove the burden of management for developers. This allows for simple one-click/one-transaction native gas token payment-based interactions for all bridge requests.

#### HolographOperator

Operator's primary job is to know the messaging protocols that are utilized by the Holograph protocol for all cross-chain messages, and to ensure the authenticity and validity of all requests being submitted. Operator ensures that only valid bridge requests are sent/received and allowed to be executed inside of the protocol.

#### Holograph

Holograph is the primary entry-point for all users and developers. A single, universal address across all blockchains will enable developers an easy way to interact with the protocol’s features. Holograph keeps references for all current Registry, Factory, and Bridge implementations. Furthermore, it allows for single interface management of the underlying Holograph Protocol.
Holograph provides a reference to the name and ID of all supported blockchains. Additionally, it:

- Enables custom smart contract logic that is chain-dependent
- Frees developers from having to query and monitor the blockchain

### Standards Enforcers

#### Holographer

Holographer exists at the core of all Holographed smart contracts, which is applied whenever a Holographed smart contract is deployed. Holographer pieces together all components and routes all inbound function calls to their proper smart contracts, ensuring security and the enforcement of specified standards. Holographer is isolated on its own private layer and is essentially hard-coded into the blockchain.

#### Enforcer

Enforcer enables and ensures complete standards, compliance, and operability for a given standard type. HolographERC20 and HolographERC721 are perfect examples of such Enforcers. Enforcers store and manage all data within themselves to ensure security, compliance, integrity, and enforcement of all protocols. Communication is established with custom contracts via specific event hooks. The storage/data layer is isolated privately and not directly accessible by custom contracts.

#### PA1D

PA1D is an on-chain royalties contract for non-fungible token types. It supports a universal module that understands and speaks all of the different royalty standards on the blockchain. PA1D is built to be extendable and can have new royalty standards implemented as they are created and agreed upon.

#### Interfaces

The Interfaces contract is used to store and share standardized data. It acts as an external library contract. This allows all the Holograph protocol smart contracts to reference a single instance of data and code.

### External Components

#### Custom Contract

Custom contract is any type of smart contract that was developed outside of Holograph Protocol, and is used to create a Holographed contract. This empowers developers to build their projects however they want. The requirements for enabling a custom contract to be Holograph-able are minimal, and allow for even novice-level developers to implement. Any current and future fungible and non-fungible token type contracts can easily be made Holograph-able.

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

### Development with live interaction & manual testing (supports Metamask)

Alternatively you can do live development & testing with Ganache GUI and Remix IDE.  
This solution also supports connecting Metamask to the Ganache's "Custom RPC Provider" and Remix IDE can then use "Injected Provider - Metamask".

Prerequisites

- Ganache https://trufflesuite.com/ganache/
- Remix daemon https://www.npmjs.com/package/@remix-project/remixd
- Remix IDE https://remix.ethereum.org/
- (optional) Metamask browser extension

#### How

1. Run `remixd` daemon on the built `/contracts` folder (not `/src/contracts`)

   ```
   remixd -s contracts
   ```

2. Run Ganache GUI and spin up a local blockchain (using workspace)
3. Open Remix IDE
   1. On the "**File explorer**" card change "Workspaces" -> "- connect to localhost -"
   2. On the "**Deploy & Run Transactions**" card pick "Environment" -> "Ganache Provider"  
      The localhost port is usually `7545` or `8545`
4. After making changes to the contracts in `/src/contracts` run `yarn dev:iterate` to update `/contracts`  
   _(Watch script is coming later)_
5. Development
   1. In "**File Explorer**" card open each relevant contract as a tab
   2. Enable "**Auto compile**" in "Solidity Compiler" card
   3. Interact with the contracts on "Deploy & run transactions" tab  
      To deploy a contract, first focus its tab in the IDE as this changes the "CONTRACT" dropdown.

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
