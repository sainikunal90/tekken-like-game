class_name CharacterData
extends Resource
## Everything that makes one character different from another: stats, colors
## and moves. Characters are .tres files in data/characters/. To make a new
## character, duplicate an existing .tres, change the values and add it to
## GameState.CHARACTERS.

@export var display_name := "Fighter"

@export_group("Look")
@export var outfit_color := Color(0.85, 0.35, 0.15)
## Used instead of outfit_color when both players pick this character.
@export var alt_outfit_color := Color(0.25, 0.4, 0.85)
@export var skin_color := Color(0.85, 0.65, 0.5)
@export var accent_color := Color(0.95, 0.85, 0.3)
@export var hair_color := Color(0.1, 0.08, 0.08)

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
