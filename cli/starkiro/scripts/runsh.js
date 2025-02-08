import { exec } from "child_process";
import { promisify } from "util";
import path from "path";

const execPromise = promisify(exec);

export async function runsh(scriptPath, flag) {
    try {
        const absoluteScriptPath = path.resolve(scriptPath);

        await execPromise(`bash ${absoluteScriptPath} ${flag}`);
    } catch (error) {
        console.error(`Error: ${error.message}`);
    }
}

export default runsh;
