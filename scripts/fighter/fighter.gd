class_name Fighter
extends Node2D
## One fighter: movement, attacks, blocking, taking hits and drawing.
##
## - What the fighter *wants* to do comes from a FighterController
##   (HumanController or AIController).
## - Stats, colors and moves come from a CharacterData resource.
## - The node's position is the point between the fighter's feet.
##
## The fighter is drawn with simple shapes for now. Swapping in real sprites
## or a 3D model later only means replacing _draw(); the game logic stays.

signal health_changed(current: int, maximum: int)
signal knocked_out(fighter: Fighter)
signal hit_landed(attacker: Fighter, defender: Fighter, blocked: bool, at: Vector2, heavy: bool)

enum State { IDLE, WALK, AIR, ATTACK, BLOCK, HITSTUN, BLOCKSTUN, KO }

const BODY_HALF_WIDTH := 30.0
const BODY_HEIGHT := 175.0
const INPUT_BUFFER_FRAMES := 8
const HITSTOP_FRAMES := 5
const GROUND_FRICTION := 2200.0

var data: CharacterData
var controller: FighterController
var opponent: Fighter
var use_alt_colors := false

var floor_y := 620.0
var arena_left := 0.0
var arena_right := 1280.0

var health := 100
var velocity := Vector2.ZERO
var facing := 1
var state: State = State.IDLE
var state_frames := 0
var stun_frames := 0
var current_move: MoveData
var move_has_hit := false
## While frozen the fighter ignores input (round intro / round over).
var frozen := true
## Short freeze when a hit connects, which makes hits feel heavy.
var hitstop := 0
var hit_flash := 0
## How many hits in a row this fighter has taken in the current combo.
var combo_taken := 0

var _air_attack := false
var _buffered_move: MoveData
var _buffer_left := 0
var _walk_cycle := 0.0
var _idle_time := 0.0


func setup(p_data: CharacterData, p_controller: FighterController, p_opponent: Fighter) -> void:
	data = p_data
	controller = p_controller
	controller.fighter = self
	opponent = p_opponent
	health = data.max_health


func reset_for_round(x: float) -> void:
	position = Vector2(x, floor_y)
	velocity = Vector2.ZERO
	health = data.max_health
	current_move = null
	combo_taken = 0
	hitstop = 0
	hit_flash = 0
	_buffered_move = null
	_buffer_left = 0
	_set_state(State.IDLE)
	_face_opponent()
	health_changed.emit(health, data.max_health)
	queue_redraw()


func is_on_floor() -> bool:
	return position.y >= floor_y - 0.5


func is_attacking() -> bool:
	return state == State.ATTACK and current_move != null


func is_knocked_out() -> bool:
	return state == State.KO


func get_hurtbox_rect() -> Rect2:
	return Rect2(position.x - BODY_HALF_WIDTH, position.y - BODY_HEIGHT, BODY_HALF_WIDTH * 2.0, BODY_HEIGHT)


func get_hitbox_rect() -> Rect2:
	var m := current_move
	var near := position.x + facing * BODY_HALF_WIDTH * 0.5
	var far := position.x + facing * m.reach
	var center_y := position.y + m.hitbox_y
	return Rect2(minf(near, far), center_y - m.hitbox_height * 0.5, absf(far - near), m.hitbox_height)


# --------------------------------------------------------------------------
# Frame update
# --------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if data == null:
		return
	if hit_flash > 0:
		hit_flash -= 1
	if hitstop > 0:
		hitstop -= 1
		queue_redraw()
		return

	state_frames += 1
	var allow_input := not frozen and state != State.KO
	if allow_input:
		controller.update()
		_read_buffer()
	_update_state(allow_input)
	_apply_physics(delta)
	_push_apart()
	if state in [State.IDLE, State.WALK, State.BLOCK]:
		_face_opponent()

	_idle_time += delta
	if state == State.WALK:
		_walk_cycle += delta * 11.0
	queue_redraw()


