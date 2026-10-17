class_name FighterController
extends RefCounted
## Base class for "who is driving this fighter". The Fighter only ever asks
## these questions, so humans (keyboard, gamepad, touch) and the computer
## are interchangeable. Online play or replays could plug in here later.

var fighter: Fighter


## Called once per physics frame before the fighter reads its input.
func update() -> void:
	pass


## -1.0 = left, 1.0 = right, 0.0 = no movement.
func get_move_axis() -> float:
	return 0.0


func wants_jump() -> bool:
	return false


## True only on the frame the button was pressed.
func wants_punch() -> bool:
	return false


## True only on the frame the button was pressed.
func wants_kick() -> bool:
	return false


## True while the block button is held.
func wants_block() -> bool:
	return false
