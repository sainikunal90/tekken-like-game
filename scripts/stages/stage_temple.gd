extends Stage3D
## Monsoon Temple: a wet stone courtyard in front of a sandstone temple at
## dusk, with flickering lamp pillars, palm trees and heavy rain.

var _flames: Array[OmniLight3D] = []
var _time := 0.0
var _noise := FastNoiseLite.new()


func build() -> void:
	_rng.seed = 21
	_noise.seed = 5
	_noise.frequency = 0.02

	setup_environment(
		Color(0.13, 0.11, 0.3), Color(0.93, 0.52, 0.38), Color(0.12, 0.1, 0.12),
		Color(0.5, 0.42, 0.62), 0.55, Color(0.5, 0.4, 0.5), 0.01)
	add_sun(Color(1.0, 0.62, 0.42), 1.0, -18.0, -50.0)

	_build_courtyard()
	_build_hills()
	_build_temple(Vector3(0, 0, -17), 1.0, true)
	_build_temple(Vector3(-13, 0, -12), 0.45, false)
	_build_temple(Vector3(13, 0, -12), 0.45, false)
	_build_lamp(Vector3(-5.5, 0, -5.5))
	_build_lamp(Vector3(5.5, 0, -5.5))
	_build_railings()
	_build_palms()
	add_precipitation(1100, Vector3(40, 16, 26), Vector3(0, 14, -5), 15.0,
			Vector3(0.012, 0.45, 0.012), Color(0.78, 0.82, 0.95, 0.35), -1.5)


func _process(delta: float) -> void:
	_time += delta
	for i in _flames.size():
		_flames[i].light_energy = 2.2 + sin(_time * 11.0 + i * 2.0) * 0.25 + randf() * 0.25


func _build_courtyard() -> void:
	var floor_mesh := add_terrain(Vector2(-40, -26), Vector2(40, 14), Vector2i(40, 20),
		func(_x: float, _z: float) -> float:
			return 0.0,
		func(x: float, z: float, _h: float) -> Color:
			var checker := (int(floor((x + 40.0) / 2.0)) + int(floor((z + 26.0) / 2.0))) % 2
			var base := Color(0.4, 0.35, 0.33) if checker == 0 else Color(0.46, 0.4, 0.37)
			if _noise.get_noise_2d(x * 4.0, z * 4.0) > 0.4:
				base = base.darkened(0.35)  # puddles
			return jitter(base, 0.02))
	# Rain-soaked stone is shiny.
	(floor_mesh.material_override as StandardMaterial3D).roughness = 0.35


func _build_hills() -> void:
	add_terrain(Vector2(-160, -150), Vector2(160, -30), Vector2i(64, 24),
		func(x: float, z: float) -> float:
			var rise := clampf((-z - 30.0) / 50.0, 0.0, 1.0)
			return (_noise.get_noise_2d(x * 0.5, z * 0.5) + 1.0) * 14.0 * rise - 1.0,
		func(_x: float, _z: float, h: float) -> Color:
			return jitter(Color(0.16, 0.22, 0.2).lerp(Color(0.24, 0.2, 0.3), clampf(h / 25.0, 0.0, 1.0)), 0.02),
		false)


