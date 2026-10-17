# Tekken Like Game

A 2-player fighting game for Android, made with [Godot 4](https://godotengine.org/) (free and open source).

**Status:** playable prototype in 3D. Four animated fighters, two stages, punches, kicks, blocking, jumping, combos, best-of-3 rounds, a computer opponent and touch controls.

| Fighter | Model | Style |
|---|---|---|
| Arjun | Barbarian | Balanced, strong front kick |
| Mira | Rogue | Fast, quick jab |
| Kabir | Knight | Slow and tough, uppercut |
| Zara | Mage | Long reach, sweeping kick |

| Stage | Description |
|---|---|
| Himalayan Pass | Stone ledge with snowy peaks, pine forest, a stupa, prayer flags and snowfall |
| Monsoon Temple | Wet courtyard in front of a sandstone temple at dusk, lamp pillars, palms and rain |

## Getting started

1. Download **Godot 4.3** (or newer 4.x, standard version, not .NET) from https://godotengine.org/download.
2. Clone this repo:
   ```bash
   git clone https://github.com/sainikunal90/tekken-like-game.git
   ```
3. Open Godot → **Import** → choose `project.godot` in the cloned folder.
4. Press **F5** (or the ▶ button) to play.

## Game modes

| Mode | Description |
|---|---|
| 2 Players | Two people on one keyboard, two gamepads, or one phone/tablet (split touch controls) |
| Vs Computer | Player 1 against the CPU (Easy / Normal / Hard) |
| Watch CPU vs CPU | Demo mode, handy for testing balance changes |

## Controls

| Action | Player 1 keys | Player 2 keys | Gamepad |
|---|---|---|---|
| Move | A / D | ← / → | D-pad or left stick |
| Jump | W or Space | ↑ | A |
| Punch | F | Numpad 1 or `,` | X |
| Kick | G | Numpad 2 or `.` | Y |
| Block (hold) | H or S | Numpad 3, `/` or ↓ | Right bumper |
| Back to menu | Esc | | |

On phones and tablets, on-screen buttons appear automatically. To test them on a computer, add `--touch` under **Project → Project Settings → Run → Main Run Args** (as `-- --touch`).

**Combos:** when a hit lands, press another attack during the recovery to chain it (e.g. Punch → Punch → Kick). Each extra hit in a combo does a little less damage.

## Project layout

```
assets/characters/    3D character models (.glb) with their animations
data/characters/      One .tres file per character (model, stats, moves)
scenes/               main_menu.tscn and fight.tscn
scripts/
  autoload/           GameState (mode, characters, stages) and InputSetup (all controls)
  controllers/        Who drives a fighter: HumanController, AIController
  data/               CharacterData and MoveData resource definitions
  fight/              fight.gd (rounds, timer, KO), fight_camera.gd, hit_spark.gd
  fighter/            fighter.gd (game logic), fighter_model.gd (3D model + animations)
  stages/             stage_3d.gd (helpers) + one script per stage
  ui/                 main_menu.gd, hud.gd, touch_controls.gd
tests/smoke_test.gd   Plays a full CPU vs CPU match headlessly to catch errors
```

### How it fits together

- A **Fighter** never reads the keyboard directly. It asks its **FighterController** "do you want to move / punch / block?". That means humans, the CPU, and later online players or replays are interchangeable.
- A fighter's stats and moves live in a **CharacterData** resource with **MoveData** for each attack (damage, startup / active / recovery frames, reach, hitstun, knockback). Balance changes are just number edits in the Godot inspector.
- **Gameplay is 2D, visuals are 3D** (like Street Fighter IV). `fighter.gd` moves fighters along a line in "arena pixels" (100 px = 1 m) and handles hitboxes. `fighter_model.gd` reads that state each frame, places the 3D model and plays the right animation (idle, walk, punch, kick, block, hit, K.O., victory). Attack animations are re-timed so the punch or kick lands exactly on the move's active frames (`impact_time` in MoveData).
- **fight.gd** owns the match: builds the stage, spawns fighters and their models, runs the round timer, decides round winners, and shows the HUD. **fight_camera.gd** keeps both fighters in view.
- **Stages** are built in code from simple shapes and generated terrain (`scripts/stages/`), so they need no extra art files and are easy to tweak.

## Adding a new character

1. In Godot's FileSystem panel, duplicate `data/characters/arjun.tres` → e.g. `dev.tres`.
2. Select it and edit its name, model, stats and moves in the Inspector. (Right-click the `punch` / `kick` sub-resources → **Make Unique** so you don't change Arjun's moves too.)
3. Add the path to `CHARACTERS` in `scripts/autoload/game_state.gd`.

### Using a different 3D model

Any rigged, animated `.glb` / `.gltf` / `.fbx` works if it has these animation names (rename them in Godot's import dock if needed):
`Unarmed_Idle`, `Walking_A`, `Walking_Backwards`, `Jump_Idle`, `Blocking`, `Block_Hit`, `Hit_A`, `Death_A`, `Cheer`, plus the attack animations named in each move (`Unarmed_Melee_Attack_Punch_A`, `Unarmed_Melee_Attack_Kick`, ...).

All **KayKit** character packs (free, CC0) use exactly these names, so their characters drop straight in:
- KayKit Adventurers (used now): https://kaylousberg.itch.io/kaykit-adventurers
- KayKit Skeletons: https://kaylousberg.itch.io/kaykit-skeletons

Copy the `.glb` into `assets/characters/`, set it as `model_scene` in a character `.tres`, and adjust `model_scale` until the fighter is about 1.8 m tall. For a model from Mixamo or Blender, set the animation names in the import dock or change the names at the top of `fighter_model.gd`. Set `impact_time` on each move to the second in the animation where the fist or foot is fully extended.

## Adding a new stage

1. Copy `scripts/stages/stage_temple.gd` to e.g. `stage_beach.gd` and change `build()`. Helpers in `stage_3d.gd` make boxes, cylinders, spheres, terrain, trees (multimesh) and rain/snow.
2. Keep the floor at y = 0 and the area between x = -7 and x = 7 clear; that's where fighters move. Scenery goes at negative z (behind) and to the sides.
3. Add it to `STAGES` in `scripts/autoload/game_state.gd`.

You can also build a stage in the Godot editor: make a scene with a root script that `extends Stage3D`, and place imported models (e.g. from KayKit or Kenney packs) in it.

## Building the Android APK

One-time setup (on the computer that builds):

1. Install **Android Studio** (or just the Android SDK command-line tools) and **JDK 17**.
2. In Godot: **Editor → Editor Settings → Export → Android** and set the *Java SDK Path* and *Android SDK Path*.
3. **Editor → Manage Export Templates → Download and Install**.

Then **Project → Export → Android → Export Project**. The APK goes to `build/tekken-like-game.apk`. Copy it to a phone and install it (allow "Install unknown apps"). You can also connect a phone with USB debugging and press the Android icon at the top right of the editor to run it directly.

The debug build is signed with Godot's debug key automatically. For a Play Store release you will need your own release keystore. **Never commit keystores or passwords**; they are already ignored in `.gitignore`.

## Testing

Run a full CPU vs CPU match without opening a window:

```bash
godot --headless --fixed-fps 60 --script res://tests/smoke_test.gd
```

It should print `SMOKE TEST PASSED`.

## Working together

- `main` should always be playable.
- Make a branch for each change (`git checkout -b add-uppercut`), push it, and open a Pull Request so the other person can try it before merging.
- Pull often (`git pull`) so you're not editing the same file for days.
- Godot's `.tscn` / `.tres` files are text, so most merges work fine. Still, avoid both editing the same scene at the same time.
- The `.godot/` folder is a local cache and is ignored. Don't commit it.

## Ideas / roadmap

- [x] 3D character models and animations (KayKit Adventurers)
- [x] 3D stages: Himalayan Pass, Monsoon Temple
- [ ] More stages: beach, city rooftop
- [ ] Sound effects and music
- [ ] More moves per character: low attacks, crouch, throws, specials (e.g. ↓→ + Punch)
- [ ] Character select screen with portraits
- [ ] Smarter CPU (combos, reading the player's habits)
- [ ] Training mode with hitbox display
- [ ] Online / Bluetooth versus

## Credits

- Character models and animations: **KayKit Adventurers** by Kay Lousberg (www.kaylousberg.com), CC0 license. See `assets/characters/kaykit/LICENSE.txt`.
