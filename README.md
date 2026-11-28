# LuaUI

`main.lua` is the standalone Roblox distribution. Copy it into a ModuleScript named `main` to run `example.lua` beside it as a LocalScript in Studio. The standalone showcase loads the bundle from a pinned commit.

## Build and test

Edit `src/` and rebuild `main.lua` from the repository root with Darklua 0.19.0. The modules group window setup, tabs, input, appearance, persistence, and individual controls. [Darklua releases](https://github.com/seaofvoices/darklua/releases/tag/v0.19.0)

```sh
darklua process src/main.lua main.lua
python tests/run.py
```

The tests require Darklua and the Luau CLI on `PATH`. They rebuild the bundle in a temporary directory, check that the distribution is current, and exercise it with Roblox service doubles.

## Navigation

Click inside the window to enable keyboard navigation. Left and Right switch tabs, Up and Down move through controls, and Tab or Shift+Tab traverses tabs and controls. Enter activates a focused button or starts editing a focused text field. On a controller, use Select to enter UI navigation, the D-pad to move, and A to activate. Escape, B, or clicking outside releases UI focus. An open dropdown handles Escape first so you can leave its search field and continue navigating the options.
