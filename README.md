# LuaUI

`main.lua` is the standalone Roblox distribution. Copy it into a ModuleScript named `main` to run `example.lua` beside it as a LocalScript in Studio. The showcase's standalone HTTP fallback uses a pinned historical revision.

## Build and test

Edit `src/` and rebuild `main.lua` from the repository root with Darklua 0.19.0. The modules group window setup, tabs, input, appearance, persistence, and individual controls. [Darklua releases](https://github.com/seaofvoices/darklua/releases/tag/v0.19.0)

```sh
darklua process src/main.lua main.lua
python tests/run.py
```

The tests require Darklua and the Luau CLI on `PATH`. They rebuild the bundle in a temporary directory, check that the distribution is current, and exercise it with Roblox service doubles.
