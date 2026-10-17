class_name CharacterData
extends Resource
## Everything that makes one character different from another: 3D model,
## stats and moves. Characters are .tres files in data/characters/. To make a
## new character, duplicate an existing .tres, change the values and add it
## to GameState.CHARACTERS.

@export var display_name := "Fighter"

@export_group("Look")
## A rigged, animated 3D model (.glb / .gltf / .fbx). It needs the animation
## names used in FighterModel (Unarmed_Idle, Walking_A, Hit_A, ...). Models
## from the KayKit character packs work as-is.
@export var model_scene: PackedScene
@export var model_scale := 0.85
## Name color in the HUD.
@export var ui_color := Color(0.85, 0.35, 0.15)
## Tint applied to player 2's model when both players pick this character.
@export var alt_tint := Color(0.6, 0.75, 1.2)

@export_group("Stats")
@export var max_health := 100
@export var walk_speed := 260.0
## Walking backwards is slower than forwards, like most fighting games.
@export_range(0.1, 1.0) var back_walk_multiplier := 0.75
@export var jump_velocity := 900.0
@export var gravity := 2600.0

@export_group("Moves")
@export var punch: MoveData
@export var kick: MoveData
