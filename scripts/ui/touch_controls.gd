class_name TouchControls
extends CanvasLayer
## On-screen buttons for phones and tablets. Each button triggers the same
## input action as the keyboard ("p1_punch", ...), so fighters work the same
## with touch, keyboard or gamepad. Multi-touch works, so two players can
## share one device: player 1 uses the left side, player 2 the right side.

const BUTTON_ALPHA := 0.45

var _texture_cache := {}


## two_players: show a control set for each player on either side.
func build(two_players: bool) -> void:
	var screen := get_viewport().get_visible_rect().size
	if two_players:
		_add_player_set(1, screen, false, 42.0, true)
		_add_player_set(2, screen, true, 42.0, true)
	else:
		_add_player_set(1, screen, false, 64.0, false)


func _add_player_set(player: int, screen: Vector2, mirrored: bool, r: float, compact: bool) -> void:
	var p := "p%d_" % player
	var h := screen.y
	var move_color := Color(0.85, 0.85, 0.95)
	var attack_colors := [Color(1.0, 0.55, 0.3), Color(0.35, 0.75, 1.0), Color(0.5, 0.9, 0.5)]

	# Movement cluster (bottom corner)
	var positions := {
		"left": Vector2(r * 1.5, h - r * 1.6),
		"right": Vector2(r * 4.0, h - r * 1.6),
		"jump": Vector2(r * 2.75, h - r * 3.9),
	}
	# Attack cluster: next to the movement buttons in 2-player mode,
	# otherwise in the opposite corner.
	if compact:
		var base_x := r * 6.4
		positions["punch"] = Vector2(base_x, h - r * 1.5)
		positions["kick"] = Vector2(base_x + r * 2.4, h - r * 1.5)
		positions["block"] = Vector2(base_x + r * 1.2, h - r * 3.7)
	else:
		positions["punch"] = Vector2(screen.x - r * 4.2, h - r * 1.6)
		positions["kick"] = Vector2(screen.x - r * 1.6, h - r * 1.6)
		positions["block"] = Vector2(screen.x - r * 2.9, h - r * 4.0)

	var labels := {"left": "<", "right": ">", "jump": "^", "punch": "P", "kick": "K", "block": "B"}
	for action: String in positions:
		var pos: Vector2 = positions[action]
		if mirrored:
			pos.x = screen.x - pos.x
			if action == "left":
				pos.x = screen.x - positions["right"].x
			elif action == "right":
				pos.x = screen.x - positions["left"].x
		var color := move_color
		match action:
			"punch": color = attack_colors[0]
			"kick": color = attack_colors[1]
			"block": color = attack_colors[2]
		_add_button(p + action, labels[action], pos, r, color)


func _add_button(action: String, text: String, center: Vector2, radius: float, color: Color) -> void:
	var b := TouchScreenButton.new()
	b.texture_normal = _circle_texture(radius, Color(color, BUTTON_ALPHA))
	b.texture_pressed = _circle_texture(radius, Color(color.lightened(0.3), 0.8))
	var shape := CircleShape2D.new()
	shape.radius = radius * 1.1
	b.shape = shape
	b.shape_centered = true
	b.action = action
	b.passby_press = true
	b.position = center - Vector2(radius, radius)
	add_child(b)

	var label := Label.new()
	label.text = text
	label.size = Vector2(radius * 2.0, radius * 2.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", int(radius * 0.7))
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(label)


func _circle_texture(radius: float, color: Color) -> Texture2D:
	var key := "%d_%s" % [int(radius), color.to_html()]
	if _texture_cache.has(key):
		return _texture_cache[key]
	var size := int(radius * 2.0)
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(radius, radius)
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d <= radius:
				var edge := clampf(radius - d, 0.0, 1.0)
				var ring := 1.0 if d > radius - 4.0 else 0.75
				img.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * edge * ring))
	var tex := ImageTexture.create_from_image(img)
	_texture_cache[key] = tex
	return tex
