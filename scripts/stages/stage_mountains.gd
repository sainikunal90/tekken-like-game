extends Stage3D
## Himalayan Pass: a stone ledge high in the mountains with snowy peaks,
## a pine forest, a small white stupa, prayer flags and light snowfall.

const FLAG_COLORS := [
	Color(0.15, 0.35, 0.85), Color(0.95, 0.95, 0.95), Color(0.85, 0.15, 0.15),
	Color(0.15, 0.6, 0.25), Color(0.95, 0.8, 0.15),
]

var _noise := FastNoiseLite.new()
var _ridge := FastNoiseLite.new()


func build() -> void:
	_rng.seed = 11
	_noise.seed = 3
	_noise.frequency = 0.03
	_noise.fractal_octaves = 3
	_ridge.seed = 8
	_ridge.frequency = 0.011
	_ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_ridge.fractal_octaves = 4

	setup_environment(
		Color(0.2, 0.4, 0.78), Color(0.78, 0.87, 0.97), Color(0.35, 0.35, 0.4),
		Color(0.62, 0.7, 0.85), 0.3, Color(0.7, 0.8, 0.95), 0.0009)
	add_sun(Color(1.0, 0.95, 0.86), 0.95, -35.0, 30.0)

	_build_ground()
	_build_peaks()
	_build_ledge()
	_build_trees()
	_build_rocks()
	_build_stupa(Vector3(-13.0, ground_height(-13.0, -10.0), -10.0))
	_build_prayer_flags()
	add_precipitation(450, Vector3(36, 14, 22), Vector3(0, 12, -4), 1.1,
			Vector3(0.05, 0.05, 0.05), Color(1, 1, 1, 0.9), 0.4)


## Height of the near ground at (x, z). Flat where the fight happens,
## rising into hills behind and dropping off as a cliff in front.
func ground_height(x: float, z: float) -> float:
	var back := maxf(0.0, -z - 4.0) + maxf(0.0, absf(x) - 11.0) * 0.6
	var bumps := (_noise.get_noise_2d(x, z) + 1.0) * 0.5
	var h := back * 0.08 + bumps * 2.5 * clampf(back / 8.0, 0.0, 1.0)
	if z > 5.0:
		h -= (z - 5.0) * 1.2
	return h


func _build_ground() -> void:
	add_terrain(Vector2(-70, -42), Vector2(70, 14), Vector2i(70, 28),
		ground_height,
		func(x: float, z: float, h: float) -> Color:
			var n := _noise.get_noise_2d(x * 3.0, z * 3.0)
			if h > 5.0 and n > 0.15:
				return jitter(Color(0.93, 0.95, 0.98), 0.03)
			if h > 3.5 or n < -0.35:
				return jitter(Color(0.47, 0.45, 0.44), 0.04)
			if n > 0.2:
				return jitter(Color(0.5, 0.42, 0.3), 0.04)
			return jitter(Color(0.45, 0.5, 0.3), 0.04))


func _build_peaks() -> void:
	add_terrain(Vector2(-260, -280), Vector2(260, -40), Vector2i(104, 40),
		func(x: float, z: float) -> float:
			var ridge := (_ridge.get_noise_2d(x * 0.8, z * 0.8) + 1.0) * 0.5
			var rise := clampf((-z - 45.0) / 150.0, 0.0, 1.0)
			return pow(ridge, 2.0) * 110.0 * rise + rise * 10.0 - 1.0,
		func(x: float, z: float, h: float) -> Color:
			var n := _noise.get_noise_2d(x * 0.7, z * 0.7)
			if h > 22.0 + n * 8.0:
				return jitter(Color(0.95, 0.96, 1.0), 0.02)
			if h > 10.0 + n * 6.0:
				return jitter(Color(0.5, 0.49, 0.53), 0.05)
			return jitter(Color(0.3, 0.37, 0.3), 0.04),
		false)


## The flat stone platform the fighters stand on.
func _build_ledge() -> void:
	var stone := mat(Color(0.3, 0.29, 0.29), 0.95)
	add_cylinder(10.5, 11.0, 0.6, Vector3(0, -0.29, -0.5), stone, 10)
	var slab := mat(Color(0.35, 0.33, 0.31), 0.9)
	for i in 9:
		var x := -8.0 + i * 2.0
		add_box(Vector3(1.9, 0.05, 3.4), Vector3(x, 0.025, 0.0), slab if i % 2 == 0 else stone)
	var snow := mat(Color(0.96, 0.97, 1.0), 0.8)
	for i in 6:
		var angle := _rng.randf_range(0.2, PI - 0.2)
		var pos := Vector3(cos(angle) * 9.8, 0.05, sin(angle) * 6.0 - 0.5)
		add_sphere(1.0, pos, snow, Vector3(_rng.randf_range(0.8, 1.6), 0.12, _rng.randf_range(0.6, 1.2)), 8)