## A Nagara-style temple: plinth, pillared hall in front and a tall
## stepped tower (shikhara) over the sanctum.
func _build_temple(origin: Vector3, s: float, with_hall: bool) -> void:
	var sandstone := mat(Color(0.66, 0.44, 0.32), 0.85)
	var dark := mat(Color(0.5, 0.32, 0.24), 0.85)
	var gold := mat(Color(0.98, 0.75, 0.3), 0.35, 0.3)
	var saffron := mat(Color(1.0, 0.5, 0.1), 0.8)
	saffron.cull_mode = BaseMaterial3D.CULL_DISABLED

	var plinth_h := 1.6 * s
	add_box(Vector3(18, 1.6, 12) * s, origin + Vector3(0, plinth_h * 0.5, 0), sandstone)
	for i in 3:  # front steps
		var h := plinth_h * (3 - i) / 3.0
		add_box(Vector3(6 * s, h, 0.6 * s), origin + Vector3(0, h * 0.5, 6.0 * s + (i + 0.5) * 0.6 * s), dark)

	var top := origin.y + plinth_h
	if with_hall:
		for i in 6:
			var x := origin.x - 6.0 * s + i * 2.4 * s
			add_cylinder(0.32 * s, 0.38 * s, 3.2 * s, Vector3(x, top + 1.6 * s, origin.z + 4.3 * s), sandstone, 10)
		add_box(Vector3(14.5, 0.5, 4.6) * s, Vector3(origin.x, top + 3.45 * s, origin.z + 3.6 * s), dark)
		add_box(Vector3(12, 0.5, 3.6) * s, Vector3(origin.x, top + 3.95 * s, origin.z + 3.6 * s), sandstone)
		add_box(Vector3(9, 0.5, 2.6) * s, Vector3(origin.x, top + 4.45 * s, origin.z + 3.6 * s), dark)

	# Sanctum and tower
	var tower_z := origin.z - 1.5 * s
	add_box(Vector3(7, 4, 7) * s, Vector3(origin.x, top + 2.0 * s, tower_z), sandstone)
	add_box(Vector3(1.8, 2.6, 0.2) * s, Vector3(origin.x, top + 1.3 * s, tower_z + 3.5 * s), mat(Color(0.12, 0.08, 0.06)))
	var y := top + 4.0 * s
	for i in 9:
		var size := (6.8 - i * 0.62) * s
		var h := 0.95 * s
		add_box(Vector3(size, h, size), Vector3(origin.x, y + h * 0.5, tower_z), sandstone if i % 2 == 0 else dark)
		y += h
	var amalaka := add_cylinder(1.1 * s, 1.1 * s, 0.45 * s, Vector3(origin.x, y + 0.22 * s, tower_z), dark, 16)
	amalaka.name = "Amalaka"
	add_sphere(0.38 * s, Vector3(origin.x, y + 0.8 * s, tower_z), gold)
	add_cylinder(0.03 * s, 0.03 * s, 2.2 * s, Vector3(origin.x, y + 1.9 * s, tower_z), mat(Color(0.3, 0.2, 0.1)), 4)
	var flag := add_box(Vector3(0.9, 0.5, 0.02) * s, Vector3(origin.x + 0.45 * s, y + 2.7 * s, tower_z), saffron)
	flag.rotation.z = -0.15


## Stone lamp pillar (deepastambha) with a flickering flame.
func _build_lamp(base: Vector3) -> void:
	var stone := mat(Color(0.38, 0.33, 0.32), 0.7)
	add_cylinder(0.5, 0.6, 0.4, base + Vector3(0, 0.2, 0), stone, 10)
	add_cylinder(0.18, 0.24, 3.4, base + Vector3(0, 2.1, 0), stone, 10)
	for i in 4:
		add_cylinder(0.42 - i * 0.05, 0.42 - i * 0.05, 0.08, base + Vector3(0, 1.2 + i * 0.6, 0), stone, 10)
	add_cylinder(0.45, 0.25, 0.25, base + Vector3(0, 3.9, 0), stone, 10)
	var fire := mat(Color(1.0, 0.55, 0.15), 1.0, 4.0)
	add_sphere(0.16, base + Vector3(0, 4.15, 0), fire, Vector3(1, 1.6, 1), 8)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.25)
	light.omni_range = 8.0
	light.light_energy = 2.2
	light.position = base + Vector3(0, 4.3, 0.4)
	add_child(light)
	_flames.append(light)


func _build_railings() -> void:
	var stone := mat(Color(0.5, 0.42, 0.38), 0.6)
	for side in [-1.0, 1.0]:
		for i in 4:
			var z := -2.0 + i * 1.4
			add_box(Vector3(0.35, 0.9, 0.35), Vector3(side * 8.2, 0.45, z), stone)
		add_box(Vector3(0.25, 0.15, 4.6), Vector3(side * 8.2, 0.95, 0.1), stone)


func _build_palms() -> void:
	var bark := mat(Color(0.42, 0.32, 0.22))
	var leaf := mat(Color(0.18, 0.42, 0.2), 0.8)
	leaf.cull_mode = BaseMaterial3D.CULL_DISABLED
	var spots := [Vector3(-17, 0, -6), Vector3(-21, 0, -14), Vector3(18, 0, -5),
			Vector3(22, 0, -15), Vector3(-26, 0, -4), Vector3(27, 0, -8), Vector3(-9, 0, -24), Vector3(10, 0, -25)]
	for base: Vector3 in spots:
		var lean := _rng.randf_range(-0.25, 0.25)
		var pos := base
		var segment_dir := Vector3(lean, 1.0, 0).normalized()
		for i in 7:
			var seg := add_cylinder(0.16, 0.2, 1.0, pos + segment_dir * 0.5, bark, 6)
			seg.rotation.z = -lean
			pos += segment_dir * 0.95
		for j in 8:
			var frond := add_box(Vector3(2.6, 0.03, 0.55), pos, leaf)
			frond.rotation = Vector3(0, j * TAU / 8.0, -0.45)
			frond.position += frond.basis.x * 1.1
