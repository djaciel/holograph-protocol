'use strict';

const fs = require('fs');
const buildDir = './src';
const deployDir = './contracts';

const { NETWORK } = require('../config/env');
const buildConfig = JSON.parse(
    fs.readFileSync('./config/build.config.json', 'utf8')
);
const config = JSON.parse(
    fs.readFileSync('./config/' + NETWORK + '.config.json', 'utf8')
);

const replaceValues = function(data) {
    Object.keys(buildConfig).forEach(function(key, index) {
        data = data.replace(new RegExp(buildConfig[key], 'gi'), config[key]);
    });
    return data;
};

const recursiveBuild = function(buildDir, deployDir) {
    fs.readdir(buildDir, function(err, files) {
        if(err) {
            throw err;
        }
        files.forEach(function(file) {
            fs.stat(buildDir + '/' + file, function(err, stats) {
                if(err) {
                    throw err;
                }
                if(stats.isDirectory()) {
                    // we go into it
                    fs.mkdir(deployDir + '/' + file, function() {
                        recursiveBuild(
                            buildDir + '/' + file,
                            deployDir + '/' + file
                        );
                    });
                }
                else {
                    if(file.endsWith('.sol')) {
                        console.log(file);
                        fs.readFile(
                            buildDir + '/' + file,
                            'utf8',
                            function(err, data) {
                                if(err) {
                                    throw err;
                                }
                                fs.writeFile(
                                    deployDir + '/' + file,
                                    replaceValues(data),
                                    function(err) {
                                        if(err) {
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
fs.mkdir(deployDir, function() {
    recursiveBuild(buildDir, deployDir);
});
