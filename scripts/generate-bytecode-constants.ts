import * as fs from 'fs';
import * as path from 'path';

const artifactsDir = path.join(__dirname, '../artifacts');
const outputPath = path.join(__dirname, '../test/foundry', 'Bytecodes.sol');

// header of the solidity library file
let solContent = `// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Bytecodes {\n`;

// read all the directories in the artifacts folder
const contractDirs = fs
  .readdirSync(artifactsDir, { withFileTypes: true })
  .filter((dirent) => dirent.isDirectory() && dirent.name.endsWith('.sol'))
  .map((dirent) => dirent.name);

contractDirs.forEach((contractDir) => {
  const jsonFilePath = path.join(artifactsDir, contractDir, contractDir.replace('.sol', '.json'));
  console.log('Checking', jsonFilePath);
  if (fs.existsSync(jsonFilePath)) {
    console.log('Processing', jsonFilePath);
    const jsonContent = fs.readFileSync(jsonFilePath, 'utf-8');
    const artifact = JSON.parse(jsonContent);

    if (artifact.deployedBytecode && artifact.deployedBytecode.object && artifact.deployedBytecode.object !== '0x') {
      const deployedBytecode = artifact.deployedBytecode.object;
      const functionName = `get${contractDir.replace('.sol', '').replace(/\W/g, '_')}`;
      solContent += `  function ${functionName}() internal pure returns (bytes memory) {\n    return hex"${deployedBytecode.slice(
        2
      )}";\n  }\n\n`;
    }
  }
});

solContent += '}';

// write or overwrite the solidity library file
fs.writeFileSync(outputPath, solContent, 'utf8');
console.log(`Bytecodes.sol generated at ${outputPath}`);
