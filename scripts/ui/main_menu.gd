extends Control
## Title screen: pick characters, CPU difficulty and the game mode.

var _p1_label: Label
var _p2_label: Label
var _stage_label: Label
var _difficulty_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.07, 0.15)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)

	var title := _label("TEKKEN LIKE GAME", 56)
	title.add_theme_color_override("font_color", Color(1.0, 0.6, 0.25))
	box.add_child(title)
	box.add_child(_label("A 2-player fighting game", 24))
	box.add_child(_spacer(4))

	_p1_label = _add_character_row(box, 1)
	_p2_label = _add_character_row(box, 2)
	_stage_label = _add_row(box, _change_stage.bind(-1), _change_stage.bind(1))
	_difficulty_button = _button("", _cycle_difficulty)
	box.add_child(_difficulty_button)
	box.add_child(_spacer(4))

	var versus := _button("2 Players", _start.bind(GameState.Mode.VERSUS))
	box.add_child(versus)
	box.add_child(_button("Vs Computer", _start.bind(GameState.Mode.VS_CPU)))
	box.add_child(_button("Watch CPU vs CPU", _start.bind(GameState.Mode.CPU_VS_CPU)))
	if not OS.has_feature("web"):
		box.add_child(_button("Quit", get_tree().quit))

	_refresh()
	versus.grab_focus()


func _add_character_row(parent: Container, player: int) -> Label:
	return _add_row(parent, _change_character.bind(player, -1), _change_character.bind(player, 1))


func _add_row(parent: Container, on_left: Callable, on_right: Callable) -> Label:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	row.add_child(_small_button("<", on_left))
	var label := _label("", 28)
	label.custom_minimum_size = Vector2(380, 0)
	row.add_child(label)
	row.add_child(_small_button(">", on_right))
	return label


func _change_stage(step: int) -> void:
	# -1 means Random, then 0..N-1 are the stages.
	var count := GameState.STAGES.size() + 1
	GameState.stage_index = wrapi(GameState.stage_index + 1 + step, 0, count) - 1
	_refresh()


func _change_character(player: int, step: int) -> void:
	var count := GameState.CHARACTERS.size()
	if player == 1:
		GameState.p1_character_index = wrapi(GameState.p1_character_index + step, 0, count)
	else:
		GameState.p2_character_index = wrapi(GameState.p2_character_index + step, 0, count)
	_refresh()


func _cycle_difficulty() -> void:
	GameState.cpu_difficulty = (GameState.cpu_difficulty + 1) % GameState.DIFFICULTY_NAMES.size()
	_refresh()


func _refresh() -> void:
	_p1_label.text = "P1: " + GameState.get_character(GameState.p1_character_index).display_name
	_p2_label.text = "P2: " + GameState.get_character(GameState.p2_character_index).display_name
	_stage_label.text = "Stage: " + GameState.get_stage_name(GameState.stage_index)
	_difficulty_button.text = "CPU Level: " + GameState.DIFFICULTY_NAMES[GameState.cpu_difficulty]


func _start(mode: GameState.Mode) -> void:
	GameState.mode = mode
	get_tree().change_scene_to_file("res://scenes/fight.tscn")


func _label(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	return l


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(380, 50)
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect(on_press)
	return b


func _small_button(text: String, on_press: Callable) -> Button:
	var b := _button(text, on_press)
	b.custom_minimum_size = Vector2(60, 44)
	return b


func _spacer(height: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c
