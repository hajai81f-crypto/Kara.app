extends Node
## AchievementManager.gd
## Tracks cumulative lifetime stats and unlocks achievements (section 17)
## the first time a threshold is crossed. Stats persist in SaveManager.data
## under "lifetime_stats" so they survive across sessions.

var _definitions := [
	{"id": "first_blood", "name": "First Blood", "stat": "targets_hit", "threshold": 1},
	{"id": "perfect_archer", "name": "Perfect Archer", "stat": "perfect_shots", "threshold": 25},
	{"id": "long_shot", "name": "Long Shot", "stat": "long_shots", "threshold": 1},
	{"id": "combo_master", "name": "Combo Master", "stat": "max_combo_reached", "threshold": 25},
	{"id": "boss_slayer", "name": "Boss Slayer", "stat": "bosses_defeated", "threshold": 1},
	{"id": "hundred_targets", "name": "100 Targets", "stat": "targets_hit", "threshold": 100},
	{"id": "thousand_targets", "name": "1000 Targets", "stat": "targets_hit", "threshold": 1000},
	{"id": "legendary_archer", "name": "Legendary Archer", "stat": "stages_won", "threshold": 100},
]

func _ensure_lifetime_stats() -> Dictionary:
	if not SaveManager.data.has("lifetime_stats"):
		SaveManager.data["lifetime_stats"] = {}
	return SaveManager.data["lifetime_stats"]

func report_stat(stat_name: String, amount: int = 1) -> void:
	var stats := _ensure_lifetime_stats()
	stats[stat_name] = int(stats.get(stat_name, 0)) + amount
	MissionManager.report_stat(stat_name, amount)
	_check_achievements(stat_name, stats[stat_name])

func report_stat_max(stat_name: String, value: int) -> void:
	# For "reach a peak value" style stats like max combo, keep the highest.
	var stats := _ensure_lifetime_stats()
	var current: int = int(stats.get(stat_name, 0))
	if value > current:
		stats[stat_name] = value
		MissionManager.report_stat(stat_name, value - current)
		_check_achievements(stat_name, value)

func _check_achievements(stat_name: String, current_value: int) -> void:
	var unlocked: Array = SaveManager.data.get("achievements", [])
	for definition in _definitions:
		if definition.stat == stat_name and not unlocked.has(definition.id):
			if current_value >= definition.threshold:
				SaveManager.unlock_achievement(definition.id)

func get_all_definitions() -> Array:
	return _definitions

func is_unlocked(id: String) -> bool:
	var unlocked: Array = SaveManager.data.get("achievements", [])
	return unlocked.has(id)
