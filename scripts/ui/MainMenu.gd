extends Control
## MainMenu.gd
## Every button here does something real. PLAY drives the actual game loop
## through GameManager. The Phase 2+ systems (World map, Bows, Arrows,
## Upgrades, Settings screens) are not built yet in this phase, so those
## buttons honestly report that instead of pretending to open a screen -
## per section 31, no fake dead UI, but also no lying about scope.

@onready var stats_label: Label = $StatsLabel
@onready var info_dialog: AcceptDialog = $InfoDialog

func _ready() -> void:
	_refresh_stats()
	EventBus.coins_changed.connect(func(_v): _refresh_stats())
	EventBus.gems_changed.connect(func(_v): _refresh_stats())
	EventBus.player_leveled_up.connect(func(_v): _refresh_stats())

func _refresh_stats() -> void:
	var level: int = SaveManager.data.get("player_level", 1)
	var coins: int = SaveManager.data.get("coins", 0)
	var gems: int = SaveManager.data.get("gems", 0)
	stats_label.text = "Level %d  |  %d Coins  |  %d Gems" % [level, coins, gems]

func _on_play_pressed() -> void:
	GameManager.start_next_stage()

func _on_world_pressed() -> void:
	_show_info("World Map", "Environment selection ships in Phase 3 (Gameplay).")

func _on_bows_pressed() -> void:
	_show_info("Bows", "The Bow loadout screen ships in Phase 2 (Player + Bow + Arrow).")

func _on_arrows_pressed() -> void:
	_show_info("Arrows", "The Arrow loadout screen ships in Phase 2 (Player + Bow + Arrow).")

func _on_upgrades_pressed() -> void:
	_show_info("Upgrades", "Bow/Arrow upgrades ship in Phase 7 (Progression + Economy).")

func _on_missions_pressed() -> void:
	var missions := MissionManager.get_active_missions()
	if missions.is_empty():
		_show_info("Daily Missions", "No missions generated yet.")
		return
	var lines := []
	for m in missions:
		var status := "DONE" if m.completed else "%d/%d" % [m.progress, m.target]
		lines.append("- %s [%s]" % [m.description, status])
	_show_info("Daily Missions", "\n".join(lines))

func _on_achievements_pressed() -> void:
	var lines := []
	for definition in AchievementManager.get_all_definitions():
		var status := "UNLOCKED" if AchievementManager.is_unlocked(definition.id) else "locked"
		lines.append("- %s [%s]" % [definition.name, status])
	_show_info("Achievements", "\n".join(lines))

func _on_settings_pressed() -> void:
	_show_info(
		"Settings",
		"Aim Sensitivity: %.1f\nAim Assist: %.1f\nMusic: %.1f\nSFX: %.1f\n(Full Settings UI ships in Phase 8.)" % [
			SaveManager.get_settings().get("aim_sensitivity", 1.0),
			SaveManager.get_settings().get("aim_assist", 0.4),
			SaveManager.get_settings().get("music_volume", 0.8),
			SaveManager.get_settings().get("sfx_volume", 1.0),
		]
	)

func _show_info(title: String, text: String) -> void:
	info_dialog.title = title
	info_dialog.dialog_text = text
	info_dialog.popup_centered()
