class_name MoveData
extends Resource
## One attack (punch, kick, ...). Tweak these numbers in the Godot inspector
## to balance a character without touching code. Timings are in frames at
## 60 frames per second.

enum Limb { ARM, LEG }

@export var move_name := "Punch"
@export var limb: Limb = Limb.ARM

@export_group("Animation")
## Animation played by the 3D model (name inside the character's .glb).
@export var animation := "Unarmed_Melee_Attack_Punch_A"
## Second (in the animation) where the fist/foot is fully extended. The
## animation is sped up or slowed down so this moment lines up with the
## move's active frames.
@export var impact_time := 0.5
## How much of the animation after impact_time is shown during recovery.
@export var recovery_time := 0.5

@export_group("Damage")
@export var damage := 6
## Damage dealt even when the opponent blocks.
@export var chip_damage := 1
## Frames the opponent is stunned when hit (higher = easier to combo).
@export var hitstun_frames := 16
## Frames the opponent is stunned when they block it.
@export var blockstun_frames := 9
## Push-back speed applied to the opponent on hit.
@export var knockback := 240.0

@export_group("Timing")
## Wind-up frames before the attack can hit.
@export var startup_frames := 4
## Frames during which the attack can hit.
@export var active_frames := 3
## Frames after the hit window before the fighter can act again.
@export var recovery_frames := 9

@export_group("Hitbox")
## How far in front of the fighter's center the attack reaches (pixels).
@export var reach := 95.0
## Height of the hitbox center, measured up from the feet (negative = up).
@export var hitbox_y := -138.0
@export var hitbox_height := 34.0
## Forward slide speed while performing the move on the ground.
@export var forward_speed := 0.0


func total_frames() -> int:
	return startup_frames + active_frames + recovery_frames
