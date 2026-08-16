extends Node
## StageGenerator.gd
## The Dynamic Stage Generation System (design doc sections 3, 12, 13, 34).
##
## This is CONTROLLED procedural generation: every value is drawn from a
## seeded RandomNumberGenerator, but always clamped through rules derived
## from stage_number, difficulty and stage_type so results stay playable.
## StageValidator double-checks the output before it reaches gameplay.

const RNG := RandomNumberGenerator

func generate_stage(stage_number: int, difficulty: float, seed_value: int) -> StageConfig:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var config := StageConfig.new()
	config.stage_number = stage_number
	config.seed_value = seed_value
	config.difficulty = difficulty

	config.stage_type = _pick_stage_type(stage_number, rng)
	config.environment = _pick_environment(stage_number, rng)
	config.weather = _pick_weather(config.environment, rng)

	config.is_boss_stage = config.stage_type == Constants.StageType.BOSS_ARCHERY
	if config.is_boss_stage:
		config.boss_id = _pick_boss_id(stage_number, rng)

	_configure_targets(config, rng)
	_configure_arena(config, rng)
	_configure_wind_and_physics(config, rng)
	_configure_enemies(config, rng)
	_configure_resources(config, rng)
	_configure_audio(config)

	return config

# --- Selection helpers -----------------------------------------------------

func _pick_stage_type(stage_number: int, rng: RandomNumberGenerator) -> int:
	# Guarantee a gentle tutorial ramp: no boss/survival before stage 6,
	# per the Progression curve (section 35).
	var available: Array[int] = [Constants.StageType.TARGET_RANGE]
	if stage_number >= 3:
		available.append(Constants.StageType.MOVING_TARGET)
	if stage_number >= 5:
		available.append(Constants.StageType.TIME_ATTACK)
	if stage_number >= 6:
		available.append(Constants.StageType.SPEED_ARCHER)
		available.append(Constants.StageType.PERFECT_SHOT)
	if stage_number >= 8:
		available.append(Constants.StageType.WIND_MASTER)
		available.append(Constants.StageType.LONG_DISTANCE)
	if stage_number >= 10:
		available.append(Constants.StageType.TRICK_SHOT)
		available.append(Constants.StageType.DEFENSE)
	if stage_number >= 12:
		available.append(Constants.StageType.SURVIVAL)
	if stage_number > 0 and stage_number % 10 == 0:
		return Constants.StageType.BOSS_ARCHERY
	return available[rng.randi_range(0, available.size() - 1)]

func _pick_environment(stage_number: int, rng: RandomNumberGenerator) -> int:
	var unlocked_count: int = clampi(1 + stage_number / 8, 1, Constants.EnvironmentType.size())
	return rng.randi_range(0, unlocked_count - 1)

func _pick_weather(environment: int, rng: RandomNumberGenerator) -> int:
	match environment:
		Constants.EnvironmentType.SNOW_MOUNTAIN:
			return [Constants.WeatherType.SNOW, Constants.WeatherType.CLEAR, Constants.WeatherType.FOG][rng.randi_range(0, 2)]
		Constants.EnvironmentType.DESERT:
			return [Constants.WeatherType.CLEAR, Constants.WeatherType.WINDY][rng.randi_range(0, 1)]
		Constants.EnvironmentType.VOLCANO:
			return [Constants.WeatherType.CLEAR, Constants.WeatherType.FOG][rng.randi_range(0, 1)]
		Constants.EnvironmentType.DARK_VALLEY:
			return [Constants.WeatherType.FOG, Constants.WeatherType.STORM, Constants.WeatherType.CLEAR][rng.randi_range(0, 2)]
		_:
			return [Constants.WeatherType.CLEAR, Constants.WeatherType.WINDY, Constants.WeatherType.RAIN][rng.randi_range(0, 2)]

func _pick_boss_id(stage_number: int, rng: RandomNumberGenerator) -> String:
	var boss_pool := ["ancient_guardian", "storm_wraith", "forest_titan", "shadow_warlord"]
	var index := (stage_number / 10 - 1) % boss_pool.size()
	return boss_pool[index]

# --- Configuration passes ---------------------------------------------------

