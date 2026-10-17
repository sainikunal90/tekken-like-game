class_name FighterModel
extends Node3D
## Shows a Fighter as an animated 3D character.
##
## Every frame it reads the fighter's logic state (position, facing, IDLE /
## WALK / ATTACK / HITSTUN ...) and plays the matching animation. It never
## changes gameplay, so you can swap models freely.
##
## Attack animations are re-timed so the moment of impact in the animation
## (MoveData.impact_time) lines up with the move's active frames.

const PIXELS_PER_METER := 100.0
## Fighters turn slightly toward the camera so you see more than a profile.
const TURN_TOWARD_CAMERA := 0.35

const ANIM_IDLE := "Unarmed_Idle"
const ANIM_WALK := "Walking_A"
const ANIM_WALK_BACK := "Walking_Backwards"
const ANIM_JUMP := "Jump_Idle"
const ANIM_BLOCK := "Blocking"
const ANIM_BLOCK_HIT := "Block_Hit"
const ANIM_HIT := "Hit_A"
const ANIM_KO := "Death_A"
const ANIM_WIN := "Cheer"
const LOOPING := [ANIM_IDLE, ANIM_WALK, ANIM_WALK_BACK, ANIM_JUMP, ANIM_BLOCK, ANIM_WIN]

## Accessories attached to bones that stay visible. Everything else attached
## to the hands (swords, shields, mugs...) is hidden - this is a fist fight.
const KEEP_ATTACHMENTS := ["Hat", "Helmet", "Cape", "Hood"]

var fighter: Fighter
var arena_center_x := 700.0

var _model: Node3D
var _anim: AnimationPlayer
var _materials: Array[BaseMaterial3D] = []
var _current := ""
var _last_state := -1
var _last_frames := 0
var _yaw := 0.0
var _flashing := false


func setup(p_fighter: Fighter, center_x: float) -> void:
	fighter = p_fighter
	arena_center_x = center_x
	var data := fighter.data

	_model = data.model_scene.instantiate() as Node3D
	_model.scale = Vector3.ONE * data.model_scale
	add_child(_model)

	_anim = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	for anim_name: String in LOOPING:
		if _anim.has_animation(anim_name):
			_anim.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR

	for node in _model.find_children("*", "BoneAttachment3D", true, false):
		var keep := false
		for word: String in KEEP_ATTACHMENTS:
			if word in String(node.name):
				keep = true
		(node as Node3D).visible = keep

	# Give each fighter its own copy of the materials so we can tint player 2
	# in mirror matches and flash white on hits.
	for node in _model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		for i in mesh_instance.get_surface_override_material_count():
			var source := mesh_instance.get_active_material(i) as BaseMaterial3D
			if source == null:
				continue
			var copy := source.duplicate() as BaseMaterial3D
			if fighter.use_alt_colors:
				copy.albedo_color = data.alt_tint
			mesh_instance.set_surface_override_material(i, copy)
			_materials.append(copy)

	_yaw = _target_yaw()
	_sync_transform(1.0)
	_anim.play(ANIM_IDLE)
	_current = ANIM_IDLE


func _process(delta: float) -> void:
	if fighter == null:
		return
	_sync_transform(minf(1.0, delta * 14.0))
	_update_animation()
	_update_flash()


func world_position_of(arena_point: Vector2) -> Vector3:
	return Vector3((arena_point.x - arena_center_x) / PIXELS_PER_METER,
			(fighter.floor_y - arena_point.y) / PIXELS_PER_METER, 0.0)


func _sync_transform(turn_weight: float) -> void:
	position = world_position_of(fighter.position)
	_yaw = lerp_angle(_yaw, _target_yaw(), turn_weight)
	rotation.y = _yaw


func _target_yaw() -> float:
	return (PI * 0.5 - TURN_TOWARD_CAMERA) * fighter.facing


func _update_animation() -> void:
	var f := fighter
	var restarted := f.state != _last_state or f.state_frames < _last_frames
	_last_state = f.state
	_last_frames = f.state_frames

	var anim_name := ANIM_IDLE
	var speed := 1.0
	var blend := 0.15
	var one_shot := false

	match f.state:
		Fighter.State.IDLE:
			anim_name = ANIM_WIN if f.celebrating else ANIM_IDLE
		Fighter.State.WALK:
			var forward := f.velocity.x * f.facing >= 0.0
			anim_name = ANIM_WALK if forward else ANIM_WALK_BACK
			speed = clampf(absf(f.velocity.x) / 220.0, 0.6, 1.6)
		Fighter.State.AIR:
			anim_name = ANIM_JUMP
		Fighter.State.BLOCK:
			anim_name = ANIM_BLOCK
		Fighter.State.ATTACK:
			var m := f.current_move
			if m != null:
				anim_name = m.animation
				speed = _attack_speed(m, f.state_frames)
				blend = 0.05
				one_shot = true
		Fighter.State.HITSTUN:
			anim_name = ANIM_HIT
			speed = _fit_speed(anim_name, f.stun_frames)
			blend = 0.05
			one_shot = true
		Fighter.State.BLOCKSTUN:
			anim_name = ANIM_BLOCK_HIT
			speed = _fit_speed(anim_name, f.stun_frames) * 2.0
			blend = 0.05
			one_shot = true
		Fighter.State.KO:
			anim_name = ANIM_KO
			blend = 0.1
			one_shot = true

	if not _anim.has_animation(anim_name):
		anim_name = ANIM_IDLE

	if anim_name != _current or (one_shot and restarted):
		var same := anim_name == _current
		_anim.play(anim_name, blend)
		if same:
			_anim.seek(0.0, true)
		_current = anim_name

	# Freeze the pose during hitstop so hits feel heavy.
	_anim.speed_scale = 0.0 if f.hitstop > 0 else speed


## Wind-up plays fast enough to reach the impact pose by the middle of the
## active frames; recovery then plays the rest more slowly.
func _attack_speed(m: MoveData, frame: int) -> float:
	var windup_frames := m.startup_frames + m.active_frames * 0.5
	if frame < windup_frames:
		return m.impact_time / maxf(windup_frames / 60.0, 0.01)
	var rest_frames := maxf(m.total_frames() - windup_frames, 1.0)
	return m.recovery_time / (rest_frames / 60.0)


func _fit_speed(anim_name: String, frames: int) -> float:
	if not _anim.has_animation(anim_name) or frames <= 0:
		return 1.0
	return _anim.get_animation(anim_name).length / (frames / 60.0)


func _update_flash() -> void:
	var flash := fighter.hit_flash > 0
	if flash == _flashing:
		return
	_flashing = flash
	for mat in _materials:
		mat.emission_enabled = flash
		if flash:
			mat.emission = Color(1.0, 0.9, 0.8)
			mat.emission_energy_multiplier = 0.8
