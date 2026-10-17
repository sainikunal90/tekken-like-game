class_name Arena
extends Node2D
## The stage background: a monsoon evening with hills, a temple silhouette,
## a stone floor and light rain. Drawn in code so the project needs no art
## files yet; replace with a painted background or 3D stage later.

var size := Vector2(1280, 720)
var floor_y := 620.0

var _rain: Array[Vector3] = []  # x, y, speed
var _time := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 90:
		_rain.append(Vector3(rng.randf() * size.x, rng.randf() * size.y, rng.randf_range(700.0, 1100.0)))


func _process(delta: float) -> void:
	_time += delta
	for i in _rain.size():
		var r := _rain[i]
		r.y += r.z * delta
		r.x -= r.z * 0.15 * delta
		if r.y > floor_y:
			r.y = -20.0
			r.x = randf() * (size.x + 200.0)
		_rain[i] = r
	queue_redraw()


func _draw() -> void:
	var w := size.x
	# Sky gradient
	var sky_top := Color(0.16, 0.12, 0.3)
	var sky_bottom := Color(0.85, 0.45, 0.35)
	draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, floor_y), Vector2(0, floor_y)]),
		PackedColorArray([sky_top, sky_top, sky_bottom, sky_bottom]))

	# Setting sun behind clouds
	draw_circle(Vector2(w * 0.72, floor_y - 250), 70.0, Color(1.0, 0.75, 0.45, 0.85))
	for i in 4:
		var y := floor_y - 230 + i * 18
		draw_rect(Rect2(w * 0.62 + i * 25, y, 260 - i * 40, 8), Color(0.55, 0.3, 0.4, 0.55))

	# Far hills
	_hills(floor_y - 170, 90.0, 0.004, Color(0.3, 0.2, 0.38))
	# Temple silhouette
	var tx := w * 0.25
	var temple := Color(0.2, 0.13, 0.25)
	draw_rect(Rect2(tx - 60, floor_y - 210, 120, 120), temple)
	draw_colored_polygon(PackedVector2Array([
		Vector2(tx - 75, floor_y - 210), Vector2(tx, floor_y - 330), Vector2(tx + 75, floor_y - 210)]), temple)
	draw_rect(Rect2(tx - 4, floor_y - 360, 8, 34), temple)
	# Near hills
	_hills(floor_y - 90, 60.0, 0.007, Color(0.2, 0.15, 0.24))

	# Stone floor
	draw_rect(Rect2(0, floor_y, w, size.y - floor_y + 400), Color(0.27, 0.22, 0.24))
	draw_line(Vector2(0, floor_y), Vector2(w, floor_y), Color(0.55, 0.45, 0.42), 4.0)
	var tiles := 14
	for i in tiles + 1:
		var x := w * i / float(tiles)
		var x_bottom := w * 0.5 + (x - w * 0.5) * 1.6
		draw_line(Vector2(x, floor_y), Vector2(x_bottom, size.y + 200), Color(0.2, 0.16, 0.18), 2.0)
	for j in 3:
		var y := floor_y + 22 + j * j * 22
		draw_line(Vector2(0, y), Vector2(w, y), Color(0.2, 0.16, 0.18), 2.0)

	# Rain
	for r in _rain:
		draw_line(Vector2(r.x, r.y), Vector2(r.x - 4, r.y + 18), Color(0.8, 0.85, 1.0, 0.28), 1.5)


func _hills(base_y: float, amp: float, freq: float, color: Color) -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2(0, floor_y))
	var steps := 40
	for i in steps + 1:
		var x := size.x * i / float(steps)
		var y := base_y - amp * (0.5 + 0.5 * sin(x * freq + base_y)) - 20.0 * sin(x * freq * 3.1)
		pts.append(Vector2(x, y))
	pts.append(Vector2(size.x, floor_y))
	draw_colored_polygon(pts, color)
