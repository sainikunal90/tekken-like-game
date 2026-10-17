class_name FightCamera
extends Camera3D
## Side-on fighting game camera. Stays centered between the two fighters,
## pulls back as they move apart and rises a little when someone jumps.

const MIN_DISTANCE := 6.2
const MAX_DISTANCE := 11.0

var models: Array[FighterModel] = []
## Seconds-ish of screen shake left (set by the fight on big hits).
var shake := 0.0

var _look_at := Vector3(0, 1, 0)


func _ready() -> void:
	fov = 42.0
	near = 0.1
	far = 400.0
	current = true


func snap() -> void:
	var target := _targets()
	global_position = target[0]
	_look_at = target[1]
	look_at(_look_at)


func _process(delta: float) -> void:
	if models.size() < 2:
		return
	var target := _targets()
	var weight := minf(1.0, delta * 5.0)
	global_position = global_position.lerp(target[0], weight)
	_look_at = _look_at.lerp(target[1], weight)
	look_at(_look_at)

	if shake > 0.0:
		shake = maxf(shake - delta * 40.0, 0.0)
		var amount := shake * 0.004
		h_offset = randf_range(-amount, amount)
		v_offset = randf_range(-amount, amount)
	else:
		h_offset = 0.0
		v_offset = 0.0


## Returns [camera position, point to look at].
func _targets() -> Array[Vector3]:
	var a := models[0].global_position
	var b := models[1].global_position
	var mid_x := (a.x + b.x) * 0.5
	var spread := absf(a.x - b.x)
	var air := maxf(a.y, b.y)
	var distance := clampf(4.2 + spread * 0.6, MIN_DISTANCE, MAX_DISTANCE)
	var pos := Vector3(mid_x, 1.45 + air * 0.4 + distance * 0.04, distance)
	var look := Vector3(mid_x, 1.3 + air * 0.5, 0.0)
	return [pos, look]
