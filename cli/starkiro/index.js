#!/usr/bin/env node

/**
 * starkiro
 * Starknet DevSuite Install CLI
 *
 * @author danielcdz <https://github.com/danielcdz>
 */

import * as p from '@clack/prompts';
import { setTimeout } from 'node:timers/promises';
import cli from './utils/cli.js';
import init from './utils/init.js';
import log from './utils/log.js';
import ora from "ora"; // Ensure you have installed ora package
import runsh from './scripts/runsh.js'

const { flags, input, showHelp } = cli;
const { clear, debug } = flags;

(async () => {
	await init({ clear });
	input.includes('help') && showHelp(0);
	debug && log(flags);

	if(input.includes('install')){
		let spinner = ora("Installing asdf...").start();
		try {
			await runsh('/Users/danielcdz/Repos/starkiro/cli/starkiro/bash/install_asdf.sh', '');
			
			spinner.succeed("asdf installed successfully!"); // Stop the spinner
		} catch (error) {
			spinner.fail("Installation failed.");
		}

		spinner = ora("Adding scarb plugin...").start();
		try {
			await runsh('/Users/danielcdz/Repos/starkiro/cli/starkiro/bash/plugin_add.sh', '--plugin scarb');
			
			spinner.succeed("scarb plugin added successfully!"); // Stop the spinner
		} catch (error) {
			spinner.fail("Installation failed.");
		}

		spinner = ora("Adding starknet-foundry plugin...").start();
		try {
			await runsh('/Users/danielcdz/Repos/starkiro/cli/starkiro/bash/plugin_add.sh', '--plugin starknet-foundry');
			
			spinner.succeed("starknet-foundry plugin added successfully!"); // Stop the spinner
		} catch (error) {
			spinner.fail("Installation failed.");
		}

		spinner = ora("Installing scarb plugin...").start();
		try {
			await runsh('/Users/danielcdz/Repos/starkiro/cli/starkiro/bash/install_plugin.sh', '--plugin scarb --version latest');
			
			spinner.succeed("scarb plugin installed successfully!"); // Stop the spinner
		} catch (error) {
			spinner.fail("Installation failed.");
		}

		spinner = ora("Installing starknet-foundry plugin...").start();
		try {
			await runsh('/Users/danielcdz/Repos/starkiro/cli/starkiro/bash/install_plugin.sh', '--plugin starknet-foundry --version latest');
			
			spinner.succeed("starknet-foundry plugin installed successfully!"); // Stop the spinner
		} catch (error) {
			spinner.fail("Installation failed.");
		}
	}
	if(input.includes('install-versions')){
		console.log("Installing versions");
	}
	if(input.includes('interactive')){
		console.log("Interacrive");
	}
})();
