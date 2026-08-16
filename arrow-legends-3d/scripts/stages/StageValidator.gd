extends Node
## StageValidator.gd
## Gatekeeper for procedurally generated stages (design doc section 13).
## Runs a series of sanity checks; if any fail, GameManager regenerates
## the stage with a new seed rather than letting a broken stage load.

class ValidationResult:
	var is_valid: bool = true
	var reason: String = ""

func validate(config: StageConfig) -> ValidationResult:
	var result := ValidationResult.new()

	var check := _check_targets_reachable(config)
	if not check.is_valid:
		return check

	check = _check_spawn_not_in_walls(config)
	if not check.is_valid:
		return check

	check = _check_targets_within_arena(config)
	if not check.is_valid:
		return check

	check = _check_time_is_reasonable(config)
	if not check.is_valid:
		return check

	check = _check_reward_balance(config)
	if not check.is_valid:
		return check

	check = _check_difficulty_balance(config)
	if not check.is_valid:
		return check

	return result

func _fail(reason: String) -> ValidationResult:
	var r := ValidationResult.new()
	r.is_valid = false
	r.reason = reason
	return r

func _check_targets_reachable(config: StageConfig) -> ValidationResult:
	if config.target_positions.is_empty():
		return _fail("Stage has no targets.")
	for pos in config.target_positions:
		var distance := config.player_spawn_point.distance_to(pos)
		if distance < 2.0:
			return _fail("Target placed too close to player spawn (%.1fm)." % distance)
		if distance > config.arena_radius * 1.5:
			return _fail("Target unreachable: %.1fm exceeds arena bounds." % distance)
	return ValidationResult.new()

func _check_spawn_not_in_walls(config: StageConfig) -> ValidationResult:
	for obstacle_pos in config.obstacle_positions:
		if obstacle_pos.distance_to(config.player_spawn_point) < 1.5:
			return _fail("Obstacle overlaps player spawn point.")
	return ValidationResult.new()

func _check_targets_within_arena(config: StageConfig) -> ValidationResult:
	for pos in config.target_positions:
		var horizontal_distance := Vector2(pos.x, pos.z).length()
		if horizontal_distance > config.arena_radius * 1.2:
			return _fail("Target lies outside arena radius bounds.")
		if pos.y < 0.0 or pos.y > 20.0:
			return _fail("Target height out of valid range (%.1f)." % pos.y)
	return ValidationResult.new()

func _check_time_is_reasonable(config: StageConfig) -> ValidationResult:
	if config.time_limit_seconds < 15.0:
		return _fail("Time limit too short to be playable (%.1fs)." % config.time_limit_seconds)
	if config.time_limit_seconds > 400.0:
		return _fail("Time limit unreasonably long (%.1fs)." % config.time_limit_seconds)
	var min_time_needed := config.target_count * 2.0
	if config.time_limit_seconds < min_time_needed:
		return _fail("Not enough time to realistically hit all targets.")
	return ValidationResult.new()

func _check_reward_balance(config: StageConfig) -> ValidationResult:
	if config.coin_reward <= 0:
		return _fail("Coin reward is zero or negative.")
	if config.coin_reward > 5000:
		return _fail("Coin reward unreasonably high, breaks economy balance.")
	return ValidationResult.new()

func _check_difficulty_balance(config: StageConfig) -> ValidationResult:
	if config.arrow_count < config.target_count:
		return _fail("Not enough arrows (%d) to hit all targets (%d)." % [config.arrow_count, config.target_count])
	if config.enemy_count > 15:
		return _fail("Enemy count exceeds sane upper bound.")
	if config.wind_strength > Constants.MAX_WIND_FORCE * 1.5:
		return _fail("Wind strength exceeds maximum allowed force.")
	return ValidationResult.new()
