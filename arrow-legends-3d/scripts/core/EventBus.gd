extends Node
## EventBus.gd
## Global signal hub. Systems communicate through signals instead of direct
## references so gameplay, UI, audio and save systems stay decoupled
## (Modular / Reusable requirement, section 26).

# --- Game flow ---
signal game_state_changed(new_state: int, old_state: int)
signal stage_generation_started(stage_number: int)
signal stage_generation_finished(stage_config: Resource)
signal stage_validation_failed(reason: String)
signal stage_ready(stage_config: Resource)
signal stage_started()
signal stage_completed(result: Dictionary)
signal stage_failed(reason: String)

# --- Player / combat ---
signal arrow_fired(arrow_type: int, origin: Vector3, direction: Vector3)
signal target_hit(target_id: String, is_critical: bool, is_perfect: bool)
signal target_missed()
signal combo_changed(combo_count: int, multiplier: float)
signal combo_broken()
signal player_health_changed(current: float, max: float)
signal boss_health_changed(current: float, max: float)
signal boss_phase_changed(phase_index: int)
signal boss_defeated(boss_id: String)

# --- Economy / progression ---
signal coins_changed(new_amount: int)
signal gems_changed(new_amount: int)
signal xp_gained(amount: int, new_total: int)
signal player_leveled_up(new_level: int)
signal mission_completed(mission_id: String)
signal achievement_unlocked(achievement_id: String)
signal stars_awarded(stage_number: int, stars: int)

# --- Save ---
signal save_completed()
signal save_failed(reason: String)
signal load_completed()

# --- Settings ---
signal settings_changed(settings: Dictionary)
