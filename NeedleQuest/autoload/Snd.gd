extends Node
## Audio manager: pooled SFX players + music with manual looping.
## All sounds are original, procedurally generated WAV files.

const SFX_DIR := "res://audio/"
const POOL_SIZE := 10

var music_volume: float = 0.8
var sfx_volume: float = 1.0

var _pool: Array[AudioStreamPlayer] = []
var _pool_idx: int = 0
var _music: AudioStreamPlayer
var _music_name: String = ""
var _cache: Dictionary = {}


func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	_music.finished.connect(_on_music_finished)


func _get_stream(name_: String) -> AudioStream:
	if _cache.has(name_):
		return _cache[name_]
	var path := SFX_DIR + name_ + ".wav"
	if ResourceLoader.exists(path):
		var s: AudioStream = load(path)
		_cache[name_] = s
		return s
	return null


func play(name_: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if sfx_volume <= 0.001:
		return
	var s := _get_stream(name_)
	if s == null:
		return
	var p := _pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % POOL_SIZE
	p.stream = s
	p.volume_db = volume_db + linear_to_db(clampf(sfx_volume, 0.001, 1.0))
	p.pitch_scale = pitch
	p.play()


func play_var(name_: String, volume_db: float = 0.0) -> void:
	# Play with slight random pitch variation (natural feel).
	play(name_, volume_db, randf_range(0.9, 1.12))


func rustle() -> void:
	var n := ["rustle1", "rustle2", "rustle3"][randi() % 3]
	play(n, -4.0, randf_range(0.85, 1.2))


func play_music(name_: String) -> void:
	if _music_name == name_ and _music.playing:
		return
	_music_name = name_
	var s := _get_stream(name_)
	if s == null:
		return
	_music.stream = s
	_music.volume_db = _music_db()
	if music_volume > 0.001:
		_music.play()


func stop_music() -> void:
	_music_name = ""
	_music.stop()


func _on_music_finished() -> void:
	# Manual seamless-ish loop.
	if _music_name != "" and music_volume > 0.001:
		_music.play()


func _music_db() -> float:
	if music_volume <= 0.001:
		return -80.0
	return linear_to_db(clampf(music_volume, 0.001, 1.0)) - 6.0


func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_music.volume_db = _music_db()
	if music_volume <= 0.001:
		_music.stop()
	elif not _music.playing and _music_name != "":
		_music.play()


func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)


func vibrate(ms: int = 30) -> void:
	if G.settings().get("vibration", true):
		Input.vibrate_handheld(ms)
