import { exec } from "child_process";
import { promisify } from "util";


// Promisify exec to use async/await
const execPromise = promisify(exec);

export async function runsh(scriptPath, flag) {
    try {
         
        await execPromise(`bash ${scriptPath} ${flag}`);
        
    } catch (error) {
        console.error(`Error: ${error.message}`);
    }
}


export default runsh;