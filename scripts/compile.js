'use strict';

const fs = require ('fs');
const exec = require ('child_process').exec;
const contractDir = './contracts';

const { NETWORK, SOLIDITY_VERSION } = require ('../config/env');
const config = JSON.parse (
    fs.readFileSync ('./config/compiler.config.json')
);

const assembleCommand = function (config, contracts) {
    let command = config.binary.replace ('SOLIDITY_VERSION', SOLIDITY_VERSION);
    for (let i = 0, l = config.configurations.length; i < l; i++) {
        let c = config.configurations [i];
        command += ' --' + c.value;
        if (!c.toggle) {
            if (typeof (c.variable) !== 'undefined' && c.variable != null && c.variable != '') {
                command += '=' + c.variable;
            }
            else {
                command += ' ' + c.variables.join ();
            }
        }
    }
    command += ' --input-file=' + contracts.join (' --input-file=');
    return command;
};


const getAllContracts = function (contractDir, contracts) {
    let files = fs.readdirSync (contractDir);
    files.forEach (function (file) {
        let stats = fs.statSync (contractDir + '/' + file);
        if (stats.isDirectory ()) {
            // we go into it
            getAllContracts (contractDir + '/' + file, contracts);
        }
        else {
            if (file.endsWith ('.sol')) {
                let contents = fs.readFileSync (contractDir + '/' + file, 'utf8');
                if (contents.includes ('\ncontract ' + file.split ('.') [0])) {
                    console.log (contractDir + '/' + file);
                    contracts.push (contractDir + '/' + file);
                }
            }
        }
    });
};

let contracts = [];
getAllContracts (contractDir, contracts);
let command = assembleCommand (config, contracts);
exec (command, function (error, stdout, stderr) {
    console.log (error);
    console.log (stdout);
    console.log (stderr);
});

