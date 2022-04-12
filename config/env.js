const env = require ('dotenv');
const path = require ('path');

// grab root .env file
env.config ({
    path: path.join (__dirname, '../.env')
});

// grab local .env file if it exists
env.config ({});

if (process.env.NETWORK_TYPE == '2') {
    let tempNetwork = process.env.NETWORK;
    process.env.NETWORK = process.env.NETWORK2;
    process.env.NETWORK2 = tempNetwork;
}

module.exports = {
    NODE_ENV,
    PRIVATE_KEY,
    WALLET,
    MNEMONIC,
    NETWORK,
    GAS
} = process.env;
