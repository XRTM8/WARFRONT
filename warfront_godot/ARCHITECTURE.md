# WarFront RTS — Architectural Governance & Modularity Standard

This document establishes the strict architectural guidelines, design patterns, and engineering standards for the WarFront RTS codebase. All existing code and future features must strictly adhere to these principles.

---

## 1. Core Principles

1. **Single Responsibility Principle (SRP)**: Each file owns exactly one distinct domain concern (e.g., weapon sound synthesis, unit spawning, crowd flocking, mission debriefing).
2. **Strict Size Limits**:
   - Ideal module size: **100 – 300 lines**.
   - Absolute ceiling: **500 lines** (files exceeding 400 lines must be reviewed for modular decomposition).
3. **Zero Breakage & Facade Pattern**:
   - Subsystem coordinators (`SimUnits`, `SoundSynth`, `MapGen`, `HUDModal`, etc.) serve as unified facades that delegate to specialized child modules.
   - Existing caller call-sites (`main.gd`, `test_runner.gd`, `hud.gd`) remain 100% backward compatible without signature churn.
4. **Clean Domain Separation**:
   - `Sim*`: Pure simulation logic, deterministic math, state updates, combat, and pathfinding. Never import or instantiate UI/Canvas controls directly.
   - `Render*`: 2D draw routines, CanvasItem custom rendering, visual FX, and sprite batching.
   - `Audio*`: Procedural DSP synthesis, math oscillators, filter pipelines, and voice pooling.
   - `HUD*`: User interface components, tactical dossiers, minimap radar, action bars, and military modal dialogs.
   - `MapGen*`: Theater layout generators, tile placement, road graph construction, and terrain synthesis.
5. **No Slop & Professional Polish**:
   - No emojis in UI strings, console logs, or code comments.
   - Precise military terminology (NATO brevity codes, tactical callouts, structured telemetry).
   - Zero placeholder stubs, `TODO: implement later`, or mock returns.

---

## 2. Directory & Module Classification

```
warfront_godot/
├── scripts/
│   ├── audio_dsp_helpers.gd      # Low-level WAV construction & DSP math filters
│   ├── audio_weapons.gd          # Procedural weapon fire audio synthesizers
│   ├── audio_impacts.gd          # Explosions, crashes, debris, and ricochet DSP
│   ├── audio_comms.gd            # Radio squelch, air raid sirens, vocal formants
│   ├── audio_ui.gd               # Military UI feedback chimes and order stabs
│   ├── sound_synth.gd            # Polyphonic voice pool manager (Audio Facade)
│   │
│   ├── map_gen_utils.gd          # Map RNG, road segment painting, tile placement
│   ├── map_gen_standard.gd       # 1v1 Theater generator (Kirkuk, Suez, New York)
│   ├── map_gen_large.gd          # 4-Player Large Theater generator (Basra, Zagros)
│   ├── map_gen.gd                # Theater generation dispatcher (MapGen Facade)
│   │
│   ├── sim_unit_spawner.gd       # Unit recruitment, starter forces, turret placement
│   ├── sim_unit_abilities.gd     # Veteran hero abilities, napalm, hydra, landmines
│   ├── sim_unit_movement.gd      # Crowd flocking, formations, reverse/retreat physics
│   ├── sim_unit_commands.gd      # Box selection, player order dispatching, stances
│   ├── sim_units.gd              # Unit lifecycle coordinator (Units Facade)
│   │
│   ├── sim_hazards.gd            # Flying turrets, napalm DoT, proximity landmines
│   ├── sim_combat.gd             # Ballistics, projectile physics, damage resolution
│   ├── sim_buildings.gd          # Base building, scaffolds, repair auras, sandbags
│   ├── sim_commander.gd          # Off-map airstrikes, cargo airdrops, recon UAVs
│   ├── sim_logistics.gd          # Oil trucks, depot routing, convoy escorts
│   ├── sim_ai.gd                 # Multi-agent autonomous AI, stances, combined arms
│   ├── simulation.gd             # Core simulation tick, match state, alliances
│   │
│   ├── hud_modal_common.gd       # Tactical military UI styling & button builders
│   ├── hud_modal_debrief.gd      # Post-battle debriefing statistics panel
│   ├── hud_modal_manual.gd       # Field manual & theater browser modals
│   ├── hud_modal_lobby.gd        # 4-way FFA / 2v2 Alliance lobby setup modal
│   ├── hud_modal.gd              # Tactical operations coordinator (Modal Facade)
│   │
│   ├── hud.gd                    # Primary HUD orchestrator
│   ├── hud_top_bar.gd            # Oil meters, timer, phase, doctrine indicators
│   ├── hud_minimap.gd            # Radar overview, camera frustum, ping pings
│   ├── hud_action_bar.gd         # Build buttons, ability triggers, rally setter
│   ├── hud_dossier.gd            # Selected unit specs, kill counter, rank insignia
│   └── hud_commander_bar.gd      # Tactical airstrike & airdrop command bar
```

---

## 3. Strict Rules for Adding New Features

Whenever a new feature, system, or mechanic is introduced:

### Rule 1: Evaluate Scope & Domain
Determine if the feature belongs to an existing domain (`Sim`, `Audio`, `Render`, `HUD`, `MapGen`). If the parent file is already above 250 lines, **DO NOT add raw code directly to the parent**.

### Rule 2: Create a Dedicated Submodule
Create a new dedicated script file named according to its domain:
- Example: A new electronic warfare feature belongs in `scripts/sim_electronic_warfare.gd`, not inside `sim_combat.gd`.
- Example: New naval units belong in `scripts/sim_naval_units.gd`, not appended into `sim_units.gd`.

### Rule 3: Expose Public API via the Parent Facade
Import the child submodule in the parent coordinator via `preload`:
```gdscript
const SimElectronicWarfare = preload("res://scripts/sim_electronic_warfare.gd")

static func trigger_emp_strike(sim, target_pos: Vector2) -> bool:
    return SimElectronicWarfare.trigger_emp_strike(sim, target_pos)
```
This guarantees existing test suites, UI calls, and simulation hooks continue to work seamlessly.

### Rule 4: Zero Circular Preload Dependencies
In GDScript, circular `preload` statements cause runtime parse errors.
- Pass the `sim` instance down into methods (`func do_action(sim, ...)`) instead of having submodules circularly preload parent facades.
- Call core simulation methods directly on `sim` (e.g. `sim.damage_unit(...)`, `sim.spawn_particle(...)`, `sim.sound_triggered.emit(...)`).

### Rule 5: Automated Verification Requirement
Every new feature MUST include automated tests in `test_runner.gd`.
- Both direct submodule invocations and parent facade invocations must be tested.
- `test_runner.gd` must run and exit with code 0 before any code is committed or merged.
