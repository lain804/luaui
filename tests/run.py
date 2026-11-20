"""Run the library specs under the Luau CLI with Roblox service doubles."""

from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory


root = Path(__file__).resolve().parents[1]
source = (root / "main.lua").read_text(encoding="utf-8")
with TemporaryDirectory() as directory:
    for name in ("config.luau", "focus.luau"):
        script = Path(directory) / name
        template = (root / "tests" / name).read_text(encoding="utf-8")
        script.write_text(template.replace("-- INSERT LIBRARY HERE", source), encoding="utf-8")
        subprocess.run(["luau", str(script)], check=True)
