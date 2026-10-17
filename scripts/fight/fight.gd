extends Node2D
## Runs a match: builds the 3D stage, spawns both fighters (logic + 3D
## model) with the right controllers, and handles rounds, the timer, K.O.s
## and the end screen.
##
## Gameplay happens on a flat line measured in "arena pixels"
## (100 px = 1 m). FighterModel turns that into 3D positions.

const FIGHTER_SCRIPT := preload("res://scripts/fighter/fighter.gd")
const ARENA_WIDTH := 1400.0
const FLOOR_Y := 620.0

var fighters: Array[Fighter] = []
var round_wins: Array[int] = [0, 0]
var round_number := 0
var time_left := 0.0
var round_active := false

var models: Array[FighterModel] = []
var stage: Stage3D

var _hud: Hud
var _camera: FightCamera
var _effects: Node2D


func _ready() -> void:
	stage = GameState.create_stage()
	add_child(stage)
	stage.build()

	_spawn_fighters()

	_camera = FightCamera.new()
	add_child(_camera)
	_camera.models = models

	_effects = Node2D.new()
	add_child(_effects)

	_hud = Hud.new()
	add_child(_hud)
	_hud.build(
		[fighters[0].data.display_name, fighters[1].data.display_name] as Array[String],
		[fighters[0].data.ui_color, fighters[1].data.ui_color] as Array[Color])
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
		f.floor_y = FLOOR_Y
		f.arena_left = 0.0
		f.arena_right = ARENA_WIDTH
		f.visible = false
		add_child(f)
		fighters.append(f)

	fighters[0].setup(p1_data, controllers[0], fighters[1])
	fighters[1].setup(p2_data, controllers[1], fighters[0])
	fighters[1].use_alt_colors = p1_data == p2_data

	for f in fighters:
		var model := FighterModel.new()
		model.name = f.name + "Model"
		add_child(model)
		model.setup(f, ARENA_WIDTH * 0.5)
		models.append(model)

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



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_to_menu()


func _notification(what: int) -> void:
	# Android back button
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_to_menu()


func _start_round() -> void:
	round_number += 1
	var center := ARENA_WIDTH * 0.5
	fighters[0].reset_for_round(center - 220.0)
	fighters[1].reset_for_round(center + 220.0)
	_set_frozen(true)
	_camera.snap()
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
		if not fighters[winner].is_knocked_out():
			fighters[winner].celebrating = true
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
	_camera.shake = 14.0
	_end_round(false)


func _on_hit_landed(attacker: Fighter, defender: Fighter, blocked: bool, at: Vector2, heavy: bool) -> void:
	# The hit happens in arena space; show the spark where that point
	# appears on screen in 3D.
	var world := models[0].world_position_of(at) + Vector3(0, 0, 0.3)
	if _camera.is_position_behind(world):
		return
	var spark := HitSpark.new()
	spark.position = _camera.unproject_position(world)
	spark.blocked = blocked
	spark.heavy = heavy
	_effects.add_child(spark)
	if not blocked:
		_camera.shake = maxf(_camera.shake, 8.0 if heavy else 4.0)
		if defender.combo_taken >= 2:
			_hud.show_combo(fighters.find(attacker), defender.combo_taken)


func _on_rematch() -> void:
	get_tree().reload_current_scene()


func _go_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
