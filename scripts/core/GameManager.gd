extends Node
## GameManager.gd
## Drives the main game loop:
## BOOT -> LOAD SAVE -> MAIN MENU -> GENERATE STAGE -> VALIDATE STAGE
## -> PLAY -> CALCULATE SCORE -> REWARDS -> SAVE -> GENERATE NEXT STAGE
##
## This is intentionally a thin orchestrator: it does not know HOW a stage is
## generated or validated, it only calls the relevant managers and reacts to
## EventBus signals. This keeps it testable and swappable.

var current_state: int = Constants.GameState.BOOT
var current_stage_number: int = 1
var current_stage_config: Resource = null
var current_run_seed: int = 0

var _state_scene_paths := {
	Constants.GameState.MAIN_MENU: "res://scenes/ui/MainMenu.tscn",
}

func _ready() -> void:
	EventBus.stage_generation_finished.connect(_on_stage_generation_finished)
	EventBus.stage_completed.connect(_on_stage_completed)
	EventBus.stage_failed.connect(_on_stage_failed)
	_change_state(Constants.GameState.BOOT)
	call_deferred("_boot_sequence")

func _boot_sequence() -> void:
	_change_state(Constants.GameState.LOADING)
	SaveManager.load_game()
	_change_state(Constants.GameState.MAIN_MENU)

func _change_state(new_state: int) -> void:
	var old_state := current_state
	current_state = new_state
	EventBus.game_state_changed.emit(new_state, old_state)
	if _state_scene_paths.has(new_state):
		call_deferred("_load_scene", _state_scene_paths[new_state])

func _load_scene(path: String) -> void:
	if ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
	else:
		push_warning("GameManager: scene not found yet: %s (later phase will add it)" % path)

## Called by MainMenu "PLAY" button.
func start_next_stage() -> void:
	_change_state(Constants.GameState.STAGE_GENERATING)
	current_run_seed = int(Time.get_unix_time_from_system() * 1000) % 2147483647
	EventBus.stage_generation_started.emit(current_stage_number)
	var config: Resource = StageGenerator.generate_stage(
		current_stage_number,
		DifficultyManager.get_current_difficulty(),
		current_run_seed
	)
	EventBus.stage_generation_finished.emit(config)

func _on_stage_generation_finished(config: Resource) -> void:
	current_stage_config = config
	_change_state(Constants.GameState.STAGE_VALIDATING)
	var validation := StageValidator.validate(config)
	if validation.is_valid:
		_change_state(Constants.GameState.PLAYING)
		EventBus.stage_ready.emit(config)
	else:
		EventBus.stage_validation_failed.emit(validation.reason)
		_regenerate_with_new_seed()

var _regeneration_attempts := 0
const MAX_REGENERATION_ATTEMPTS := 8

func _regenerate_with_new_seed() -> void:
	_regeneration_attempts += 1
	if _regeneration_attempts > MAX_REGENERATION_ATTEMPTS:
		push_error("StageGenerator failed to produce a valid stage after %d attempts" % MAX_REGENERATION_ATTEMPTS)
		_regeneration_attempts = 0
		_change_state(Constants.GameState.MAIN_MENU)
		return
	current_run_seed += 1
	var config: Resource = StageGenerator.generate_stage(
		current_stage_number,
		DifficultyManager.get_current_difficulty(),
		current_run_seed
	)
	EventBus.stage_generation_finished.emit(config)

func _on_stage_completed(result: Dictionary) -> void:
	_regeneration_attempts = 0
	_change_state(Constants.GameState.STAGE_RESULT)
	DifficultyManager.record_stage_result(result)
	EconomyManager.grant_stage_rewards(result)
	var stars := _calculate_stars(result)
	EventBus.stars_awarded.emit(current_stage_number, stars)
	SaveManager.record_stage_completion(current_stage_number, result.get("score", 0), stars)
	SaveManager.save_game()
	current_stage_number += 1

func _on_stage_failed(_reason: String) -> void:
	_regeneration_attempts = 0
	_change_state(Constants.GameState.STAGE_RESULT)
	SaveManager.save_game()

func _calculate_stars(result: Dictionary) -> int:
	var accuracy: float = result.get("accuracy", 0.0)
	var perfect_shots: int = result.get("perfect_shots", 0)
	var stars := 1
	if accuracy >= 0.6:
		stars = 2
	if accuracy >= 0.85 and perfect_shots >= 3:
		stars = 3
	return stars

func return_to_main_menu() -> void:
	_change_state(Constants.GameState.MAIN_MENU)

func pause_game() -> void:
	if current_state == Constants.GameState.PLAYING:
		get_tree().paused = true
		_change_state(Constants.GameState.PAUSED)

func resume_game() -> void:
	if current_state == Constants.GameState.PAUSED:
		get_tree().paused = false
		_change_state(Constants.GameState.PLAYING)