func _configure_targets(config: StageConfig, rng: RandomNumberGenerator) -> void:
	var base_count := 5 + int(config.stage_number * 0.3)
	var count := clampi(int(base_count * lerp(0.7, 1.6, clamp(config.difficulty / 2.0, 0.0, 1.0))), 3, 24)
	config.target_count = count

	var arena_radius: float = clamp(15.0 + config.stage_number * 0.4, 15.0, 45.0)
	config.arena_radius = arena_radius

	for i in range(count):
		var angle := rng.randf_range(0.0, TAU)
		var distance := rng.randf_range(arena_radius * 0.3, arena_radius * 0.95)
		var height := rng.randf_range(1.0, 6.0)
		var pos := Vector3(cos(angle) * distance, height, sin(angle) * distance)
		config.target_positions.append(pos)

		var is_moving := config.stage_type in [
			Constants.StageType.MOVING_TARGET,
			Constants.StageType.SPEED_ARCHER,
			Constants.StageType.SURVIVAL,
		]
		if is_moving:
			var speed := rng.randf_range(1.5, 3.0) * clamp(config.difficulty, 0.5, 2.0)
			if config.stage_type == Constants.StageType.SPEED_ARCHER:
				speed *= 1.5
			config.target_speeds.append(speed)
			var dir := Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)).normalized()
			config.target_move_directions.append(dir)
		else:
			config.target_speeds.append(0.0)
			config.target_move_directions.append(Vector3.ZERO)

func _configure_arena(config: StageConfig, rng: RandomNumberGenerator) -> void:
	config.player_spawn_point = Vector3.ZERO

	var obstacle_count := 0
	if config.stage_type in [Constants.StageType.TRICK_SHOT, Constants.StageType.DEFENSE]:
		obstacle_count = rng.randi_range(3, 7)
	elif config.stage_number > 15:
		obstacle_count = rng.randi_range(0, 3)

	for i in range(obstacle_count):
		var angle := rng.randf_range(0.0, TAU)
		var distance := rng.randf_range(config.arena_radius * 0.2, config.arena_radius * 0.7)
		config.obstacle_positions.append(Vector3(cos(angle) * distance, 0.0, sin(angle) * distance))

func _configure_wind_and_physics(config: StageConfig, rng: RandomNumberGenerator) -> void:
	config.gravity_scale = 1.0
	if config.stage_type == Constants.StageType.WIND_MASTER or config.weather in [Constants.WeatherType.WINDY, Constants.WeatherType.STORM]:
		var angle := rng.randf_range(0.0, TAU)
		config.wind_direction = Vector3(cos(angle), 0.0, sin(angle))
		var strength_scale := 1.0 if config.stage_type != Constants.StageType.WIND_MASTER else 1.6
		config.wind_strength = rng.randf_range(1.0, Constants.MAX_WIND_FORCE) * clamp(config.difficulty, 0.5, 1.5) * strength_scale
	else:
		config.wind_direction = Vector3.ZERO
		config.wind_strength = 0.0

func _configure_enemies(config: StageConfig, rng: RandomNumberGenerator) -> void:
	if config.stage_type == Constants.StageType.DEFENSE:
		config.enemy_count = clampi(3 + config.stage_number / 5, 3, 15)
	elif config.stage_type == Constants.StageType.SURVIVAL:
		config.enemy_count = clampi(2 + config.stage_number / 6, 2, 12)
	elif config.is_boss_stage:
		config.enemy_count = 1
	else:
		config.enemy_count = 0

	for i in range(config.enemy_count):
		var angle := rng.randf_range(0.0, TAU)
		var distance := config.arena_radius * rng.randf_range(0.6, 1.0)
		config.enemy_spawn_points.append(Vector3(cos(angle) * distance, 0.0, sin(angle) * distance))

func _configure_resources(config: StageConfig, rng: RandomNumberGenerator) -> void:
	config.arrow_count = clampi(config.target_count + rng.randi_range(2, 6), 5, 40)

	var base_time := 60.0 + config.target_count * 5.0
	match config.stage_type:
		Constants.StageType.TIME_ATTACK:
			base_time *= 0.7
		Constants.StageType.SURVIVAL:
			base_time = 120.0 + config.stage_number * 2.0
		Constants.StageType.BOSS_ARCHERY:
			base_time = 180.0
	config.time_limit_seconds = clampf(base_time / clamp(config.difficulty, 0.6, 1.6), 30.0, 300.0)

	config.coin_reward = 20 + config.stage_number * 2
	config.xp_reward = 30 + config.stage_number * 3

func _configure_audio(config: StageConfig) -> void:
	var env_key := Constants.ENVIRONMENT_NAMES.get(config.environment, "ancient_forest")
	config.music_id = "music_" + env_key.to_lower().replace(" ", "_")
