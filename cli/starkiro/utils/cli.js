import meowHelp from 'cli-meow-help';
import meow from 'meow';

const flags = {
	"snfoundry": {
		type: `string`,
		default: "latest",
		shortFlag: `-s`,
		desc: `Version of Starknet Foundry to install`
	},
	"scarb": {
		type: `string`,
		default: "latest",
		shortFlag: `-s`,
		desc: `Version of scarb to install`
	},

};

const commands = {
	"help": { desc: `Print help info` },
	"install": { desc: `Install all latest versions to develop on Starknet` },
	"install-versions": { desc: `Install given versions to develop on Starknet` },
	"interactive": { desc: `Opens interactive mode` },
	
};

const helpText = meowHelp({
	name: `starkiro`,
	flags,
	commands
});

const options = {
	importMeta: import.meta,
	inferType: true,
	description: false,
	hardRejection: false,
	flags
};

export default meow(helpText, options);
