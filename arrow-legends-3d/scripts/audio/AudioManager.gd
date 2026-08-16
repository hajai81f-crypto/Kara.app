extends Node
## AudioManager.gd
## Central audio hub. Owns a pool of AudioStreamPlayer nodes for SFX so we
## never instantiate/free players at runtime (Object Pooling requirement,
## section 24), plus dedicated players for music and ambient loops.

const SFX_POOL_SIZE := 12

var _sfx_pool: Array[AudioStreamPlayer] = []
var _next_sfx_index := 0
var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer

var _sfx_library: Dictionary = {}   # String id -> AudioStream
var _music_library: Dictionary = {} # String id -> AudioStream

func _ready() -> void:
	_setup_buses()
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	add_child(_music_player)

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "AmbientPlayer"
	_ambient_player.bus = "Ambient"
	add_child(_ambient_player)

	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.name = "SFXPlayer%d" % i
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)

	_apply_saved_volumes()
	EventBus.settings_changed.connect(_on_settings_changed)

func _setup_buses() -> void:
	# Buses are also defined in the audio bus layout resource; this is a
	# runtime safety net in case that resource is missing (e.g. fresh clone).
	var bus_names := ["Master", "Music", "SFX", "UI", "Ambient"]
	for bus_name in bus_names:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			if bus_name != "Master":
				AudioServer.set_bus_send(idx, "Master")

func register_sfx(id: String, stream: AudioStream) -> void:
	_sfx_library[id] = stream

func register_music(id: String, stream: AudioStream) -> void:
	_music_library[id] = stream

func play_sfx(id: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not _sfx_library.has(id):
		push_warning("AudioManager: unknown SFX id '%s'" % id)
		return
	var player: AudioStreamPlayer = _sfx_pool[_next_sfx_index]
	_next_sfx_index = (_next_sfx_index + 1) % _sfx_pool.size()
	player.stream = _sfx_library[id]
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()

func play_music(id: String, fade_seconds: float = 0.5) -> void:
	if not _music_library.has(id):
		push_warning("AudioManager: unknown music id '%s'" % id)
		return
	if _music_player.stream == _music_library[id] and _music_player.playing:
		return
	var tween := create_tween()
	if _music_player.playing:
		tween.tween_property(_music_player, "volume_db", -40.0, fade_seconds)
		tween.tween_callback(func():
			_music_player.stream = _music_library[id]
			_music_player.volume_db = 0.0
			_music_player.play()
		)
	else:
		_music_player.stream = _music_library[id]
		_music_player.play()

func stop_music() -> void:
	_music_player.stop()

func set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clamp(linear_volume, 0.0, 1.0)))

func _apply_saved_volumes() -> void:
	var settings := SaveManager.get_settings()
	set_bus_volume("Music", settings.get("music_volume", 0.8))
	set_bus_volume("SFX", settings.get("sfx_volume", 1.0))
	set_bus_volume("UI", settings.get("sfx_volume", 1.0))

func _on_settings_changed(settings: Dictionary) -> void:
	set_bus_volume("Music", settings.get("music_volume", 0.8))
	set_bus_volume("SFX", settings.get("sfx_volume", 1.0))
	set_bus_volume("UI", settings.get("sfx_volume", 1.0))