func _update_state(allow_input: bool) -> void:
	var axis := controller.get_move_axis() if allow_input else 0.0
	match state:
		State.IDLE, State.WALK:
			if allow_input and _buffered_move:
				_start_attack(_consume_buffer())
			elif allow_input and controller.wants_block():
				velocity.x = 0.0
				_set_state(State.BLOCK)
			elif allow_input and controller.wants_jump():
				velocity = Vector2(axis * data.walk_speed, -data.jump_velocity)
				_set_state(State.AIR)
			else:
				var speed := data.walk_speed
				if axis * facing < 0.0:
					speed *= data.back_walk_multiplier
				velocity.x = axis * speed
				var next: State = State.WALK if absf(axis) > 0.1 else State.IDLE
				if next != state:
					_set_state(next)
		State.AIR:
			if allow_input and _buffered_move:
				_start_attack(_consume_buffer())
		State.BLOCK:
			velocity.x = 0.0
			if not allow_input or not controller.wants_block():
				_set_state(State.IDLE)
		State.ATTACK:
			_update_attack(allow_input)
		State.HITSTUN, State.BLOCKSTUN:
			if state_frames >= stun_frames:
				combo_taken = 0
				_set_state(State.IDLE if is_on_floor() else State.AIR)
		State.KO:
			pass


func _update_attack(allow_input: bool) -> void:
	var m := current_move
	var f := state_frames
	var active_end := m.startup_frames + m.active_frames

	if not _air_attack:
		velocity.x = facing * m.forward_speed if f <= active_end else 0.0

	if allow_input and not move_has_hit and f > m.startup_frames and f <= active_end:
		_try_hit()

	# Combo: after a hit connects, the recovery can be cancelled into the
	# next attack. Pressing buttons in rhythm chains punches and kicks.
	if allow_input and move_has_hit and f > active_end and _buffered_move:
		_start_attack(_consume_buffer())
		return

	if f >= m.total_frames():
		current_move = null
		_set_state(State.IDLE if is_on_floor() else State.AIR)


func _try_hit() -> void:
	if opponent == null or opponent.is_knocked_out():
		return
	var hitbox := get_hitbox_rect()
	var hurtbox := opponent.get_hurtbox_rect()
	if hitbox.intersects(hurtbox):
		move_has_hit = true
		hitstop = HITSTOP_FRAMES
		opponent.receive_hit(current_move, self, hitbox.intersection(hurtbox).get_center())


func receive_hit(move: MoveData, attacker: Fighter, at: Vector2) -> void:
	if state == State.KO:
		return
	var toward_attacker := signf(attacker.position.x - position.x)
	var blocked := state in [State.BLOCK, State.BLOCKSTUN] and is_on_floor() \
			and toward_attacker == float(facing)
	hitstop = HITSTOP_FRAMES
	current_move = null

	if blocked:
		# Chip damage can't finish a round.
		health = maxi(health - move.chip_damage, mini(health, 1))
		stun_frames = move.blockstun_frames
		velocity.x = -toward_attacker * move.knockback * 0.6
		_set_state(State.BLOCKSTUN)
	else:
		combo_taken += 1
		health = maxi(health - _scaled_damage(move.damage), 0)
		stun_frames = move.hitstun_frames
		velocity.x = -toward_attacker * move.knockback
		if not is_on_floor():
			velocity.y = -380.0
		hit_flash = 6
		_set_state(State.HITSTUN)

	health_changed.emit(health, data.max_health)
	hit_landed.emit(attacker, self, blocked, at, move.damage >= 9)

	if health <= 0:
		velocity = Vector2(-toward_attacker * 420.0, -560.0)
		_set_state(State.KO)
		knocked_out.emit(self)


## Each extra hit in a combo does a bit less damage, so combos can't be
## infinite damage machines.
func _scaled_damage(base: int) -> int:
	var factor := maxf(0.5, 1.0 - 0.1 * (combo_taken - 1))
	return maxi(1, roundi(base * factor))


func _start_attack(move: MoveData) -> void:
	if move == null:
		return
	current_move = move
	move_has_hit = false
	_air_attack = not is_on_floor()
	if not _air_attack:
		velocity.x = 0.0
	_set_state(State.ATTACK)


func _read_buffer() -> void:
	if controller.wants_punch():
		_buffered_move = data.punch
		_buffer_left = INPUT_BUFFER_FRAMES
	elif controller.wants_kick():
		_buffered_move = data.kick
		_buffer_left = INPUT_BUFFER_FRAMES
	elif _buffer_left > 0:
		_buffer_left -= 1
		if _buffer_left == 0:
			_buffered_move = null


