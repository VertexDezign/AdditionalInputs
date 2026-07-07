# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`FS25_additionalInputs` is a **Farming Simulator 25 (FS25) mod** written in Lua (Giants Engine / Luau, Lua 5.1-compatible). It adds explicit vehicle input bindings — car-style turn-signal logic with tip/comfort blink, discrete headlight/worklight/high-beam controls, and Fold/Lower/Activate actions targeting front- or back-attached implements without needing to select them first. Designed around realistic hardware such as the Moza Multi-function Stalks.

For FS25 modding patterns, APIs, and pitfalls, use the **`fs25-modding-skill`**.

## Build / package

There is no compile step; the mod ships as a zip of the source files, built with [FSTools](https://github.com/VertexDezign/FSTools) (the `fs` CLI, installed via `uv tool install --editable .` from an FSTools checkout). `fstools.toml` supplies the packaging config (`zip_name`, `version`, `author`). The output `FS25_additionalInputs.zip` and `.idea/` are gitignored.

Run from this project's root:
- `fs pack` — build `FS25_additionalInputs.zip` (auto-excludes source/docs/VCS; the icon is always kept).
- `fs pack -d` — build and deploy into the FS25 `mods/` folder; `fs pack -p` also launches the game.
- `fs validate` — validate `modDesc.xml`; `fs log` — follow the live game log; `fs test` — run the GIANTS ModHub TestRunner.
- Path overrides via env vars `FS25_MODS_DIR` / `FS25_GAME_DIR` if not auto-detected.

There is no unit-test suite in this repo; behavioral verification is manual in-game (or via `fs test`).

## Versioning — keep these in sync

When bumping the version, update **all three**: `fstools.toml`, `modDesc.xml` (`<version>`), and the `@history` header + changelog in `AI.lua` / `modDesc.xml`. Additionally, `AdditionalInputs.MAJOR_VERSION` / `MINOR_VERSION` in `AI.lua` are a **separate compatibility contract** consumed by the companion `vdTelemetry` mod — bump MAJOR on breaking changes to that integration, MINOR when adding a feature vdTelemetry may depend on.

## Architecture

Two-stage load. `modDesc.xml` lists `GrisuDebug.lua` then `AI.lua` in `<extraSourceFiles>` (loaded globally, in order). `AISpec.lua` is **not** listed there — it is registered at runtime as a vehicle specialization.

- **`AI.lua`** — mod entry point. `init()` runs on load, creates the singleton `g_vdAdditionalInputs` (an `AdditionalInputs` instance) and exposes it globally via `getmetatable(_G).__index`. It reads/writes user settings (log levels) from `modSettings/additionalInputsSettings.xml` in the user profile, creating defaults if absent. It hooks `TypeManager.validateTypes` (via `Utils.prependedFunction`) so that when the `"vehicle"` type manager validates, `installSpec` injects the `AdditionalInputsSpec` specialization into every vehicle type that is `Enterable` but not `Rideable`.

- **`AISpec.lua`** — the `AdditionalInputsSpec` vehicle specialization: all actual behavior. Registers event listeners (`onLoad`, `onEnterVehicle`, `onLeaveVehicle`, `onUpdate`, `onRegisterActionEvents`) and the action-event handlers. Per-vehicle state lives in `self.spec_additionalInputs`.
  - **Indicators**: `vdAISetTurnLightState` wraps `setTurnLightState` but refuses to act when hazard lights are on (hazard has priority). Tip/comfort blink: if an OFF action arrives within 500ms of an ON action, it latches a 3s timer (`indicatorTipDuration`) counted down in `onUpdate` instead of turning off immediately.
  - **Lights**: handlers manipulate `spec_lights.lightsTypesMask` with `bitOR`/`bitAND`/`bitNOT` over `Lights.LIGHT_TYPE_*` flags. Low-beam-on also clears the front work light. High-beam "flash trigger" toggles the beam (on if off, off if on) so a press-and-hold flash works via separate trigger/release actions.
  - **Implements**: `vdAIActionEvent(actionName, callback[, forceState])` is the shared dispatcher. It reads the action-name suffix (`FRONT`/`BACK`), walks `spec_attacherJoints.attachedImplements`, and for each implement whose estimated position matches, invokes `callback`. `vdAIGetAttacherJointPosition` estimates front vs. back by transforming the attacher-joint world position into the vehicle root node's local space and testing the sign of local Z. When a callback returns a new state, it **recurses into that implement** passing `forceState` so nested/chained implements (e.g. front→back) all follow the same state.

- **`GrisuDebug.lua`** — self-contained leveled logger (`TRACE`…`OFF`). `debugger:trace/debug/info/warn/error` accept either a plain string (with `string.format` varargs) or a **closure** returning the string — prefer the closure form for expensive trace messages so they're only built when the level is active. Log levels come from the settings XML (`AI.logging.level` and `AI.logging.specLevel`, the latter applied to per-vehicle spec loggers).

## Conventions

- All public identifiers are namespaced `VD_AI_` (actions/l10n) or `vdAI`/`vd`-prefixed (functions/globals) to avoid clashes with the base game and other mods.
- Every new action needs, in lockstep: an `<action>` in `modDesc.xml`, an `input_VD_AI_*` entry in **both** `l10n/l10n_en.xml` and `l10n/l10n_de.xml`, and an `addActionEvent` registration in `AISpec.lua:onRegisterActionEvents`. Default keybinds are optional (`<inputBinding>` in `modDesc.xml`); several actions intentionally ship unbound for the user to assign.
- Commit messages use gitmoji (✨ feature, 🔨 chore/refactor, 🚑 fix, 📖 docs, ⬆️ version bump).
