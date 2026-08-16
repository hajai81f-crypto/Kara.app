extends Resource
class_name StageConfig
## StageConfig.gd
## Data container produced by StageGenerator and consumed by the gameplay
## scene, StageValidator and Debug Tools. Being a Resource (not a Dictionary)
## gives us typed fields, easy serialization and inspector debugging.

@export var stage_number: int = 1
@export var seed_value: int = 0
@export var stage_type: int = Constants.StageType.TARGET_RANGE
@export var environment: int = Constants.EnvironmentType.ANCIENT_FOREST
@export var weather: int = Constants.WeatherType.CLEAR
@export var difficulty: float = 1.0

@export var target_count: int = 5
@export var target_positions: Array[Vector3] = []
@export var target_speeds: Array[float] = []
@export var target_move_directions: Array[Vector3] = []

@export var obstacle_positions: Array[Vector3] = []
@export var enemy_spawn_points: Array[Vector3] = []
@export var enemy_count: int = 0

@export var player_spawn_point: Vector3 = Vector3.ZERO
@export var arena_radius: float = 25.0

@export var wind_direction: Vector3 = Vector3.ZERO
@export var wind_strength: float = 0.0
@export var gravity_scale: float = 1.0

@export var arrow_count: int = 10
@export var time_limit_seconds: float = 90.0

@export var coin_reward: int = 25
@export var xp_reward: int = 40

@export var music_id: String = "ambient_forest"
@export var is_boss_stage: bool = false
@export var boss_id: String = ""

func get_stage_type_name() -> String:
	return Constants.STAGE_TYPE_NAMES.get(stage_type, "Unknown")

func get_environment_name() -> String:
	return Constants.ENVIRONMENT_NAMES.get(environment, "Unknown")
