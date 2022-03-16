'use strict';

const fs = require ('fs');
const buildDir = './build';
const abiDir = './abi';

const contracts = JSON.parse (
    fs.readFileSync (buildDir + '/combined.json')
).contracts;

const recursiveBuild = function () {
    Object.keys (contracts).forEach (function (key, index) {
        let splits = key.split (':');
        let fileName = splits [0];
        let contractName = splits [1];
        let path = fileName.split ('/');
        path.pop ();
        if (path.length > 0) {
            fs.mkdirSync (abiDir + '/' + path.join ('/'), { recursive: true });
        }
        path.push (contractName + '.json');
        fs.writeFileSync (
            abiDir + '/' + path.join ('/'),
            JSON.stringify (contracts [key].abi, null, 4)
        );
        console.log ('Created ' + abiDir + '/' + path.join ('/') + ' ABI');
    });
};
fs.mkdir (abiDir, function () {
    recursiveBuild ();
});
