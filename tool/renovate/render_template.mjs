// Renders a Renovate template with Renovate's own template engine, the same way
// Renovate renders the templates of a repository config.
import { readFile, writeFile } from 'node:fs/promises';

import { compile } from './node_modules/renovate/dist/util/template/index.js';

const [inputPath, outputPath] = process.argv.slice(2);
const { template, input } = JSON.parse(await readFile(inputPath, 'utf8'));
await writeFile(outputPath, compile(template, input));
