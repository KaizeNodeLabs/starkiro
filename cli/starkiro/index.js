#!/usr/bin/env node

/**
 * starkiro
 * Starknet DevSuite Install CLI
 *
 * @author danielcdz <https://github.com/danielcdz>
 */

import cli from './utils/cli.js';
import executeScript from './utils/excecuteScript.js';
import init from './utils/init.js';
import log from './utils/log.js';

const { flags, input, showHelp } = cli;
const { clear, debug } = flags;

(async () => {
	await init({ clear });
	input.includes('help') && showHelp(0);
	debug && log(flags);

	if(input.includes('install')){
		await executeScript('bash/install_asdf.sh', '', "Installing asdf...", "asdf installed successfully!", "Installation failed.");
        await executeScript('bash/plugin_add.sh', '--plugin scarb', "Adding scarb plugin...", "scarb plugin added successfully!", "Installation failed.");
        await executeScript('bash/plugin_add.sh', '--plugin starknet-foundry', "Adding starknet-foundry plugin...", "starknet-foundry plugin added successfully!", "Installation failed.");
        await executeScript('bash/install_plugin.sh', '--plugin scarb --version latest', "Installing scarb plugin...", "scarb plugin installed successfully!", "Installation failed.");
        await executeScript('bash/install_plugin.sh', '--plugin starknet-foundry --version latest', "Installing starknet-foundry plugin...", "starknet-foundry plugin installed successfully!", "Installation failed.");
	}
	if(input.includes('install-versions')){
		console.log("Installing versions");
	}
	if(input.includes('interactive')){
		console.log("Interacrive");
	}
})();