func _build_trees() -> void:
	var trunks: Array[Transform3D] = []
	var layers: Array = [[], [], []]
	for i in 160:
		var x := _rng.randf_range(-65.0, 65.0)
		var z := _rng.randf_range(-40.0, 4.0)
		if absf(x) < 18.0 and z > -24.0:
			continue  # keep the area behind the fighters clear
		var y := ground_height(x, z)
		var s := _rng.randf_range(0.8, 1.6)
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * s)
		trunks.append(Transform3D(basis, Vector3(x, y + 0.5 * s, z)))
		for l in 3:
			layers[l].append(Transform3D(basis, Vector3(x, y + (1.3 + l * 0.8) * s, z)))

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.08
	trunk_mesh.bottom_radius = 0.14
	trunk_mesh.height = 1.0
	trunk_mesh.radial_segments = 6
	add_multimesh(trunk_mesh, trunks, mat(Color(0.35, 0.24, 0.16)))

	var greens := [Color(0.13, 0.32, 0.2), Color(0.16, 0.38, 0.23), Color(0.2, 0.44, 0.27)]
	for l in 3:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 1.25 - l * 0.32
		cone.height = 1.5 - l * 0.2
		cone.radial_segments = 7
		var typed: Array[Transform3D] = []
		typed.assign(layers[l])
		add_multimesh(cone, typed, mat(greens[l]))


func _build_rocks() -> void:
	var rock := mat(Color(0.32, 0.31, 0.32), 1.0)
	# Boulders marking the edges of the fighting area.
	for side in [-1.0, 1.0]:
		for i in 3:
			var pos := Vector3(side * (8.6 + i * 0.9), 0.3, -1.4 + i * 1.3)
			add_sphere(1.0, pos, rock, Vector3(1.2, 0.9, 1.0) * _rng.randf_range(0.7, 1.2), 6)
	for i in 40:
		var x := _rng.randf_range(-50.0, 50.0)
		var z := _rng.randf_range(-36.0, 6.0)
		if absf(x) < 14.0 and z > -14.0:
			continue
		var s := _rng.randf_range(0.5, 2.2)
		add_sphere(1.0, Vector3(x, ground_height(x, z) + s * 0.3, z), rock,
				Vector3(s * 1.3, s * 0.8, s), 6)


func _build_stupa(base: Vector3) -> void:
	var white := mat(Color(0.95, 0.94, 0.9), 0.8)
	var gold := mat(Color(0.95, 0.72, 0.25), 0.4, 0.15)
	add_box(Vector3(4.0, 1.0, 4.0), base + Vector3(0, 0.5, 0), white)
	add_box(Vector3(3.2, 0.6, 3.2), base + Vector3(0, 1.3, 0), white)
	add_sphere(1.5, base + Vector3(0, 2.3, 0), white, Vector3(1, 0.85, 1), 14)
	add_box(Vector3(1.0, 0.6, 1.0), base + Vector3(0, 3.6, 0), white)
	var spire := add_cylinder(0.05, 0.45, 2.0, base + Vector3(0, 4.9, 0), gold, 10)
	spire.name = "StupaSpire"
	add_sphere(0.18, base + Vector3(0, 6.0, 0), gold)


func _build_prayer_flags() -> void:
	var wood := mat(Color(0.4, 0.28, 0.18))
	var flag_mats: Array[StandardMaterial3D] = []
	for c: Color in FLAG_COLORS:
		var m := mat(c, 0.9)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		flag_mats.append(m)

	# Two strings of flags running back from the sides of the ledge, leaving
	# the view behind the fighters open.
	for side in [-1.0, 1.0]:
		var start := Vector3(side * 10.0, 4.2, -1.5)
		var end := Vector3(side * 4.5, 5.0, -16.0)
		for pole: Vector3 in [start, end]:
			var ground := ground_height(pole.x, pole.z)
			add_cylinder(0.07, 0.09, pole.y - ground + 0.2, Vector3(pole.x, (pole.y + ground) * 0.5, pole.z), wood, 6)
		var count := 26
		var yaw := atan2(end.x - start.x, end.z - start.z) + PI * 0.5
		for i in count:
			var t := (i + 0.5) / count
			var p := start.lerp(end, t)
			p.y -= 1.0 * (1.0 - pow(t * 2.0 - 1.0, 2.0))  # rope sag
			var flag := add_box(Vector3(0.4, 0.45, 0.01), p + Vector3(0, -0.26, 0), flag_mats[i % flag_mats.size()])
			flag.rotation = Vector3(0, yaw, _rng.randf_range(-0.12, 0.12))
			flag.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
