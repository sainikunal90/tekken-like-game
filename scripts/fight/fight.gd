extends Node2D
## Runs a match: builds the stage, spawns both fighters with the right
## controllers, and handles rounds, the timer, K.O.s and the end screen.

const FIGHTER_SCRIPT := preload("res://scripts/fighter/fighter.gd")

var fighters: Array[Fighter] = []
var round_wins: Array[int] = [0, 0]
var round_number := 0
var time_left := 0.0
var round_active := false

var _screen := Vector2(1280, 720)
var _floor_y := 620.0
var _hud: Hud
var _camera: Camera2D
var _effects: Node2D
var _shake := 0.0


func _ready() -> void:
	_screen = get_viewport_rect().size
	_floor_y = _screen.y - 100.0

	var arena := Arena.new()
	arena.size = _screen
	arena.floor_y = _floor_y
	add_child(arena)

	_camera = Camera2D.new()
	_camera.position = _screen * 0.5
	add_child(_camera)

	_spawn_fighters()

	_effects = Node2D.new()
	add_child(_effects)

	_hud = Hud.new()
	add_child(_hud)
	_hud.build(
		[fighters[0].data.display_name, fighters[1].data.display_name] as Array[String],
		[_outfit(fighters[0]), _outfit(fighters[1])] as Array[Color])
	_hud.rematch_pressed.connect(_on_rematch)
	_hud.menu_pressed.connect(_go_to_menu)

	if GameState.wants_touch_controls() and GameState.mode != GameState.Mode.CPU_VS_CPU:
		var touch := TouchControls.new()
		add_child(touch)
		touch.build(GameState.mode == GameState.Mode.VERSUS)

	_start_round()


func _spawn_fighters() -> void:
	var p1_data := GameState.get_character(GameState.p1_character_index)
	var p2_data := GameState.get_character(GameState.p2_character_index)

	var controllers: Array[FighterController] = []
	match GameState.mode:
		GameState.Mode.VERSUS:
			controllers = [HumanController.new(1), HumanController.new(2)]
		GameState.Mode.VS_CPU:
			controllers = [HumanController.new(1), AIController.new(GameState.cpu_difficulty)]
		GameState.Mode.CPU_VS_CPU:
			controllers = [AIController.new(GameState.cpu_difficulty), AIController.new(GameState.cpu_difficulty)]

	for i in 2:
		var f: Fighter = FIGHTER_SCRIPT.new()
		f.name = "Player%d" % (i + 1)
		f.floor_y = _floor_y
		f.arena_left = 20.0
		f.arena_right = _screen.x - 20.0
		add_child(f)
		fighters.append(f)

	fighters[0].setup(p1_data, controllers[0], fighters[1])
	fighters[1].setup(p2_data, controllers[1], fighters[0])
	fighters[1].use_alt_colors = p1_data == p2_data

	for i in 2:
		var f := fighters[i]
		f.health_changed.connect(_on_health_changed.bind(i))
		f.knocked_out.connect(_on_knocked_out)
		f.hit_landed.connect(_on_hit_landed)


func _process(delta: float) -> void:
	if round_active:
		time_left -= delta
		_hud.set_timer(ceili(time_left))
		if time_left <= 0.0:
			_end_round(true)

	if _shake > 0.0:
		_shake = maxf(_shake - delta * 40.0, 0.0)
		_camera.offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	else:
		_camera.offset = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_to_menu()


func _notification(what: int) -> void:
	# Android back button
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_to_menu()


func _start_round() -> void:
	round_number += 1
	var center := _screen.x * 0.5
	fighters[0].reset_for_round(center - 220.0)
	fighters[1].reset_for_round(center + 220.0)
	_set_frozen(true)
	time_left = GameState.ROUND_TIME
	_hud.set_timer(ceili(time_left))
	_hud.set_round_wins(round_wins)

	var final_round := round_wins[0] == GameState.ROUNDS_TO_WIN - 1 and round_wins[1] == GameState.ROUNDS_TO_WIN - 1
	_hud.show_message("FINAL ROUND" if final_round else "ROUND %d" % round_number)
	await get_tree().create_timer(1.2).timeout
	_hud.show_message("FIGHT!")
	_set_frozen(false)
	round_active = true
	await get_tree().create_timer(0.7).timeout
	if round_active:
		_hud.hide_message()


func _end_round(timed_out: bool) -> void:
	if not round_active:
		return
	round_active = false
	_set_frozen(true)

	var ratio0 := float(fighters[0].health) / fighters[0].data.max_health
	var ratio1 := float(fighters[1].health) / fighters[1].data.max_health
	var winner := -1
	if fighters[0].is_knocked_out() and not fighters[1].is_knocked_out():
		winner = 1
	elif fighters[1].is_knocked_out() and not fighters[0].is_knocked_out():
		winner = 0
	elif not is_equal_approx(ratio0, ratio1):
		winner = 0 if ratio0 > ratio1 else 1

	if winner == -1:
		round_wins[0] += 1
		round_wins[1] += 1
	else:
		round_wins[winner] += 1

	print("Round %d: %s, health P1 %d / P2 %d" % [round_number, "time" if timed_out else "K.O.", fighters[0].health, fighters[1].health])
	_hud.show_message("TIME" if timed_out else "K.O.")
	await get_tree().create_timer(1.4).timeout
	if winner == -1:
		_hud.show_message("DRAW")
	else:
		_hud.show_message("%s WINS" % fighters[winner].data.display_name.to_upper())
	_hud.set_round_wins(round_wins)
	await get_tree().create_timer(1.6).timeout

	var p1_done := round_wins[0] >= GameState.ROUNDS_TO_WIN
	var p2_done := round_wins[1] >= GameState.ROUNDS_TO_WIN
	if p1_done or p2_done:
		_end_match(p1_done, p2_done)
	else:
		_start_round()


func _end_match(p1_done: bool, p2_done: bool) -> void:
	if p1_done and p2_done:
		_hud.show_message("DRAW GAME")
	else:
		var winner := 0 if p1_done else 1
		var label := "PLAYER %d" % (winner + 1)
		if GameState.mode == GameState.Mode.VS_CPU:
			label = "YOU WIN!" if winner == 0 else "CPU WINS"
			_hud.show_message(label, fighters[winner].data.display_name)
		else:
			_hud.show_message("%s WINS!" % label, fighters[winner].data.display_name)
	print("Match over. Rounds: P1 %d - P2 %d" % [round_wins[0], round_wins[1]])
	_hud.show_end_buttons()


func _set_frozen(value: bool) -> void:
	for f in fighters:
		f.frozen = value


func _on_health_changed(current: int, maximum: int, player: int) -> void:
	_hud.set_health(player, current, maximum)


func _on_knocked_out(_fighter: Fighter) -> void:
	_shake = 14.0
	_end_round(false)


func _on_hit_landed(attacker: Fighter, defender: Fighter, blocked: bool, at: Vector2, heavy: bool) -> void:
	var spark := HitSpark.new()
	spark.position = at
	spark.blocked = blocked
	spark.heavy = heavy
	_effects.add_child(spark)
	if not blocked:
		_shake = maxf(_shake, 8.0 if heavy else 4.0)
		if defender.combo_taken >= 2:
			_hud.show_combo(fighters.find(attacker), defender.combo_taken)


func _outfit(f: Fighter) -> Color:
	return f.data.alt_outfit_color if f.use_alt_colors else f.data.outfit_color


func _on_rematch() -> void:
	get_tree().reload_current_scene()


func _go_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
