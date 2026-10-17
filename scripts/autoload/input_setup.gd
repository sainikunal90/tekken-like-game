extends Node
## Creates the input actions for both players at startup, so all controls
## live in one readable place instead of a long block in project.godot.
## Registered as the "InputSetup" autoload.
##
## Actions are named "p1_left", "p2_punch", etc. The on-screen touch buttons
## fire these same actions, so the fighters don't care where input comes from.

const KEYBOARD := {
	"p1_left": [KEY_A],
	"p1_right": [KEY_D],
	"p1_jump": [KEY_W, KEY_SPACE],
	"p1_punch": [KEY_F],
	"p1_kick": [KEY_G],
	"p1_block": [KEY_H, KEY_S],
	"p2_left": [KEY_LEFT],
	"p2_right": [KEY_RIGHT],
	"p2_jump": [KEY_UP],
	"p2_punch": [KEY_KP_1, KEY_COMMA],
	"p2_kick": [KEY_KP_2, KEY_PERIOD],
	"p2_block": [KEY_KP_3, KEY_SLASH, KEY_DOWN],
}

## Gamepad 0 drives player 1, gamepad 1 drives player 2.
const GAMEPAD_BUTTONS := {
	"left": JOY_BUTTON_DPAD_LEFT,
	"right": JOY_BUTTON_DPAD_RIGHT,
	"jump": JOY_BUTTON_A,
	"punch": JOY_BUTTON_X,
	"kick": JOY_BUTTON_Y,
	"block": JOY_BUTTON_RIGHT_SHOULDER,
}


func _ready() -> void:
	for action: String in KEYBOARD:
		_ensure_action(action)
		for keycode: Key in KEYBOARD[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			InputMap.action_add_event(action, ev)

	for player in [1, 2]:
		var device: int = player - 1
		for name: String in GAMEPAD_BUTTONS:
			var action := "p%d_%s" % [player, name]
			_ensure_action(action)
			var button := InputEventJoypadButton.new()
			button.device = device
			button.button_index = GAMEPAD_BUTTONS[name]
			InputMap.action_add_event(action, button)
		for dir in [-1.0, 1.0]:
			var stick := InputEventJoypadMotion.new()
			stick.device = device
			stick.axis = JOY_AXIS_LEFT_X
			stick.axis_value = dir
			InputMap.action_add_event("p%d_%s" % [player, "left" if dir < 0.0 else "right"], stick)


func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.3)
