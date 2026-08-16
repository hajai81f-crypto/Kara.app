extends Node
## DifficultyManager.gd
## Implements the Adaptive Difficulty System (design doc section 4).
## Tracks a rolling performance window and exposes a single 0.0-2.0
## difficulty multiplier that StageGenerator uses to scale everything
## from target count to spawn speed.

const HISTORY_SIZE := 8
const MIN_DIFFICULTY := 0.4
const MAX_DIFFICULTY := 2.0
const BASE_DIFFICULTY := 1.0

var _history: Array[Dictionary] = []
var _current_difficulty: float = BASE_DIFFICULTY

func record_stage_result(result: Dictionary) -> void:
	_history.append({
		"accuracy": result.get("accuracy", 0.0),
		"won": result.get("won", false),
		"arrows_used": result.get("arrows_used", 0),
		"time_taken": result.get("time_taken", 0.0),
		"time_limit": result.get("time_limit", 1.0),
		"errors": result.get("errors", 0),
	})
	if _history.size() > HISTORY_SIZE:
		_history.pop_front()
	_recalculate_difficulty()

func _recalculate_difficulty() -> void:
	if _history.is_empty():
		_current_difficulty = BASE_DIFFICULTY
		return

	var total_score := 0.0
	for entry in _history:
		var accuracy: float = entry.accuracy
		var win_bonus: float = 1.0 if entry.won else -0.5
		var time_ratio: float = 1.0
		if entry.time_limit > 0.0:
			time_ratio = clamp(1.0 - (entry.time_taken / entry.time_limit), -0.5, 0.5)
		var error_penalty: float = clamp(entry.errors * -0.05, -0.5, 0.0)

		# Weighted skill score for this stage, roughly in range [-1, 2].
		var stage_score := (accuracy * 1.2) + win_bonus + time_ratio + error_penalty
		total_score += stage_score

	var average_score := total_score / _history.size()

	# Map average performance score onto the difficulty multiplier smoothly,
	# so difficulty never jumps abruptly between stages (no "cheating" feel).
	var target_difficulty: float = clamp(BASE_DIFFICULTY + (average_score * 0.4), MIN_DIFFICULTY, MAX_DIFFICULTY)
	_current_difficulty = lerp(_current_difficulty, target_difficulty, 0.35)

func get_current_difficulty() -> float:
	return _current_difficulty

func get_performance_summary() -> Dictionary:
	if _history.is_empty():
		return {"average_accuracy": 0.0, "win_rate": 0.0, "sample_size": 0}
	var accuracy_sum := 0.0
	var wins := 0
	for entry in _history:
		accuracy_sum += entry.accuracy
		if entry.won:
			wins += 1
	return {
		"average_accuracy": accuracy_sum / _history.size(),
		"win_rate": float(wins) / _history.size(),
		"sample_size": _history.size(),
	}
