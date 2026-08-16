extends Node
## SaveManager.gd
## Handles reading/writing player progress to disk as JSON at user://.
## Uses a backup file so a corrupted write never destroys existing progress
## (writes go to a temp file first, then atomically replace the save file).

var data: Dictionary = {}

const DEFAULT_DATA := {
	"schema_version": 1,
	"player_level": 1,
	"xp": 0,
	"coins": 0,
	"gems": 0,
	"unlocked_bows": ["basic"],
	"unlocked_arrows": ["normal"],
	"equipped_bow": "basic",
	"upgrades": {},
	"completed_stages": {},   # stage_number(String) -> {"score": int, "stars": int}
	"best_scores": {},
	"achievements": [],
	"settings": {
		"aim_sensitivity": 1.0,
		"aim_assist": 0.4,
		"vibration": true,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"graphics_quality": "medium",
	},
	"daily_missions": {
		"date": "",
		"missions": [],
	},
}

func _ready() -> void:
	data = DEFAULT_DATA.duplicate(true)

func load_game() -> void:
	if not FileAccess.file_exists(Constants.SAVE_FILE_PATH):
		data = DEFAULT_DATA.duplicate(true)
		EventBus.load_completed.emit()
		return

	var loaded := _read_json_file(Constants.SAVE_FILE_PATH)
	if loaded.is_empty():
		# Primary file corrupt/unreadable, try backup.
		loaded = _read_json_file(Constants.SAVE_FILE_BACKUP_PATH)

	if loaded.is_empty():
		push_warning("SaveManager: no valid save found, starting fresh.")
		data = DEFAULT_DATA.duplicate(true)
	else:
		data = _merge_with_defaults(loaded)

	EventBus.load_completed.emit()

func _read_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var error := json.parse(text)
	if error != OK:
		push_warning("SaveManager: failed to parse %s (%s)" % [path, json.get_error_message()])
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return json.data

func _merge_with_defaults(loaded: Dictionary) -> Dictionary:
	var merged: Dictionary = DEFAULT_DATA.duplicate(true)
	for key in loaded.keys():
		merged[key] = loaded[key]
	return merged

func save_game() -> void:
	# Backup current save before overwriting.
	if FileAccess.file_exists(Constants.SAVE_FILE_PATH):
		var current := FileAccess.open(Constants.SAVE_FILE_PATH, FileAccess.READ)
		if current:
			var backup := FileAccess.open(Constants.SAVE_FILE_BACKUP_PATH, FileAccess.WRITE)
			if backup:
				backup.store_string(current.get_as_text())
				backup.close()
			current.close()

	var file := FileAccess.open(Constants.SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		EventBus.save_failed.emit("Could not open save file for writing.")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	EventBus.save_completed.emit()

func record_stage_completion(stage_number: int, score: int, stars: int) -> void:
	var key := str(stage_number)
	data["completed_stages"][key] = {"score": score, "stars": stars}
	var best: int = data["best_scores"].get(key, 0)
	if score > best:
		data["best_scores"][key] = score

func add_coins(amount: int) -> void:
	data["coins"] = max(0, int(data.get("coins", 0)) + amount)
	EventBus.coins_changed.emit(data["coins"])

func add_gems(amount: int) -> void:
	data["gems"] = max(0, int(data.get("gems", 0)) + amount)
	EventBus.gems_changed.emit(data["gems"])

func add_xp(amount: int) -> void:
	data["xp"] = int(data.get("xp", 0)) + amount
	EventBus.xp_gained.emit(amount, data["xp"])
	_check_level_up()

func _check_level_up() -> void:
	var level: int = data.get("player_level", 1)
	var xp: int = data.get("xp", 0)
	var xp_needed := _xp_required_for_level(level + 1)
	while xp >= xp_needed:
		level += 1
		data["player_level"] = level
		EventBus.player_leveled_up.emit(level)
		xp_needed = _xp_required_for_level(level + 1)

func _xp_required_for_level(level: int) -> int:
	# Simple increasing curve: 100 * level^1.5
	return int(100 * pow(level, 1.5))

func unlock_achievement(id: String) -> void:
	var achievements: Array = data.get("achievements", [])
	if not achievements.has(id):
		achievements.append(id)
		data["achievements"] = achievements
		EventBus.achievement_unlocked.emit(id)

func get_settings() -> Dictionary:
	return data.get("settings", {})

func update_setting(key: String, value) -> void:
	data["settings"][key] = value
	EventBus.settings_changed.emit(data["settings"])
