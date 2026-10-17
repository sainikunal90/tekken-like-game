class_name Hud
extends CanvasLayer
## Health bars, names, round timer, round-win markers, big center messages
## ("ROUND 1", "FIGHT!", "K.O.") and the end-of-match buttons.

signal rematch_pressed
signal menu_pressed

var _bars: Array[ProgressBar] = []
var _combo_labels: Array[Label] = []
var _win_markers: Array = [[], []]
var _timer_label: Label
var _message: Label
var _sub_message: Label
var _end_buttons: VBoxContainer
var _combo_timers := [0.0, 0.0]


func build(names: Array[String], colors: Array[Color]) -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var screen := root.get_viewport_rect().size
	var bar_width := screen.x * 0.36
	var margin := 28.0

	for i in 2:
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.size = Vector2(bar_width, 30)
		bar.position = Vector2(margin if i == 0 else screen.x - margin - bar_width, 24)
		bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN if i == 0 else ProgressBar.FILL_BEGIN_TO_END
		bar.add_theme_stylebox_override("background", _box(Color(0.15, 0.05, 0.08, 0.85), Color(1, 1, 1, 0.9)))
		bar.add_theme_stylebox_override("fill", _box(Color(1.0, 0.8, 0.2), Color(0, 0, 0, 0)))
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(bar)
		_bars.append(bar)

		var name_label := _label(names[i], 26)
		name_label.add_theme_color_override("font_color", colors[i].lightened(0.35))
		name_label.position = Vector2(bar.position.x, 58)
		name_label.size = Vector2(bar_width, 36)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		root.add_child(name_label)

		for w in GameState.ROUNDS_TO_WIN:
			var marker := Panel.new()
			marker.size = Vector2(18, 18)
			var x := bar.position.x + bar_width - 22 - w * 26 if i == 0 else bar.position.x + 4 + w * 26
			marker.position = Vector2(x, 64)
			marker.add_theme_stylebox_override("panel", _box(Color(0.2, 0.2, 0.2, 0.8), Color.WHITE, 9))
			marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
			root.add_child(marker)
			_win_markers[i].append(marker)

		var combo := _label("", 34)
		combo.position = Vector2(margin if i == 0 else screen.x - margin - 260, 150)
		combo.size = Vector2(260, 50)
		combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		combo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		root.add_child(combo)
		_combo_labels.append(combo)

	_timer_label = _label("60", 44)
	_timer_label.position = Vector2(screen.x * 0.5 - 60, 12)
	_timer_label.size = Vector2(120, 56)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_timer_label)

	_message = _label("", 96)
	_message.position = Vector2(0, screen.y * 0.28)
	_message.size = Vector2(screen.x, 120)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_message)

	_sub_message = _label("", 36)
	_sub_message.position = Vector2(0, screen.y * 0.28 + 120)
	_sub_message.size = Vector2(screen.x, 50)
	_sub_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_sub_message)

	_end_buttons = VBoxContainer.new()
	_end_buttons.add_theme_constant_override("separation", 16)
	_end_buttons.size = Vector2(320, 150)
	_end_buttons.position = Vector2(screen.x * 0.5 - 160, screen.y * 0.28 + 190)
	_end_buttons.visible = false
	root.add_child(_end_buttons)
	_end_buttons.add_child(_button("Rematch", rematch_pressed.emit))
	_end_buttons.add_child(_button("Main Menu", menu_pressed.emit))


func _process(delta: float) -> void:
	for i in 2:
		if _combo_timers[i] > 0.0:
			_combo_timers[i] -= delta
			if _combo_timers[i] <= 0.0 and i < _combo_labels.size():
				_combo_labels[i].text = ""


func set_health(player: int, current: int, maximum: int) -> void:
	_bars[player].max_value = maximum
	_bars[player].value = current
	var ratio := float(current) / float(maximum)
	var fill := Color(1.0, 0.8, 0.2) if ratio > 0.3 else Color(0.95, 0.25, 0.2)
	_bars[player].add_theme_stylebox_override("fill", _box(fill, Color(0, 0, 0, 0)))


func set_timer(seconds: int) -> void:
	_timer_label.text = str(maxi(seconds, 0))


func set_round_wins(wins: Array[int]) -> void:
	for i in 2:
		for w in _win_markers[i].size():
			var won: bool = w < wins[i]
			var color := Color(1.0, 0.8, 0.2) if won else Color(0.2, 0.2, 0.2, 0.8)
			(_win_markers[i][w] as Panel).add_theme_stylebox_override("panel", _box(color, Color.WHITE, 9))


func show_combo(player: int, hits: int) -> void:
	_combo_labels[player].text = "%d HITS!" % hits
	_combo_timers[player] = 1.2


func show_message(text: String, sub: String = "") -> void:
	_message.text = text
	_sub_message.text = sub


func hide_message() -> void:
	show_message("")


func show_end_buttons() -> void:
	_end_buttons.visible = true
	(_end_buttons.get_child(0) as Button).grab_focus()


func _label(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_constant_override("outline_size", maxi(4, font_size / 8))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 64)
	b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(on_press)
	return b


func _box(color: Color, border: Color, radius: int = 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(2 if border.a > 0.0 else 0)
	s.set_corner_radius_all(radius)
	return s
