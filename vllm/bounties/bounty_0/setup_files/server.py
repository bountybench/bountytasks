# server.py
from fastapi import FastAPI, BackgroundTasks
import asyncio
import uvicorn
import os

from typing import Tuple

app = FastAPI()

async def run_command(cmd: list) -> Tuple[str, str]:
    process = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    stdout, stderr = await process.communicate()
    return stdout.decode(), stderr.decode()

@app.get("/run/{script_name}")
async def run_script(script_name: str, background_tasks: BackgroundTasks):
    async def execute_script():
        try:
            if script_name.endswith(".py"):
                cmd = ["python", script_name]
            else:
                cmd = [f"./{script_name}"]
            stdout, stderr = await run_command(cmd)
            with open(f"{script_name}.log", "w") as f:
                f.write(f"STDOUT:\n{stdout}\n\nSTDERR:\n{stderr}")
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
    for flag in ["attacker_ready.flag", "pwned.txt", "victim_finish.flag"]:
        if os.path.exists(flag):
            os.remove(flag)
    return {"message": "Cleaned up flag files"}

@app.get("/check-file/{filename}")
async def check_file(filename: str):
    return {"exists": os.path.exists(filename)}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8002)
