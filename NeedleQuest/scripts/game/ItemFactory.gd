class_name ItemFactory
## Builds original low-poly 3D models for every collectible, the needle,
## decoys, chests and movable props. Pure procedural geometry - no
## external assets, tiny memory footprint, mobile friendly.


static func _mat(color: Color, metallic: float = 0.0, rough: float = 0.7, emission: Color = Color.BLACK, emission_strength: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = rough
	if emission_strength > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = emission_strength
	return m


static func _mesh_node(mesh: Mesh, mat: StandardMaterial3D, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func make_item(id: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Item_" + id
	match id:
		"coin":
			var c := CylinderMesh.new()
			c.top_radius = 0.09
			c.bottom_radius = 0.09
			c.height = 0.025
			root.add_child(_mesh_node(c, _mat(Color(0.95, 0.78, 0.2), 0.9, 0.3, Color(0.9, 0.7, 0.2), 0.3)))
		"button":
			var c := CylinderMesh.new()
			c.top_radius = 0.07
			c.bottom_radius = 0.07
			c.height = 0.02
			root.add_child(_mesh_node(c, _mat(Color(0.35, 0.25, 0.2), 0.0, 0.5)))
		"bolt":
			var head := CylinderMesh.new()
			head.top_radius = 0.05
			head.bottom_radius = 0.05
			head.height = 0.03
			head.radial_segments = 6
			root.add_child(_mesh_node(head, _mat(Color(0.6, 0.6, 0.65), 0.85, 0.4)))
			var shaft := CylinderMesh.new()
			shaft.top_radius = 0.02
			shaft.bottom_radius = 0.02
			shaft.height = 0.1
			root.add_child(_mesh_node(shaft, _mat(Color(0.55, 0.55, 0.6), 0.85, 0.45), Vector3(0, -0.06, 0)))
		"gem":
			var g := SphereMesh.new()
			g.radius = 0.08
			g.height = 0.16
			g.radial_segments = 6
			g.rings = 3
			root.add_child(_mesh_node(g, _mat(Color(0.3, 0.6, 1.0), 0.2, 0.1, Color(0.3, 0.6, 1.0), 0.8)))
		"key":
			var ring := TorusMesh.new()
			ring.inner_radius = 0.035
			ring.outer_radius = 0.065
			root.add_child(_mesh_node(ring, _mat(Color(0.75, 0.6, 0.25), 0.85, 0.35)))
			var shaft := BoxMesh.new()
			shaft.size = Vector3(0.025, 0.14, 0.02)
			root.add_child(_mesh_node(shaft, _mat(Color(0.75, 0.6, 0.25), 0.85, 0.35), Vector3(0, -0.1, 0)))
			var tooth := BoxMesh.new()
			tooth.size = Vector3(0.05, 0.025, 0.02)
			root.add_child(_mesh_node(tooth, _mat(Color(0.75, 0.6, 0.25), 0.85, 0.35), Vector3(0.025, -0.15, 0)))
		"toy":
			var body := BoxMesh.new()
			body.size = Vector3(0.1, 0.1, 0.08)
			root.add_child(_mesh_node(body, _mat(Color(0.9, 0.3, 0.3), 0.0, 0.6)))
			var head := SphereMesh.new()
			head.radius = 0.05
			head.height = 0.1
			root.add_child(_mesh_node(head, _mat(Color(0.95, 0.8, 0.6), 0.0, 0.6), Vector3(0, 0.09, 0)))
		"horseshoe":
			var t := TorusMesh.new()
			t.inner_radius = 0.05
			t.outer_radius = 0.1
			var mi := _mesh_node(t, _mat(Color(0.5, 0.5, 0.55), 0.8, 0.5))
			mi.scale = Vector3(1, 0.5, 1)
			root.add_child(mi)
		"photo":
			var ph := BoxMesh.new()
			ph.size = Vector3(0.16, 0.005, 0.12)
			root.add_child(_mesh_node(ph, _mat(Color(0.9, 0.88, 0.8), 0.0, 0.8)))
			var inner := BoxMesh.new()
			inner.size = Vector3(0.12, 0.007, 0.08)
			root.add_child(_mesh_node(inner, _mat(Color(0.45, 0.4, 0.35), 0.0, 0.8)))
		"watch":
			var w := CylinderMesh.new()
			w.top_radius = 0.08
			w.bottom_radius = 0.08
			w.height = 0.03
			root.add_child(_mesh_node(w, _mat(Color(0.85, 0.7, 0.3), 0.9, 0.25, Color(0.8, 0.65, 0.3), 0.2)))
			var face := CylinderMesh.new()
			face.top_radius = 0.06
			face.bottom_radius = 0.06
			face.height = 0.035
			root.add_child(_mesh_node(face, _mat(Color(0.95, 0.95, 0.9), 0.1, 0.2)))
		"ring":
			var r := TorusMesh.new()
			r.inner_radius = 0.03
			r.outer_radius = 0.055
			root.add_child(_mesh_node(r, _mat(Color(0.95, 0.8, 0.3), 0.95, 0.15, Color(0.9, 0.75, 0.3), 0.3)))
			var stone := SphereMesh.new()
			stone.radius = 0.02
			stone.height = 0.04
			root.add_child(_mesh_node(stone, _mat(Color(0.9, 0.3, 0.5), 0.3, 0.1, Color(0.9, 0.3, 0.5), 0.9), Vector3(0, 0.055, 0)))
		"artifact":
			var a := PrismMesh.new()
			a.size = Vector3(0.14, 0.16, 0.12)
			root.add_child(_mesh_node(a, _mat(Color(0.55, 0.5, 0.42), 0.0, 0.9)))
		"treasure":
			var base := BoxMesh.new()
			base.size = Vector3(0.16, 0.1, 0.12)
			root.add_child(_mesh_node(base, _mat(Color(0.5, 0.33, 0.15), 0.0, 0.8)))
			var lid := BoxMesh.new()
			lid.size = Vector3(0.16, 0.05, 0.12)
			root.add_child(_mesh_node(lid, _mat(Color(0.85, 0.7, 0.25), 0.8, 0.35, Color(0.85, 0.7, 0.25), 0.25), Vector3(0, 0.075, 0)))
		"nail":
			root.add_child(_needle_shape(Color(0.55, 0.35, 0.25), 0.4, 0.016, 0.0))
		"golden_needle":
			root.add_child(_needle_shape(Color(1.0, 0.85, 0.3), 0.5, 0.013, 1.2))
		"legendary_needle":
			root.add_child(_needle_shape(Color(0.85, 0.5, 1.0), 0.55, 0.014, 2.0))
		_:
			var s := SphereMesh.new()
			s.radius = 0.07
			s.height = 0.14
			root.add_child(_mesh_node(s, _mat(Color.GRAY)))
	return root


static func make_needle() -> Node3D:
	var root := Node3D.new()
	root.name = "Needle"
	root.add_child(_needle_shape(Color(0.85, 0.88, 0.95), 0.5, 0.012, 0.6))
	return root


static func _needle_shape(color: Color, length: float, radius: float, glow: float) -> Node3D:
	var n := Node3D.new()
	var shaft := CylinderMesh.new()
	shaft.top_radius = radius * 0.3
	shaft.bottom_radius = radius
	shaft.height = length
	var mat := _mat(color, 0.95, 0.15, color, glow)
	var mi := _mesh_node(shaft, mat)
	mi.rotation_degrees = Vector3(0, 0, 90)
	n.add_child(mi)
	# the needle "eye"
	var eye := TorusMesh.new()
	eye.inner_radius = radius * 0.8
	eye.outer_radius = radius * 2.4
	var eye_mi := _mesh_node(eye, mat, Vector3(-length * 0.52, 0, 0))
	eye_mi.rotation_degrees = Vector3(0, 90, 0)
	n.add_child(eye_mi)
	return n


static func make_chest() -> Node3D:
	var root := Node3D.new()
	root.name = "Chest"
	var base := BoxMesh.new()
	base.size = Vector3(0.42, 0.26, 0.3)
	root.add_child(_mesh_node(base, _mat(Color(0.45, 0.3, 0.14), 0.0, 0.85), Vector3(0, 0.13, 0)))
	var band := BoxMesh.new()
	band.size = Vector3(0.44, 0.06, 0.32)
	root.add_child(_mesh_node(band, _mat(Color(0.7, 0.6, 0.3), 0.8, 0.4), Vector3(0, 0.14, 0)))
	var lid := BoxMesh.new()
	lid.size = Vector3(0.42, 0.12, 0.3)
	var lid_mi := _mesh_node(lid, _mat(Color(0.5, 0.34, 0.16), 0.0, 0.85), Vector3(0, 0.32, 0))
	lid_mi.name = "Lid"
	root.add_child(lid_mi)
	return root


static func make_prop(kind: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Prop_" + kind
	match kind:
		"crate":
			var b := BoxMesh.new()
			b.size = Vector3(0.55, 0.5, 0.55)
			var mi := _mesh_node(b, _mat(Color(0.6, 0.44, 0.22), 0.0, 0.9), Vector3(0, 0.25, 0))
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			root.add_child(mi)
			var edge := BoxMesh.new()
			edge.size = Vector3(0.58, 0.07, 0.58)
			root.add_child(_mesh_node(edge, _mat(Color(0.45, 0.32, 0.15), 0.0, 0.9), Vector3(0, 0.46, 0)))
		"barrel":
			var c := CylinderMesh.new()
			c.top_radius = 0.24
			c.bottom_radius = 0.24
			c.height = 0.55
			var mi2 := _mesh_node(c, _mat(Color(0.5, 0.35, 0.18), 0.0, 0.85), Vector3(0, 0.275, 0))
			mi2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			root.add_child(mi2)
			var hoop := TorusMesh.new()
			hoop.inner_radius = 0.23
			hoop.outer_radius = 0.26
			root.add_child(_mesh_node(hoop, _mat(Color(0.4, 0.4, 0.45), 0.8, 0.4), Vector3(0, 0.15, 0)))
			var hoop2 := TorusMesh.new()
			hoop2.inner_radius = 0.23
			hoop2.outer_radius = 0.26
			root.add_child(_mesh_node(hoop2, _mat(Color(0.4, 0.4, 0.45), 0.8, 0.4), Vector3(0, 0.42, 0)))
	return root
