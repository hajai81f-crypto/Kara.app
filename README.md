# Arrow Legends 3D

A mobile-first, 3D procedural archery game built in Godot 4 (GDScript). Players
aim and fire a bow at targets, bosses and challenges across stages that are
generated on the fly by a rule-constrained procedural system, with difficulty
that adapts to how well the player is doing.

> **Build status: Phase 1 of 14 complete.** This repository is being built in
> the ordered phases listed below, each one landing real, runnable code — no
> stubs pretending to be features. See "Roadmap status" for exactly what
> works today versus what's still to come.

## Features (implemented so far)

- Full autoload architecture: `GameManager`, `EventBus`, `SaveManager`,
  `AudioManager`, `EconomyManager`, `DifficultyManager`, `StageGenerator`,
  `StageValidator`, `MissionManager`, `AchievementManager`, `DebugTools`.
- **Dynamic Stage Generation System** — seeded, controlled procedural stage
  generation across 11 stage types and 8 environments.
- **Stage Validator** — rejects unreachable targets, obstacles blocking
  spawn, out-of-bounds targets, unreasonable timers, and unbalanced
  rewards, then triggers automatic regeneration with a new seed.
- **Adaptive Difficulty System** — rolling performance window drives a
  smoothed difficulty multiplier (never snaps instantly, never impossible).
- **Save System** — JSON save at `user://save_data.json` with automatic
  backup-before-write.
- **Economy** — coins/gems/XP rewards, no pay-to-win hooks.
- **Daily Missions** and **Achievements** — real, save-backed progress
  tracking.
- **Audio Manager** — pooled SFX players, music crossfade, bus-driven volume.
- Functional Main Menu wired to real save data (stats, missions,
  achievements are live; screens not yet built say so honestly instead of
  being dead buttons).
- Headless test suite covering the generator, validator, and difficulty
  system (see `tests/`).
- GitHub Actions CI that runs the test suite and builds a debug Android APK.

## Requirements

- [Godot Engine 4.3+](https://godotengine.org/download) (standard, non-.NET
  build — this project uses GDScript only).
- For Android export: Java JDK 17, Android SDK/cmdline-tools, and Gradle
  (Godot's Android export template installs most of this automatically via
  **Editor → Manage Export Templates**).

## How to Open

1. Install Godot 4.3 or newer.
2. Open Godot, choose **Import**, and select `project.godot` from this
   repository.
3. Let Godot import all resources on first open.

## How to Run

- Press **F5** in the Godot editor, or run:
  ```bash
  godot --path . 
  ```
- The game boots to `scenes/Boot.tscn`, loads (or creates) the save file,
  then shows the Main Menu. Press **PLAY** to generate and validate a real
  stage via `StageGenerator` / `StageValidator` (the playable 3D gameplay
  scene itself lands in Phase 3 — right now `GameManager` completes the
  full generate → validate → reward → save loop against the data layer).

## How to Export Android

1. In the Godot editor: **Editor → Manage Export Templates** → download
   templates for your installed version.
2. **Project → Export** → the `Android` preset from `export_presets.cfg`
   is already configured (arm64-v8a, landscape, min SDK 24, target SDK 34).
3. Click **Export Project** for a debug APK, or use the second preset,
   **"Android (AAB - Google Play)"**, for a release bundle.
4. Command-line equivalent:
   ```bash
   godot --headless --export-debug "Android" builds/android/ArrowLegends3D.apk
   ```
5. For a signed release AAB, add your real keystore credentials to
   `export_presets.cfg` locally (never commit them — see `.gitignore`) or
   supply them as GitHub Actions secrets for CI signing.

## Project Structure

```
arrow-legends-3d/
├── scenes/            # .tscn scene files (ui/, player/, enemies/, stages/, bosses/)
├── scripts/
│   ├── core/          # Constants, EventBus, GameManager
│   ├── gameplay/      # EconomyManager, MissionManager, AchievementManager
│   ├── stages/        # StageConfig, StageGenerator, StageValidator, DifficultyManager
│   ├── save/          # SaveManager
│   ├── audio/         # AudioManager
│   ├── ui/            # MainMenu, BootScreen
│   ├── player/        # (Phase 2)
│   ├── weapons/       # (Phase 2)
│   ├── enemies/       # (Phase 3+)
│   └── utilities/     # DebugTools
├── assets/            # models/, textures/, materials/, audio/, particles/, animations/
├── resources/         # shared .tres resources
├── shaders/           # custom mobile-friendly shaders
├── data/              # data-driven config (bow/arrow stat tables, etc.)
├── tests/             # headless test runner
├── android/            # Android-specific export assets (icons, splash)
├── .github/workflows/ # CI pipeline
├── project.godot
├── export_presets.cfg
├── .gitignore
└── LICENSE
```

## Controls (current + planned)

- **Touch drag** — aim the bow (Phase 2).
- **Hold** — draw/charge the shot (Phase 2).
- **Release** — fire the arrow (Phase 2).
- **F3** (editor/desktop) — toggle the on-screen debug overlay (implemented
  now, see `DebugTools.gd`).

## Roadmap status

| Phase | Scope | Status |
|---|---|---|
| 1 | Core Architecture (autoloads, stage generation/validation, save, audio, economy, missions, achievements, menu, tests, CI, Android export config) | **Done** |
| 2 | Player + Bow + Arrow (movement, aiming, real arrow physics, bow/arrow inventory) | Pending |
| 3 | Gameplay scene (3D arena, target instancing, stage flow tied to real scenes) | Pending |
| 4 | Environments (8 biomes: skybox, lighting, fog, weather, ambient audio) | Pending |
| 5 | Boss system (health, weak points, phases, attack patterns) | Pending |
| 6 | Combo system, VFX, camera system | Pending |
| 7 | Upgrades, bow/arrow unlock economy UI | Pending |
| 8 | Full UI/UX (World map, Bows, Arrows, Upgrades, Settings screens) | Pending |
| 9 | Additional audio/VFX polish pass | Pending |
| 10 | Save system UI (slots, settings persistence UI) | Pending |
| 11 | Performance pass (LOD, culling, object pooling audit) | Pending |
| 12 | Expanded automated test coverage | Pending |
| 13 | Android build polish (icons, splash, signing docs) | Pending |
| 14 | GitHub/CI polish | Partially done (workflow exists, see `.github/workflows/build.yml`) |

## Build Instructions

See "How to Run" and "How to Export Android" above. For CI, push to `main`
or open a pull request — `.github/workflows/build.yml` runs the headless
test suite and, on success, builds a debug APK artifact automatically.

## Testing Instructions

```bash
godot --headless --script tests/run_tests.gd
```

This runs the suite in `tests/run_tests.gd` covering `StageGenerator`
(seed reproducibility, difficulty scaling), `StageValidator` (rejects
broken stages, accepts valid ones), and `DifficultyManager` (adapts up on
wins, down on losses). Exit code is non-zero on any failure, so it's CI-safe.

## Troubleshooting

- **"Scene not found" warning in the log on boot** — expected right now:
  `GameManager` looks for gameplay scenes that land in Phase 3. The
  generate/validate/reward loop still runs against the data layer.
- **Android export fails with "no export templates"** — run
  **Editor → Manage Export Templates** and download the version matching
  your Godot install.
- **Gradle build fails** — confirm JDK 17 is on `PATH` and that you ran
  **Project → Install Android Build Template** at least once.
- **Tests fail to run headless** — make sure you're invoking Godot with
  `--headless --script tests/run_tests.gd` from the project root (the
  working directory matters for `res://` resolution).

## License

MIT — see [LICENSE](LICENSE).
