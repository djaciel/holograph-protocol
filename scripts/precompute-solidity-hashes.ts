import { promises as fs } from 'fs';
import * as path from 'path';
const Web3 = require('web3');
const web3 = new Web3();

const removeX = (input: string): string => (input.startsWith('0x') ? input.substring(2) : input);

const hexify = (input: string, prepend: boolean = true): string => {
  input = input.toLowerCase().trim();
  input = removeX(input);
  input = input.replace(/[^0-9a-f]/g, '');
  return prepend ? '0x' + input : input;
};

// Define all regexes
const regexes = [
  { regex: /precomputeslot\("([^"]+)"\)/i, process: (match: string) => computeSlot(match) },
  { regex: /precomputeslothex\("([^"]+)"\)/i, process: (match: string) => computeSlotHex(match) },
  { regex: /precomputekeccak256\("([^"]*)"\)/i, process: (match: string) => computeKeccak256(match) },
  { regex: /functionsig\("([^"]+)"\)/i, process: (match: string) => computeFunctionSig(match) },
  { regex: /asciihex\("([^"]+)"\)/i, process: (match: string) => computeAsciiHex(match) },
];

const computeSlot = (input: string): string => {
  // Directly compute the hash
  const hash = web3.utils.soliditySha3({ type: 'string', value: input }) || '';

  // Convert hash to BN, subtract 1, and ensure correct hex formatting
  let slot = web3.utils.toHex(web3.utils.toBN(hash).sub(web3.utils.toBN(1)));

  // Pad the hex string to 64 characters, ensuring it starts with '0x'
  slot = '0x' + slot.substring(2).padStart(64, '0');

  return slot;
};

const computeSlotHex = (input: string): string => {
  const hash = web3.utils.soliditySha3({ type: 'string', value: input }) || '';
  return 'hex"' + hexify(hash.substring(2), false) + '"';
};

const computeKeccak256 = (input: string): string => web3.utils.keccak256(input) || '0x';

const computeFunctionSig = (input: string): string => {
  const hash = web3.utils.keccak256(web3.eth.abi.encodeFunctionSignature(input));
  return hash.substring(0, 10);
};

const computeAsciiHex = (input: string): string => '0x' + web3.utils.asciiToHex(input).substring(2).padStart(64, '0');

// Recursively read directory for .sol files
const readDirRecursively = async (dir: string, fileList: string[] = []): Promise<string[]> => {
  const files = await fs.readdir(dir, { withFileTypes: true });
  for (const file of files) {
    const filePath = path.join(dir, file.name);
    if (file.isDirectory()) {
      await readDirRecursively(filePath, fileList);
    } else if (file.name.endsWith('.sol')) {
      fileList.push(filePath);
    }
  }
  return fileList;
};

// Process each file
const processFile = async (filePath: string): Promise<void> => {
  let content = await fs.readFile(filePath, { encoding: 'utf8' });
  const lines = content.split(/\r?\n/); // Split content into lines

  for (let [index, line] of lines.entries()) {
    for (let { regex, process } of regexes) {
      const match = line.match(regex);
      if (match) {
        const lineNumber = index + 1; // Line numbers are usually 1-based
        const originalText = match[0];
        const replacement = process(match[1]);
        console.log(`File: ${filePath}\nLine: ${lineNumber}\nOriginal: ${originalText}\nReplacement: ${replacement}\n`);

        // Perform the replacement on the line (if we decide to modify the content directly)
        // This example modifies the line directly within the array of lines.
        // lines[index] = line.replace(regex, (_) => replacement);
      }
    }
  }
};

// If you want to modify the lines array (e.g., by replacing text within lines),
// you would rejoin the modified lines back into a single string to reflect changes.
// This step is necessary if you uncomment the line modification above.
// content = lines.join('\n');

// If modifications were made and you want to save the changes back to the file:
// await fs.writeFile(filePath, content, { encoding: 'utf8' })

// Main function to find and process files
const main = async () => {
  console.log('Finding .sol files...');
  const srcDir = path.join(__dirname, '../src'); // Adjust based on actual path
  const files = await readDirRecursively(srcDir);
  console.log(`Found ${files.length} .sol files`);

  for (const file of files) {
    await processFile(file);
  }
};

main().catch(console.error);
