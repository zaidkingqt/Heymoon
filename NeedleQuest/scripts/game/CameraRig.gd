extends Node3D
## Touch-first orbit camera:
##  - 1 finger drag  -> orbit (yaw/pitch)
##  - 2 finger pinch -> zoom
##  - 2 finger drag  -> pan across the ground
##  - quick tap      -> "tap" signal (interaction)
##  - mouse wheel    -> zoom (desktop testing)
## All motion is smoothed (lerped) each frame.

signal tapped(screen_pos: Vector2)
signal orbited
signal zoomed

const TAP_TIME := 0.3
const TAP_DIST := 26.0

var cam: Camera3D
var pitch_node: Node3D

var yaw: float = 0.6
var pitch: float = -0.95
var dist: float = 9.0
var target: Vector3 = Vector3.ZERO

var _yaw_goal: float = 0.6
var _pitch_goal: float = -0.95
var _dist_goal: float = 9.0
var _target_goal: Vector3 = Vector3.ZERO

var bounds_radius: float = 6.0
var min_dist: float = 3.0
var max_dist: float = 16.0

var _touches: Dictionary = {}
var _tap_start_pos: Vector2 = Vector2.ZERO
var _tap_start_time: float = 0.0
var _tap_moved: float = 0.0
var _multi_touch: bool = false
var _locked: bool = false
var _focus_tween: Tween


func _ready() -> void:
	pitch_node = Node3D.new()
	add_child(pitch_node)
	cam = Camera3D.new()
	cam.fov = 60.0
	pitch_node.add_child(cam)
	_apply_now()


func setup(radius: float) -> void:
	bounds_radius = radius * 0.6
	max_dist = radius * 3.2
	min_dist = 2.5
	_dist_goal = radius * 2.1
	dist = _dist_goal
	_target_goal = Vector3(0, 0.6, 0)
	target = _target_goal
	_apply_now()


func _apply_now() -> void:
	position = target
	rotation.y = yaw
	pitch_node.rotation.x = pitch
	cam.position = Vector3(0, 0, dist)


func _process(delta: float) -> void:
	var w := clampf(delta * 10.0, 0.0, 1.0)
	yaw = lerp_angle(yaw, _yaw_goal, w)
	pitch = lerpf(pitch, _pitch_goal, w)
	dist = lerpf(dist, _dist_goal, w)
	target = target.lerp(_target_goal, w)
	_apply_now()


func set_locked(v: bool) -> void:
	_locked = v
	if v:
		_touches.clear()


func handle_input(event: InputEvent) -> void:
	if _locked:
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_touches[st.index] = st.position
			if _touches.size() == 1:
				_tap_start_pos = st.position
				_tap_start_time = Time.get_ticks_msec() / 1000.0
				_tap_moved = 0.0
				_multi_touch = false
			else:
				_multi_touch = true
		else:
			if _touches.size() == 1 and not _multi_touch:
				var dt := Time.get_ticks_msec() / 1000.0 - _tap_start_time
				if dt < TAP_TIME and _tap_moved < TAP_DIST:
					tapped.emit(st.position)
			_touches.erase(st.index)
	elif event is InputEventScreenDrag:
		var dg := event as InputEventScreenDrag
		var prev: Vector2 = _touches.get(dg.index, dg.position)
		if _touches.size() == 1:
			_touches[dg.index] = dg.position
			_tap_moved += dg.relative.length()
			if _tap_moved > TAP_DIST:
				_yaw_goal -= dg.relative.x * 0.0065
				_pitch_goal = clampf(_pitch_goal - dg.relative.y * 0.005, -1.35, -0.35)
				orbited.emit()
		elif _touches.size() >= 2:
			var other_idx := -1
			for k: int in _touches.keys():
				if k != dg.index:
					other_idx = k
					break
			if other_idx >= 0:
				var other: Vector2 = _touches[other_idx]
				var d_prev := prev.distance_to(other)
				var d_new := dg.position.distance_to(other)
				if d_prev > 1.0:
					var ratio := d_prev / maxf(d_new, 1.0)
					_dist_goal = clampf(_dist_goal * lerpf(1.0, ratio, 0.9), min_dist, max_dist)
					zoomed.emit()
				# two-finger pan
				var pan := dg.relative * 0.5
				_pan(pan)
			_touches[dg.index] = dg.position
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_dist_goal = clampf(_dist_goal * 0.9, min_dist, max_dist)
				zoomed.emit()
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_dist_goal = clampf(_dist_goal * 1.12, min_dist, max_dist)
				zoomed.emit()


func _pan(screen_delta: Vector2) -> void:
	var fwd := -global_transform.basis.z
	fwd.y = 0
	fwd = fwd.normalized()
	var right := global_transform.basis.x
	right.y = 0
	right = right.normalized()
	var world_delta := (-right * screen_delta.x + fwd * screen_delta.y) * dist * 0.0016
	_target_goal += world_delta
	var flat := Vector2(_target_goal.x, _target_goal.z)
	if flat.length() > bounds_radius:
		flat = flat.normalized() * bounds_radius
	_target_goal = Vector3(flat.x, _target_goal.y, flat.y)


func focus_on(world_pos: Vector3, zoom_dist: float, duration: float = 1.0) -> void:
	set_locked(true)
	if _focus_tween and _focus_tween.is_running():
		_focus_tween.kill()
	_focus_tween = create_tween().set_parallel(true)
	_focus_tween.tween_property(self, "_target_goal", world_pos, duration).set_trans(Tween.TRANS_SINE)
	_focus_tween.tween_property(self, "_dist_goal", zoom_dist, duration).set_trans(Tween.TRANS_SINE)
	_focus_tween.tween_property(self, "_pitch_goal", -0.7, duration).set_trans(Tween.TRANS_SINE)


func set_magnify(enabled: bool) -> void:
	var tw := create_tween()
	tw.tween_property(cam, "fov", 38.0 if enabled else 60.0, 0.35).set_trans(Tween.TRANS_SINE)
	if enabled:
		min_dist = 1.4
	else:
		min_dist = 2.5
		_dist_goal = maxf(_dist_goal, 4.0)


func ray_origin(screen_pos: Vector2) -> Vector3:
	return cam.project_ray_origin(screen_pos)


func ray_dir(screen_pos: Vector2) -> Vector3:
	return cam.project_ray_normal(screen_pos)
