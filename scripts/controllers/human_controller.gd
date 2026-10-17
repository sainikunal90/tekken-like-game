class_name HumanController
extends FighterController
## Reads keyboard / gamepad / touch input for one player through the
## "p1_*" or "p2_*" input actions (see scripts/autoload/input_setup.gd).

var prefix: String


func _init(player_number: int) -> void:
	prefix = "p%d_" % player_number


func get_move_axis() -> float:
	return Input.get_axis(prefix + "left", prefix + "right")


func wants_jump() -> bool:
	return Input.is_action_just_pressed(prefix + "jump")


func wants_punch() -> bool:
	return Input.is_action_just_pressed(prefix + "punch")


func wants_kick() -> bool:
	return Input.is_action_just_pressed(prefix + "kick")


func wants_block() -> bool:
	return Input.is_action_pressed(prefix + "block")
