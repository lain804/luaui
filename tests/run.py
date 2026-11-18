"""Run the single-file library under the Luau CLI with the spec's service doubles."""

from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory


root = Path(__file__).resolve().parents[1]
source = (root / "main.lua").read_text(encoding="utf-8")
spec = (root / "tests/config.luau").read_text(encoding="utf-8")
with TemporaryDirectory() as directory:
    script = Path(directory) / "config.luau"
    script.write_text(spec.replace("-- INSERT LIBRARY HERE", source), encoding="utf-8")
    subprocess.run(["luau", str(script)], check=True)
