"""Run the library specs under the Luau CLI with Roblox service doubles."""

from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory


root = Path(__file__).resolve().parents[1]
with TemporaryDirectory() as directory:
    bundle = Path(directory) / "main.lua"
    subprocess.run(["darklua", "process", "src/main.lua", str(bundle)], cwd=root, check=True)
    source = bundle.read_text(encoding="utf-8")
    if source != (root / "main.lua").read_text(encoding="utf-8"):
        raise SystemExit("main.lua is stale. Run darklua process src/main.lua main.lua")

    for name in ("config.luau", "focus.luau"):
        script = Path(directory) / name
        template = (root / "tests" / name).read_text(encoding="utf-8")
        script.write_text(template.replace("-- INSERT LIBRARY HERE", source), encoding="utf-8")
        subprocess.run(["luau", str(script)], check=True)
