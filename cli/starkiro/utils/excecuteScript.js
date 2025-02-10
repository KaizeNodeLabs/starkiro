import ora from "ora";
import runsh from "../scripts/runsh.js"; 

const executeScript = async (scriptPath, args, startMessage, successMessage, failureMessage) => {
    const spinner = ora(startMessage).start();
    try {
        await runsh(scriptPath, args);
        spinner.succeed(successMessage);
    } catch (error) {
        spinner.fail(failureMessage);
    }
};

export default executeScript;
