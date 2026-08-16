extends CanvasLayer
## DebugTools.gd
## Developer debug overlay (design doc section 29). Disabled by default in
## release builds via the `is_debug_build` check; toggled with F3 in editor
## or a 5-tap corner gesture on device (see MainMenu for the tap hook).

var enabled: bool = false
var _label: Label

func _ready() -> void:
	layer = 100
	visible = false
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(0, 1, 0.2))
	_label.position = Vector2(12, 12)
	add_child(_label)
	set_process(false)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		toggle()

func toggle() -> void:
	enabled = not enabled
	visible = enabled
	set_process(enabled)

func _process(_delta: float) -> void:
	var config: StageConfig = GameManager.current_stage_config
	var lines := [
		"FPS: %d" % Engine.get_frames_per_second(),
		"State: %s" % _state_name(GameManager.current_state),
		"Stage: %d" % GameManager.current_stage_number,
	]
	if config:
		lines.append("Seed: %d" % config.seed_value)
		lines.append("Stage Type: %s" % config.get_stage_type_name())
		lines.append("Environment: %s" % config.get_environment_name())
		lines.append("Difficulty: %.2f" % config.difficulty)
		lines.append("Targets: %d" % config.target_count)
		lines.append("Enemies: %d" % config.enemy_count)
	lines.append("Static Memory: %.2f MB" % (OS.get_static_memory_usage() / 1048576.0))
	_label.text = "\n".join(lines)

func _state_name(state: int) -> String:
	for key in Constants.GameState.keys():
		if Constants.GameState[key] == state:
			return key
	return "UNKNOWN"