/*

    Usage: solc [options] [input_file...]
    Compiles the given Solidity input files (or the standard input if none given or
    "-" is used as a file name) and outputs the components specified in the options
    at standard output or in files in the output directory, if specified.
    Imports are automatically read from the filesystem, but it is also possible to
    remap paths using the context:prefix=path syntax.
    Example:
    solc --bin -o /tmp/solcoutput dapp-bin=/usr/local/lib/dapp-bin contract.sol
    #
    General Information:
      --help               Show help message and exit.
      --version            Show version and exit.
      --license            Show licensing information and exit.
      --input-file arg     input file
    #
    Input Options:
      --base-path path     Use the given path as the root of the source tree
                           instead of the root of the filesystem.
      --include-path path  Make an additional source directory available to the
                           default import callback. Use this option if you want to
                           import contracts whose location is not fixed in relation
                           to your main source tree, e.g. third-party libraries
                           installed using a package manager. Can be used multiple
                           times. Can only be used if base path has a non-empty
                           value.
      --allow-paths path(s)
                           Allow a given path for imports. A list of paths can be
                           supplied by separating them with a comma.
      --ignore-missing     Ignore missing files.
      --error-recovery     Enables additional parser error recovery.
    #
    Output Options:
      -o [ --output-dir ] path
                           If given, creates one file per component and
                           contract/file at the specified directory.
      --overwrite          Overwrite existing files (used together with -o).
      --evm-version version (=london)
                           Select desired EVM version. Either homestead,
                           tangerineWhistle, spuriousDragon, byzantium,
                           constantinople, petersburg, istanbul, berlin or london.
      --experimental-via-ir
                           Turn on experimental compilation mode via the IR
                           (EXPERIMENTAL).
      --revert-strings debug,default,strip,verboseDebug
                           Strip revert (and require) reason strings or add
                           additional debugging information.
      --debug-info arg (=ast-id,location,snippet)
                           Debug info components to be included in the produced EVM
                           assembly and Yul code. Value can be all, none or a
                           comma-separated list containing one or more of the
                           following components: ast-id, location, snippet.
      --stop-after stage   Stop execution after the given compiler stage. Valid
                           options: "parsing".
    #
    Alternative Input Modes:
      --standard-json      Switch to Standard JSON input / output mode, ignoring
                           all options. It reads from standard input, if no input
                           file was given, otherwise it reads from the provided
                           input file. The result will be written to standard
                           output.
      --link               Switch to linker mode, ignoring all options apart from
                           --libraries and modify binaries in place.
      --assemble           Switch to assembly mode, ignoring all options except
                           --machine, --yul-dialect, --optimize and
                           --yul-optimizations and assumes input is assembly.
      --yul                Switch to Yul mode, ignoring all options except
                           --machine, --yul-dialect, --optimize and
                           --yul-optimizations and assumes input is Yul.
      --strict-assembly    Switch to strict assembly mode, ignoring all options
                           except --machine, --yul-dialect, --optimize and
                           --yul-optimizations and assumes input is strict
                           assembly.
      --import-ast         Import ASTs to be compiled, assumes input holds the AST
                           in compact JSON format. Supported Inputs is the output
                           of the --standard-json or the one produced by
                           --combined-json ast
      --lsp                Switch to language server mode ("LSP"). Allows the
                           compiler to be used as an analysis backend for your
                           favourite IDE.
    #
    Assembly Mode Options:
      --machine evm,ewasm  Target machine in assembly or Yul mode.
      --yul-dialect evm,ewasm
                           Input dialect to use in assembly or yul mode.
    #
    Linker Mode Options:
      --libraries libs     Direct string or file containing library addresses.
                           Syntax: <libraryName>=<address> [, or whitespace] ...
                           Address is interpreted as a hex string prefixed by 0x.
    #
    Output Formatting:
      --pretty-json        Output JSON in pretty format.
      --json-indent N (=2) Indent pretty-printed JSON with N spaces. Enables
                           '--pretty-json' automatically.
      --color              Force colored output.
      --no-color           Explicitly disable colored output, disabling terminal
                           auto-detection.
      --error-codes        Output error codes.
    #
    Output Components:
      --ast-compact-json   AST of all source files in a compact JSON format.
      --asm                EVM assembly of the contracts.
      --asm-json           EVM assembly of the contracts in JSON format.
      --opcodes            Opcodes of the contracts.
      --bin                Binary of the contracts in hex.
      --bin-runtime        Binary of the runtime part of the contracts in hex.
      --abi                ABI specification of the contracts.
      --ir                 Intermediate Representation (IR) of all contracts
                           (EXPERIMENTAL).
      --ir-optimized       Optimized intermediate Representation (IR) of all
                           contracts (EXPERIMENTAL).
      --ewasm              Ewasm text representation of all contracts
                           (EXPERIMENTAL).
      --ewasm-ir           Intermediate representation (IR) converted to a form
                           that can be translated directly into Ewasm text
                           representation (EXPERIMENTAL).
      --hashes             Function signature hashes of the contracts.
      --userdoc            Natspec user documentation of all contracts.
      --devdoc             Natspec developer documentation of all contracts.
      --metadata           Combined Metadata JSON whose Swarm hash is stored
                           on-chain.
      --storage-layout     Slots, offsets and types of the contract's state
                           variables.
    #
    Extra Output:
      --gas                Print an estimate of the maximal gas usage for each
                           function.
      --combined-json abi,asm,ast,bin,bin-runtime,devdoc,function-debug,function-debug-runtime,generated-sources,generated-sources-runtime,hashes,metadata,opcodes,srcmap,srcmap-runtime,storage-layout,userdoc
                           Output a single json document containing the specified
                           information.
    #
    Metadata Options:
      --metadata-hash ipfs,none,swarm
                           Choose hash method for the bytecode metadata or disable
                           it.
      --metadata-literal   Store referenced sources as literal data in the metadata
                           output.
    #
    Optimizer Options:
      --optimize           Enable bytecode optimizer.
      --optimize-runs n (=200)
                           The number of runs specifies roughly how often each
                           opcode of the deployed code will be executed across the
                           lifetime of the contract. Lower values will optimize
                           more for initial deployment cost, higher values will
                           optimize more for high-frequency usage.
      --optimize-yul       Legacy option, ignored. Use the general --optimize to
                           enable Yul optimizer.
      --no-optimize-yul    Disable Yul optimizer in Solidity.
      --yul-optimizations steps
                           Forces yul optimizer to use the specified sequence of
                           optimization steps instead of the built-in one.
    #
    Model Checker Options:
      --model-checker-contracts default,<source>:<contract> (=default)
                           Select which contracts should be analyzed using the form
                           <source>:<contract>.Multiple pairs <source>:<contract>
                           can be selected at the same time, separated by a comma
                           and no spaces.
      --model-checker-div-mod-no-slacks
                           Encode division and modulo operations with their precise
                           operators instead of multiplication with slack
                           variables.
      --model-checker-engine all,bmc,chc,none (=none)
                           Select model checker engine.
      --model-checker-invariants default,all,contract,reentrancy (=default)
                           Select whether to report inferred contract inductive
                           invariants. Multiple types of invariants can be selected
                           at the same time, separated by a comma and no spaces. By
                           default no invariants are reported.
      --model-checker-show-unproved
                           Show all unproved targets separately.
      --model-checker-solvers all,cvc4,z3,smtlib2 (=all)
                           Select model checker solvers.
      --model-checker-targets default,all,constantCondition,underflow,overflow,divByZero,balance,assert,popEmptyArray,outOfBounds (=default)
                           Select model checker verification targets. Multiple
                           targets can be selected at the same time, separated by a
                           comma and no spaces. By default all targets except
                           underflow and overflow are selected.
      --model-checker-timeout ms
                           Set model checker timeout per query in milliseconds. The
                           default is a deterministic resource limit. A timeout of
                           0 means no resource/time restrictions for any query.

*/