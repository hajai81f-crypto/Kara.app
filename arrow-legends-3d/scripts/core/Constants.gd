extends Node
## Constants.gd
## Central definition of enums and tunable constants used across every system.
## Autoloaded as "Constants". Keeping these in one place avoids magic strings
## and magic numbers scattered through the codebase (see Architecture rules).

enum GameState {
	BOOT,
	LOADING,
	MAIN_MENU,
	STAGE_GENERATING,
	STAGE_VALIDATING,
	PLAYING,
	PAUSED,
	STAGE_RESULT,
	GAME_OVER
}

enum StageType {
	TARGET_RANGE,
	MOVING_TARGET,
	SPEED_ARCHER,
	WIND_MASTER,
	BOSS_ARCHERY,
	SURVIVAL,
	TIME_ATTACK,
	PERFECT_SHOT,
	DEFENSE,
	LONG_DISTANCE,
	TRICK_SHOT
}

enum EnvironmentType {
	ANCIENT_FOREST,
	DESERT,
	SNOW_MOUNTAIN,
	MEDIEVAL_CASTLE,
	DARK_VALLEY,
	VOLCANO,
	ANCIENT_TEMPLE,
	FLOATING_ISLANDS
}

enum ArrowType {
	NORMAL,
	HEAVY,
	FIRE,
	ICE,
	EXPLOSIVE,
	LIGHTNING,
	PIERCING,
	MULTI
}

enum BowType {
	BASIC,
	HUNTER,
	WARRIOR,
	ANCIENT,
	SHADOW,
	LEGENDARY
}

enum WeatherType {
	CLEAR,
	WINDY,
	RAIN,
	SNOW,
	FOG,
	STORM
}

# --- Progression curve boundaries (see Design Doc section 35) ---
const TUTORIAL_STAGE_MAX := 10
const SYSTEMS_STAGE_MAX := 30
const MEDIUM_STAGE_MAX := 60
const PROFESSIONAL_STAGE_MAX := 100
# Beyond PROFESSIONAL_STAGE_MAX the game enters "Endless Mastery" scaling.

# --- Physics defaults, overridden per-stage by StageGenerator ---
const DEFAULT_GRAVITY := 9.8
const MAX_WIND_FORCE := 6.0
const MIN_ARROW_SPEED := 25.0
const MAX_ARROW_SPEED := 70.0

# --- Save file location ---
const SAVE_FILE_PATH := "user://save_data.json"
const SAVE_FILE_BACKUP_PATH := "user://save_data_backup.json"

# --- Human readable names, used by UI without hardcoding strings elsewhere ---
const STAGE_TYPE_NAMES := {
	StageType.TARGET_RANGE: "Target Range",
	StageType.MOVING_TARGET: "Moving Target",
	StageType.SPEED_ARCHER: "Speed Archer",
	StageType.WIND_MASTER: "Wind Master",
	StageType.BOSS_ARCHERY: "Boss Archery",
	StageType.SURVIVAL: "Survival",
	StageType.TIME_ATTACK: "Time Attack",
	StageType.PERFECT_SHOT: "Perfect Shot",
	StageType.DEFENSE: "Defense",
	StageType.LONG_DISTANCE: "Long Distance",
	StageType.TRICK_SHOT: "Trick Shot",
}

const ENVIRONMENT_NAMES := {
	EnvironmentType.ANCIENT_FOREST: "Ancient Forest",
	EnvironmentType.DESERT: "Desert",
	EnvironmentType.SNOW_MOUNTAIN: "Snow Mountain",
	EnvironmentType.MEDIEVAL_CASTLE: "Medieval Castle",
	EnvironmentType.DARK_VALLEY: "Dark Valley",
	EnvironmentType.VOLCANO: "Volcano",
	EnvironmentType.ANCIENT_TEMPLE: "Ancient Temple",
	EnvironmentType.FLOATING_ISLANDS: "Floating Islands",
}
