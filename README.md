# Tekken Like Game

A 2-player fighting game for Android, made with [Godot 4](https://godotengine.org/) (free and open source).

**Status:** playable prototype. Two fighters, punches, kicks, blocking, jumping, combos, best-of-3 rounds, a computer opponent and touch controls. The fighters are drawn with simple shapes for now so we can get the gameplay right before adding real art.

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
data/characters/      One .tres file per character (stats, colors, moves)
scenes/               main_menu.tscn and fight.tscn
scripts/
  autoload/           GameState (mode, picked characters) and InputSetup (all controls)
  controllers/        Who drives a fighter: HumanController, AIController
  data/               CharacterData and MoveData resource definitions
  fight/              fight.gd (rounds, timer, KO), arena.gd (stage), hit_spark.gd
  fighter/            fighter.gd - movement, attacks, hits, blocking, drawing
  ui/                 main_menu.gd, hud.gd, touch_controls.gd
tests/smoke_test.gd   Plays a full CPU vs CPU match headlessly to catch errors
```

### How it fits together

- A **Fighter** never reads the keyboard directly. It asks its **FighterController** "do you want to move / punch / block?". That means humans, the CPU, and later online players or replays are interchangeable.
- A fighter's stats and moves live in a **CharacterData** resource with **MoveData** for each attack (damage, startup / active / recovery frames, reach, hitstun, knockback). Balance changes are just number edits in the Godot inspector.
- **fight.gd** owns the match: spawns fighters, runs the round timer, decides round winners, and shows the HUD.

## Adding a new character

1. In Godot's FileSystem panel, duplicate `data/characters/arjun.tres` → e.g. `kabir.tres`.
2. Select it and edit its name, colors, stats and moves in the Inspector. (Right-click the `punch` / `kick` sub-resources → **Make Unique** so you don't change Arjun's moves too.)
3. Add the path to `CHARACTERS` in `scripts/autoload/game_state.gd`.

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

- [ ] Real character art (sprite sheets or 3D models) and animations
- [ ] Sound effects and music
- [ ] More moves per character: low attacks, crouch, throws, specials (e.g. ↓→ + Punch)
- [ ] Character select screen with portraits
- [ ] More stages
- [ ] Smarter CPU (combos, reading the player's habits)
- [ ] Training mode with hitbox display
- [ ] Online / Bluetooth versus
