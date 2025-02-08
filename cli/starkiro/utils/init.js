import unhandled from 'cli-handle-unhandled';
import welcome from 'cli-welcome';
import { getPackageJson } from 'get-package-json-file';

export default async ({ clear = true }) => {
	unhandled();
	const pkgJson = await getPackageJson(`./../package.json`);

	welcome({
		title: `starkiro cli`,
		tagLine: `by danielcdz`,
		description: pkgJson.description,
		version: pkgJson.version,
		bgColor: '#2200d4',
		color: '#000000',
		bold: true,
		clear
	});
};