func _consume_buffer() -> MoveData:
	var m := _buffered_move
	_buffered_move = null
	_buffer_left = 0
	return m


func _set_state(new_state: State) -> void:
	state = new_state
	state_frames = 0


func _apply_physics(delta: float) -> void:
	var was_airborne := not is_on_floor()
	if was_airborne or velocity.y < 0.0:
		velocity.y += data.gravity * delta
	position += velocity * delta

	if position.y >= floor_y:
		position.y = floor_y
		if velocity.y > 0.0:
			velocity.y = 0.0
		if was_airborne:
			_on_landed()

	if is_on_floor() and state in [State.HITSTUN, State.BLOCKSTUN, State.KO]:
		velocity.x = move_toward(velocity.x, 0.0, GROUND_FRICTION * delta)

	position.x = clampf(position.x, arena_left + BODY_HALF_WIDTH, arena_right - BODY_HALF_WIDTH)


func _on_landed() -> void:
	if state == State.AIR or (state == State.ATTACK and _air_attack):
		current_move = null
		velocity.x = 0.0
		_set_state(State.IDLE)


## Fighters can't stand inside each other (unless one jumps over the other).
func _push_apart() -> void:
	if opponent == null:
		return
	if absf(position.y - opponent.position.y) > BODY_HEIGHT * 0.6:
		return
	var dx := position.x - opponent.position.x
	var min_dist := BODY_HALF_WIDTH * 2.0
	if absf(dx) < min_dist:
		var dir := signf(dx) if dx != 0.0 else float(-facing)
		position.x += dir * (min_dist - absf(dx)) * 0.5
		position.x = clampf(position.x, arena_left + BODY_HALF_WIDTH, arena_right - BODY_HALF_WIDTH)


func _face_opponent() -> void:
	if opponent == null:
		return
	var d := opponent.position.x - position.x
	if absf(d) > 4.0:
		facing = 1 if d > 0.0 else -1


# --------------------------------------------------------------------------
# Drawing (placeholder art made from simple shapes)
# --------------------------------------------------------------------------

func _draw() -> void:
	if data == null:
		return
	var outfit := data.alt_outfit_color if use_alt_colors else data.outfit_color
	var skin := data.skin_color
	var accent := data.accent_color
	var hair := data.hair_color
	if hit_flash > 0:
		outfit = outfit.lerp(Color.WHITE, 0.75)
		skin = skin.lerp(Color.WHITE, 0.75)
		accent = accent.lerp(Color.WHITE, 0.75)
	var outfit_back := outfit.darkened(0.3)
	var skin_back := skin.darkened(0.25)

	# Shadow on the floor, shrinking as the fighter goes higher.
	var height := floor_y - position.y
	var shadow_size := clampf(1.0 - height / 500.0, 0.35, 1.0)
	draw_set_transform(Vector2(0.0, height), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, 46.0 * shadow_size, Color(0, 0, 0, 0.35))

	var lean := 0.0
	match state:
		State.HITSTUN:
			lean = -0.18
		State.KO:
			lean = -PI * 0.5 * clampf(state_frames / 18.0, 0.0, 1.0)
	draw_set_transform(Vector2.ZERO, lean * facing, Vector2(facing, 1.0))

	var p := _pose()
	var hip: Vector2 = p.hip
	var shoulder: Vector2 = p.shoulder

	# Back limbs first (darker), then body, then front limbs.
	_limb(hip, p.back_knee, p.back_foot, 16.0, outfit_back, outfit_back.darkened(0.3))
	_limb(shoulder + Vector2(-6, 2), p.back_elbow, p.back_hand, 11.0, skin_back, accent.darkened(0.25))

	var torso := PackedVector2Array([
		shoulder + Vector2(-24, -6), shoulder + Vector2(24, -6),
		hip + Vector2(17, 4), hip + Vector2(-17, 4),
	])
	draw_colored_polygon(torso, outfit)
	draw_rect(Rect2(hip + Vector2(-18, -6), Vector2(36, 10)), accent)

	_limb(hip, p.front_knee, p.front_foot, 16.0, outfit, outfit.darkened(0.35))

	var head: Vector2 = p.head
	draw_line(shoulder, head + Vector2(0, 12), skin, 12.0)
	draw_circle(head, 19.0, skin)
	draw_circle(head + Vector2(-4, -8), 17.0, hair)
	draw_line(head + Vector2(-19, -4), head + Vector2(17, -6), accent, 5.0)
	var eye := Color(0.1, 0.1, 0.1) if state != State.KO else Color(0.4, 0.1, 0.1)
	draw_circle(head + Vector2(10, 0), 2.6, eye)

	_limb(shoulder + Vector2(6, 2), p.front_elbow, p.front_hand, 12.0, skin, accent)


