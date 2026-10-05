class_name FX
## Particle & visual effect factory. One-shot emitters free themselves.
## The equipped effect style (shop cosmetic) changes dust appearance.


static func _style() -> String:
	return SaveGame.data.get("fx", "classic")


static func _quad_mat(color: Color, emissive: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	if emissive:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 2.0
	return m


static func _one_shot(parent: Node, pos: Vector3, amount: int, lifetime: float, mat: ParticleProcessMaterial, draw_color: Color, size: float, emissive: bool = false) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = maxi(int(float(amount) * G.particle_scale()), 2)
	p.lifetime = lifetime
	p.one_shot = true
	p.explosiveness = 1.0
	p.process_material = mat
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	quad.material = _quad_mat(draw_color, emissive)
	p.draw_pass_1 = quad
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


static func _base_pm(gravity: Vector3, vel_min: float, vel_max: float, spread: float, color: Color) -> ParticleProcessMaterial:
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = spread
	pm.gravity = gravity
	pm.initial_velocity_min = vel_min
	pm.initial_velocity_max = vel_max
	pm.scale_min = 0.6
	pm.scale_max = 1.3
	pm.color = color
	pm.damping_min = 0.4
	pm.damping_max = 1.0
	return pm


## Dust burst when removing hay.
static func dust(parent: Node, pos: Vector3, intensity: float = 1.0) -> void:
	match _style():
		"sparkle":
			var pm := _base_pm(Vector3(0, -1.5, 0), 0.8, 1.8, 70.0, Color(1.0, 0.85, 0.35, 0.9))
			_one_shot(parent, pos, int(10 * intensity), 0.5, pm, Color(1, 0.9, 0.5), 0.05, true)
		"leaves":
			var pm2 := _base_pm(Vector3(0, -2.5, 0), 0.6, 1.4, 85.0, Color(0.5, 0.75, 0.3, 0.9))
			pm2.angular_velocity_min = -360.0
			pm2.angular_velocity_max = 360.0
			_one_shot(parent, pos, int(8 * intensity), 0.7, pm2, Color(0.55, 0.8, 0.35), 0.09)
		"fireflies":
			var pm3 := _base_pm(Vector3(0, 0.6, 0), 0.2, 0.7, 180.0, Color(0.7, 1.0, 0.4, 0.9))
			_one_shot(parent, pos, int(7 * intensity), 1.1, pm3, Color(0.75, 1.0, 0.45), 0.045, true)
		_:
			var pm4 := _base_pm(Vector3(0, -0.8, 0), 0.5, 1.3, 75.0, Color(0.8, 0.7, 0.45, 0.65))
			_one_shot(parent, pos, int(9 * intensity), 0.6, pm4, Color(0.85, 0.75, 0.5, 0.8), 0.1)
	# flying hay debris bits
	var pm5 := _base_pm(Vector3(0, -5.0, 0), 1.2, 2.6, 60.0, Color(0.85, 0.7, 0.3))
	pm5.angular_velocity_min = -480.0
	pm5.angular_velocity_max = 480.0
	_one_shot(parent, pos, int(6 * intensity), 0.55, pm5, Color(0.9, 0.75, 0.35), 0.06)


## Golden shimmer - near-needle feedback.
static func shimmer(parent: Node, pos: Vector3, strong: bool = false) -> void:
	var pm := _base_pm(Vector3(0, 0.9, 0), 0.3, 0.9, 50.0, Color(1.0, 0.95, 0.6, 0.9))
	_one_shot(parent, pos, 14 if strong else 7, 0.9, pm, Color(1, 0.95, 0.6), 0.04, true)


## Coin/collect burst.
static func burst(parent: Node, pos: Vector3, color: Color) -> void:
	var pm := _base_pm(Vector3(0, -4.0, 0), 1.5, 3.0, 85.0, color)
	_one_shot(parent, pos, 16, 0.8, pm, color, 0.07, true)


## Victory confetti.
static func confetti(parent: Node, pos: Vector3) -> void:
	var colors := [Color(1, 0.4, 0.4), Color(0.4, 0.8, 1), Color(1, 0.9, 0.3), Color(0.5, 1, 0.5), Color(0.9, 0.5, 1)]
	for c: Color in colors:
		var pm := _base_pm(Vector3(0, -3.0, 0), 2.0, 4.5, 80.0, c)
		pm.angular_velocity_min = -540.0
		pm.angular_velocity_max = 540.0
		_one_shot(parent, pos, 10, 1.6, pm, c, 0.08)


## Wind gust (fan tool).
static func wind(parent: Node, pos: Vector3) -> void:
	var pm := _base_pm(Vector3(0, 0.5, 0), 2.0, 4.0, 160.0, Color(0.9, 0.9, 0.85, 0.35))
	_one_shot(parent, pos, 24, 0.7, pm, Color(0.95, 0.95, 0.9, 0.4), 0.14)


## Pulsing glow marker (magnet scan result). Frees itself.
static func marker(parent: Node, pos: Vector3, color: Color, duration: float = 3.0) -> void:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.09
	s.height = 0.18
	mi.mesh = s
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 3.0
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	parent.add_child(mi)
	mi.global_position = pos
	var tw := mi.create_tween().set_loops(int(duration * 2.0))
	tw.tween_property(mi, "scale", Vector3.ONE * 1.8, 0.25).set_trans(Tween.TRANS_SINE)
	tw.tween_property(mi, "scale", Vector3.ONE * 0.8, 0.25).set_trans(Tween.TRANS_SINE)
	tw.finished.connect(mi.queue_free)


## Pulsing ground ring used by hints.
static func make_hint_ring(radius: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = maxf(radius - 0.06, 0.05)
	t.outer_radius = radius
	mi.mesh = t
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 2.2
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	return mi
