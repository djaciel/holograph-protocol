'use strict';

const fs = require ('fs');
const web3 = new (require ('web3')) ();
const buildDir = './src';
const deployDir = './contracts';

const { NETWORK } = require ('../config/env');
const buildConfig = JSON.parse (fs.readFileSync ('./config/build.config.json', 'utf8'));
const license = fs.readFileSync ('./config/license', 'utf8');
const config = Object.assign (
    {
        holographLicenseHeader: license
    },
    JSON.parse (fs.readFileSync ('./config/' + NETWORK + '.config.json', 'utf8'))
);

const removeX = function (input) {
    if (input.startsWith ('0x')) {
        return input.substring (2);
    }
    else {
        return input;
    }
};

const hexify = function (input, prepend) {
	input = input.toLowerCase ().trim ();
	input = removeX (input);
	input = input.replace (/[^0-9a-f]/g, '');
	if (prepend) {
	    input = '0x' + input;
	}
	return input;
};

const slotRegex = /precomputeslot\('([^']+)'\)/i;
const precomputeSlots = function (text) {
    let result, str, slot, index;
    while ( (result = text.match(slotRegex)) ) {
        str = result [0];
        slot = '0x' + hexify (
            web3.utils.toHex (
                web3.utils.toBN (
                    web3.utils.keccak256 (
                        result [1]
                    )
                ).sub (web3.utils.toBN (1))
            ),
            false
        ).padStart (64, '0');
        index = result.index;
        text = text.slice (0, index) + slot + text.slice (index + str.length);
    }
    return text;
};

const replaceValues = function (data) {
    data = precomputeSlots (data);
    Object.keys (buildConfig).forEach (function (key, index) {
        data = data.replace (
            new RegExp (buildConfig [key], 'gi'),
            config [key]
        );
    });
    return data;
};

const recursiveBuild = function (buildDir, deployDir) {
    fs.readdir (buildDir, function (err, files) {
        if (err) {
            throw err;
        }
        files.forEach (function (file) {
            fs.stat (buildDir + '/' + file, function (err, stats) {
                if (err) {
                    throw err;
                }
                if (stats.isDirectory ()) {
                    // we go into it
                    fs.mkdir (deployDir + '/' + file, function () {
                        recursiveBuild (
                            buildDir + '/' + file,
                            deployDir + '/' + file
                        );
                    });
                }
                else {
                    if (file.endsWith ('.sol')) {
                        console.log (file);
                        fs.readFile (
                            buildDir + '/' + file,
                            'utf8',
                            function (err, data) {
                                if (err) {
                                    throw err;
                                }
                                fs.writeFile (
                                    deployDir + '/' + file,
                                    replaceValues (data),
                                    function (err) {
                                        if (err) {
                                            throw err;
                                        }
                                    }
                                );
                            }
                        );
                    }
                }
            });
        });
    });
};

fs.mkdir (deployDir, function () {
    recursiveBuild (buildDir, deployDir);
});