func _limb(from: Vector2, joint: Vector2, to: Vector2, width: float, color: Color, end_color: Color) -> void:
	draw_line(from, joint, color, width)
	draw_line(joint, to, color, width * 0.9)
	draw_circle(from, width * 0.5, color)
	draw_circle(joint, width * 0.48, color)
	draw_circle(to, width * 0.62, end_color)


## Returns key body points for the current state, in local coordinates where
## the fighter faces right and (0, 0) is between the feet.
func _pose() -> Dictionary:
	var breathe := sin(_idle_time * 3.0) * 2.0
	var stride := sin(_walk_cycle) * 16.0 if state == State.WALK else 0.0
	var p := {
		"hip": Vector2(0, -82 + breathe * 0.3),
		"shoulder": Vector2(4, -142 + breathe),
		"head": Vector2(8, -168 + breathe),
		"back_knee": Vector2(-14 - stride * 0.5, -42),
		"back_foot": Vector2(-22 - stride, 0),
		"front_knee": Vector2(20 + stride * 0.5, -42),
		"front_foot": Vector2(24 + stride, 0),
		"back_elbow": Vector2(10, -116 + breathe),
		"back_hand": Vector2(30, -134 + breathe),
		"front_elbow": Vector2(22, -112 + breathe),
		"front_hand": Vector2(44, -140 + breathe),
	}

	match state:
		State.AIR:
			p.back_knee = Vector2(-6, -60)
			p.back_foot = Vector2(-26, -36)
			p.front_knee = Vector2(26, -62)
			p.front_foot = Vector2(14, -30)
		State.BLOCK, State.BLOCKSTUN:
			p.back_elbow = Vector2(22, -128)
			p.back_hand = Vector2(34, -160)
			p.front_elbow = Vector2(30, -120)
			p.front_hand = Vector2(40, -152)
			p.head = Vector2(4, -164)
		State.HITSTUN:
			p.front_hand = Vector2(20, -110)
			p.back_hand = Vector2(-10, -112)
		State.ATTACK:
			_attack_pose(p)
	return p


func _attack_pose(p: Dictionary) -> void:
	var m := current_move
	if m == null:
		return
	var f := float(state_frames)
	var active_end := float(m.startup_frames + m.active_frames)
	var extend := 0.0
	if f <= m.startup_frames:
		extend = 0.35 * f / maxf(1.0, m.startup_frames)
	elif f <= active_end:
		extend = 1.0
	else:
		extend = 1.0 - (f - active_end) / maxf(1.0, m.recovery_frames)
	extend = clampf(extend, 0.0, 1.0)

	var target := Vector2(m.reach, m.hitbox_y)
	if m.limb == MoveData.Limb.ARM:
		var hand := (p.front_hand as Vector2).lerp(target, extend)
		p.front_hand = hand
		p.front_elbow = ((p.shoulder as Vector2) + hand) * 0.5 + Vector2(0, 6 * (1.0 - extend))
		p.shoulder = (p.shoulder as Vector2) + Vector2(8 * extend, 0)
		p.head = (p.head as Vector2) + Vector2(6 * extend, 2 * extend)
	else:
		var foot := (p.front_foot as Vector2).lerp(target, extend)
		p.front_foot = foot
		p.front_knee = ((p.hip as Vector2) + foot) * 0.5 + Vector2(-8, -14) * extend
		p.shoulder = (p.shoulder as Vector2) + Vector2(-14 * extend, 6 * extend)
		p.head = (p.head as Vector2) + Vector2(-18 * extend, 8 * extend)
		p.back_hand = Vector2(-20, -120)
