extends Node
## EconomyManager.gd
## Computes rewards for stage completion. All reward sources are earned
## in-game (no pay-to-win hooks) per the design constraints.

const BASE_COIN_REWARD := 25
const BASE_XP_REWARD := 40
const PERFECT_SHOT_COIN_BONUS := 8
const COMBO_COIN_BONUS_PER_LEVEL := 5
const BOSS_STAGE_GEM_REWARD := 3

func grant_stage_rewards(result: Dictionary) -> void:
	var stage_number: int = result.get("stage_number", 1)
	var accuracy: float = result.get("accuracy", 0.0)
	var perfect_shots: int = result.get("perfect_shots", 0)
	var max_combo: int = result.get("max_combo", 0)
	var stage_type: int = result.get("stage_type", Constants.StageType.TARGET_RANGE)
	var won: bool = result.get("won", false)

	if not won:
		# Still grant a small consolation reward so players aren't punished
		# for trying, matching the "never impossible" difficulty philosophy.
		SaveManager.add_coins(int(BASE_COIN_REWARD * 0.25))
		SaveManager.add_xp(int(BASE_XP_REWARD * 0.25))
		return

	var coins := BASE_COIN_REWARD
	coins += int(stage_number * 0.5)
	coins += perfect_shots * PERFECT_SHOT_COIN_BONUS
	coins += (max_combo / 5) * COMBO_COIN_BONUS_PER_LEVEL
	coins = int(coins * clamp(accuracy + 0.5, 0.5, 1.5))

	var xp := BASE_XP_REWARD + int(stage_number * 0.75)

	SaveManager.add_coins(coins)
	SaveManager.add_xp(xp)

	if stage_type == Constants.StageType.BOSS_ARCHERY:
		SaveManager.add_gems(BOSS_STAGE_GEM_REWARD)

func can_afford(cost_coins: int = 0, cost_gems: int = 0) -> bool:
	var coins: int = SaveManager.data.get("coins", 0)
	var gems: int = SaveManager.data.get("gems", 0)
	return coins >= cost_coins and gems >= cost_gems

func spend(cost_coins: int = 0, cost_gems: int = 0) -> bool:
	if not can_afford(cost_coins, cost_gems):
		return false
	if cost_coins > 0:
		SaveManager.add_coins(-cost_coins)
	if cost_gems > 0:
		SaveManager.add_gems(-cost_gems)
	return true
