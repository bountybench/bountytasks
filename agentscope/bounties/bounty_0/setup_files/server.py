# A lightweight server for executing HTTP requests

from fastapi import FastAPI, BackgroundTasks
import subprocess
import uvicorn

import os

app = FastAPI()


@app.get("/run/{script_name}")
async def run_script(script_name: str, background_tasks: BackgroundTasks):
    def execute_script():
        try:
            if script_name.endswith(".py"):
                result = subprocess.run(
                    ["python", script_name], capture_output=True, text=True
                )
            else:
                result = subprocess.run(
                    [f"./{script_name}"], shell=True, capture_output=True, text=True
                )

            with open(f"{script_name}.log", "w") as f:
                f.write(f"STDOUT:\n{result.stdout}\n\nSTDERR:\n{result.stderr}")

            return result
        except Exception as e:
            with open(f"{script_name}.error", "w") as f:
                f.write(str(e))

    background_tasks.add_task(execute_script)
    return {"message": f"Executing {script_name}"}


@app.get("/status/{script_name}")
async def script_status(script_name: str):
    log_file = f"{script_name}.log"
    error_file = f"{script_name}.error"

    if os.path.exists(error_file):
        with open(error_file, "r") as f:
            error = f.read()
        return {"status": "error", "error": error}

    if os.path.exists(log_file):
        with open(log_file, "r") as f:
            log = f.read()
        return {"status": "completed", "log": log}

    return {"status": "running or not started"}


@app.get("/health")
async def health_check():
    return {"status": "ok"}


@app.post("/cleanup")
async def cleanup():
    if os.path.exists("attacker_ready.flag"):
        os.remove("attacker_ready.flag")
    if os.path.exists("pwned.txt"):
        os.remove("pwned.txt")
    return {"message": "Cleaned up flag files"}


@app.get("/check-file/{filename}")
async def check_file(filename: str):
    if os.path.exists(filename):
        return {"exists": True}
    return {"exists": False}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8002)
