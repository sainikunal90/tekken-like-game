class_name AIController
extends FighterController
## A simple computer opponent. Every few frames it "thinks": walks into
## range, attacks, blocks incoming attacks and sometimes jumps. Difficulty
## changes how fast it reacts and how often it blocks.

## Frames between decisions, per difficulty (Easy, Normal, Hard).
const REACTION_FRAMES := [26, 15, 8]
const BLOCK_CHANCE := [0.15, 0.45, 0.75]
const AGGRESSION := [0.35, 0.6, 0.8]

var difficulty := 1

var _axis := 0.0
var _block := false
var _jump := false
var _punch := false
var _kick := false
var _think_timer := 0


func _init(p_difficulty: int = 1) -> void:
	difficulty = clampi(p_difficulty, 0, 2)


func update() -> void:
	# Button presses only last a single frame.
	_jump = false
	_punch = false
	_kick = false

	var me := fighter
	var foe := me.opponent if me else null
	if foe == null:
		return

	# React to an incoming attack immediately (if we're good enough to).
	if foe.is_attacking() and _distance() < 190.0 and not _block:
		if randf() < BLOCK_CHANCE[difficulty] * 0.25:
			_block = true
			_axis = 0.0

	_think_timer -= 1
	if _think_timer > 0:
		return
	_think_timer = REACTION_FRAMES[difficulty] + randi() % 6
	_decide(me, foe)


func _decide(me: Fighter, foe: Fighter) -> void:
	var dist := _distance()
	var toward := signf(foe.position.x - me.position.x)
	_block = false

	if foe.is_attacking() and dist < 190.0 and randf() < BLOCK_CHANCE[difficulty]:
		_block = true
		_axis = 0.0
		return

	if dist > 150.0:
		_axis = toward
		if randf() < 0.06:
			_jump = true
	elif dist < 75.0 and randf() < 0.25:
		_axis = -toward
	else:
		_axis = 0.0
		if randf() < AGGRESSION[difficulty]:
			if dist > 110.0 or randf() < 0.4:
				_kick = true
			else:
				_punch = true
		elif randf() < 0.1:
			_jump = true
			_axis = toward


func _distance() -> float:
	return absf(fighter.opponent.position.x - fighter.position.x)


func get_move_axis() -> float:
	return _axis


func wants_jump() -> bool:
	return _jump


func wants_punch() -> bool:
	return _punch


func wants_kick() -> bool:
	return _kick


func wants_block() -> bool:
	return _block
