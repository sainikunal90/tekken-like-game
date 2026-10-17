class_name Stage3D
extends Node3D
## Base class for 3D stages, with helpers to build low-poly scenery in code.
##
## Stage layout (meters):
## - The fighting floor is at y = 0.
## - Fighters move along the x axis between x = -7 and x = 7, at z = 0.
## - The camera looks from +z toward -z, so scenery goes at negative z
##   (background) and to the sides.
##
## Building stages in code keeps the repo small and lets you tweak scenery
## with numbers. You can also make a stage in the Godot editor instead:
## create a scene whose root uses a script that extends Stage3D.

const FIGHT_HALF_WIDTH := 7.0

var _rng := RandomNumberGenerator.new()


## Override in each stage to create its scenery.
func build() -> void:
	pass


# --------------------------------------------------------------------------
# Environment and lights
# --------------------------------------------------------------------------

func setup_environment(sky_top: Color, horizon: Color, ground: Color, ambient: Color,
		ambient_energy: float, fog_color: Color, fog_density: float) -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = sky_top
	sky_mat.sky_horizon_color = horizon
	sky_mat.ground_horizon_color = horizon
	sky_mat.ground_bottom_color = ground
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient
	env.ambient_light_energy = ambient_energy
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = fog_density > 0.0
	env.fog_light_color = fog_color
	env.fog_density = fog_density
	env.fog_sky_affect = 0.0

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)


func add_sun(color: Color, energy: float, pitch_deg: float, yaw_deg: float) -> DirectionalLight3D:
	var sun := DirectionalLight3D.new()
	sun.light_color = color
	sun.light_energy = energy
	sun.rotation_degrees = Vector3(pitch_deg, yaw_deg, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 30.0
	add_child(sun)
	return sun


# --------------------------------------------------------------------------
# Materials and primitive shapes
# --------------------------------------------------------------------------

func mat(color: Color, roughness := 0.9, emission := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m


func vertex_color_mat(roughness := 0.95) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = roughness
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func add_mesh(mesh: Mesh, pos: Vector3, material: Material, rot := Vector3.ZERO,
		scl := Vector3.ONE, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	(parent if parent else self).add_child(mi)
	return mi


func add_box(size: Vector3, pos: Vector3, material: Material, rot := Vector3.ZERO,
		parent: Node3D = null) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return add_mesh(mesh, pos, material, rot, Vector3.ONE, parent)


func add_cylinder(top_radius: float, bottom_radius: float, height: float, pos: Vector3,
		material: Material, segments := 12, parent: Node3D = null) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	return add_mesh(mesh, pos, material, Vector3.ZERO, Vector3.ONE, parent)


func add_sphere(radius: float, pos: Vector3, material: Material, scl := Vector3.ONE,
		segments := 12, parent: Node3D = null) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = maxi(4, segments / 2)
	return add_mesh(mesh, pos, material, Vector3.ZERO, scl, parent)


## Draws many copies of one mesh in a single draw call (good for phones).
func add_multimesh(mesh: Mesh, transforms: Array[Transform3D], material: Material) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = material
	add_child(mmi)
	return mmi


# --------------------------------------------------------------------------
# Terrain: a flat-shaded height-field with per-vertex colors
# --------------------------------------------------------------------------

## height_fn(x, z) -> float, color_fn(x, z, height) -> Color
func add_terrain(from: Vector2, to: Vector2, cells: Vector2i, height_fn: Callable,
		color_fn: Callable, cast_shadows := true) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := (to - from) / Vector2(cells)
	var heights := []
	for iz in cells.y + 1:
		var row := []
		for ix in cells.x + 1:
			var x := from.x + ix * step.x
			var z := from.y + iz * step.y
			row.append(height_fn.call(x, z))
		heights.append(row)

	for iz in cells.y:
		for ix in cells.x:
			var x0 := from.x + ix * step.x
			var z0 := from.y + iz * step.y
			var p00 := Vector3(x0, heights[iz][ix], z0)
			var p10 := Vector3(x0 + step.x, heights[iz][ix + 1], z0)
			var p01 := Vector3(x0, heights[iz + 1][ix], z0 + step.y)
			var p11 := Vector3(x0 + step.x, heights[iz + 1][ix + 1], z0 + step.y)
			_flat_triangle(st, p00, p11, p10, color_fn)
			_flat_triangle(st, p00, p01, p11, color_fn)

	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = vertex_color_mat()
	if not cast_shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func _flat_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color_fn: Callable) -> void:
	var normal := (c - a).cross(b - a).normalized()
	if normal.y < 0.0:
		normal = -normal
	var center := (a + b + c) / 3.0
	var color: Color = color_fn.call(center.x, center.z, center.y)
	for p in [a, b, c]:
		st.set_normal(normal)
		st.set_color(color)
		st.add_vertex(p)


# --------------------------------------------------------------------------
# Weather
# --------------------------------------------------------------------------

func add_precipitation(amount: int, area: Vector3, center: Vector3, fall_speed: float,
		drop_size: Vector3, color: Color, sway := 0.0) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = area.y / fall_speed
	p.preprocess = p.lifetime
	p.position = center
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(area.x * 0.5, 0.1, area.z * 0.5)
	p.direction = Vector3(0, -1, 0)
	p.spread = 4.0 + sway * 10.0
	p.gravity = Vector3(sway, 0, 0)
	p.initial_velocity_min = fall_speed * 0.85
	p.initial_velocity_max = fall_speed * 1.15
	var mesh := BoxMesh.new()
	mesh.size = drop_size
	var m := mat(color, 1.0)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = m
	p.mesh = mesh
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	return p


# --------------------------------------------------------------------------
# Small utilities
# --------------------------------------------------------------------------

func jitter(color: Color, amount: float) -> Color:
	var j := _rng.randf_range(-amount, amount)
	return Color(clampf(color.r + j, 0, 1), clampf(color.g + j, 0, 1), clampf(color.b + j, 0, 1))
