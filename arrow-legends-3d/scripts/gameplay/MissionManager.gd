extends Node
## MissionManager.gd
## Generates a fresh set of Daily Missions (design doc section 16) once per
## calendar day and tracks progress against the current save data.

const MISSIONS_PER_DAY := 3

var _templates := [
	{"id": "hit_targets", "text": "Hit %d targets", "min": 15, "max": 30, "stat": "targets_hit"},
	{"id": "perfect_shots", "text": "Get %d Perfect Shots", "min": 5, "max": 12, "stat": "perfect_shots"},
	{"id": "win_stages", "text": "Win %d stages", "min": 2, "max": 4, "stat": "stages_won"},
	{"id": "combo", "text": "Reach Combo x%d", "min": 8, "max": 15, "stat": "max_combo_reached"},
	{"id": "defeat_boss", "text": "Defeat %d Boss", "min": 1, "max": 1, "stat": "bosses_defeated"},
]

func _ready() -> void:
	EventBus.load_completed.connect(_ensure_daily_missions)

func _ensure_daily_missions() -> void:
	var today := Time.get_date_string_from_system()
	var mission_data: Dictionary = SaveManager.data.get("daily_missions", {})
	if mission_data.get("date", "") != today:
		_generate_new_missions(today)

func _generate_new_missions(today: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = today.hash()
	var pool := _templates.duplicate(true)
	_seeded_shuffle(pool, rng)

	var missions := []
	for i in range(min(MISSIONS_PER_DAY, pool.size())):
		var template = pool[i]
		var target_value := rng.randi_range(template.min, template.max)
		missions.append({
			"id": template.id,
			"description": template.text % target_value,
			"target": target_value,
			"progress": 0,
			"stat": template.stat,
			"completed": false,
		})

	SaveManager.data["daily_missions"] = {"date": today, "missions": missions}
	SaveManager.save_game()

func _seeded_shuffle(array: Array, rng: RandomNumberGenerator) -> void:
	# Fisher-Yates shuffle driven by our own seeded RNG so results are
	# reproducible per calendar day instead of relying on global RNG state.
	for i in range(array.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = array[i]
		array[i] = array[j]
		array[j] = tmp

func report_stat(stat_name: String, amount: int = 1) -> void:
	var mission_data: Dictionary = SaveManager.data.get("daily_missions", {})
	var missions: Array = mission_data.get("missions", [])
	var changed := false
	for mission in missions:
		if mission.stat == stat_name and not mission.completed:
			mission.progress = min(int(mission.progress) + amount, int(mission.target))
			changed = true
			if mission.progress >= mission.target:
				mission.completed = true
				EventBus.mission_completed.emit(mission.id)
	if changed:
		SaveManager.data["daily_missions"]["missions"] = missions

func get_active_missions() -> Array:
	return SaveManager.data.get("daily_missions", {}).get("missions", [])
