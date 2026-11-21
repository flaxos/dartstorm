extends Node
## Autoload "Progression": tracks player XP, levels, coins, cosmetics unlocks,
## and active backyard missions. Purely gameplay-earned (D-028), zero real money,
## zero gems, zero microtransactions, and zero paid power.
## Saved to user://progression.cfg.

signal xp_gained(amount: int, total_xp: int)
signal level_up(new_level: int)
signal coins_changed(new_balance: int)
signal item_unlocked(category: StringName, id: Variant)
signal mission_progress(mission_id: StringName, current: int, target: int)
signal mission_completed(mission: Dictionary)
signal progression_saved
signal progression_loaded

const SAVE_PATH := "user://progression.cfg"
const PROGRESSION_VERSION := 1

## Starting coins given to every new player so they can get their first cool hat or colour!
const STARTING_COINS := 250

## Standard reward values across modes
const XP_PER_TAG := 25
const COINS_PER_TAG := 5
const XP_MATCH_FINISH := 100
const COINS_MATCH_FINISH := 25
const XP_MATCH_WIN := 150
const COINS_MATCH_WIN := 50
const XP_MISSION_REWARD := 200
const COINS_MISSION_REWARD := 100

const DEFAULT_HATS: Array[StringName] = [&"cap", &"beanie", &"none"]
const DEFAULT_COLORS: Array[int] = [0, 1, 2, 3]
const DEFAULT_SKINS: Array[StringName] = [&"default"]

## The backyard mission pool: kid-safe, engaging objectives
const MISSION_POOL: Array[Dictionary] = [
	{
		"id": &"ricochet_tags",
		"title": "RICOCHET ACE",
		"description": "Score 2 ricochet tags off mirrors",
		"event": &"ricochet_tag",
		"target": 2,
		"xp_reward": XP_MISSION_REWARD,
		"coin_reward": COINS_MISSION_REWARD,
		"icon": "🪞",
	},
	{
		"id": &"chain_zaps",
		"title": "THUNDER LINK",
		"description": "Chain zap 3 rivals with lightning",
		"event": &"chain_zap",
		"target": 3,
		"xp_reward": XP_MISSION_REWARD,
		"coin_reward": COINS_MISSION_REWARD,
		"icon": "⚡",
	},
	{
		"id": &"extinguish",
		"title": "FIREFIGHTER",
		"description": "Extinguish sparkling fire with water",
		"event": &"extinguish",
		"target": 1,
		"xp_reward": XP_MISSION_REWARD,
		"coin_reward": COINS_MISSION_REWARD,
		"icon": "💧",
	},
	{
		"id": &"ice_slides",
		"title": "SPEED SLICK",
		"description": "Slide down ice slicks 2 times",
		"event": &"ice_slide",
		"target": 2,
		"xp_reward": XP_MISSION_REWARD,
		"coin_reward": COINS_MISSION_REWARD,
		"icon": "🧊",
	},
	{
		"id": &"shield_absorb",
		"title": "FOAM BUBBLE",
		"description": "Absorb a hit with Foam Shield",
		"event": &"shield_absorb",
		"target": 1,
		"xp_reward": XP_MISSION_REWARD,
		"coin_reward": COINS_MISSION_REWARD,
		"icon": "🛡️",
	},
	{
		"id": &"zombie_tags",
		"title": "ZOMBIE CURE",
		"description": "Tag out 2 Green Zombies",
		"event": &"zombie_tag",
		"target": 2,
		"xp_reward": XP_MISSION_REWARD,
		"coin_reward": COINS_MISSION_REWARD,
		"icon": "🧟",
	},
	{
		"id": &"popper_tags",
		"title": "POCKET POWER",
		"description": "Tag 3 rivals with Pocket Popper",
		"event": &"popper_tag",
		"target": 3,
		"xp_reward": XP_MISSION_REWARD,
		"coin_reward": COINS_MISSION_REWARD,
		"icon": "🔫",
	},
]

const ACTIVE_MISSION_COUNT := 3

var active_profile_index: int = 0
var profiles: Array[Dictionary] = []
var lifetime_xp: int = 0
var coins: int = STARTING_COINS
var unlocked_hats: Array[StringName] = []
var unlocked_colors: Array[int] = []
var unlocked_skins: Array[StringName] = []
var active_missions: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_progression()


## Level curve calculations:
## Level 1: 0..99 XP
## Level 2: 100..299 XP (requires 100 XP to reach Level 2)
## Level 3: 300..599 XP (requires 200 XP to reach Level 3)
## Level N requires 100 * (N-1) XP to reach from N-1.
## Cumulative XP to reach level N: 50 * N * (N - 1).
func level_for_xp(xp: int) -> int:
	if xp <= 0:
		return 1
	var lvl := int(floorf((1.0 + sqrt(1.0 + 0.08 * float(xp))) * 0.5))
	return maxi(lvl, 1)


func xp_for_level(lvl: int) -> int:
	if lvl <= 1:
		return 0
	return 50 * lvl * (lvl - 1)


## Returns details about progress towards the next level:
## { "level": int, "current_xp": int, "needed_xp": int, "ratio": float }
func level_progress(xp: int) -> Dictionary:
	var lvl := level_for_xp(xp)
	var base_xp := xp_for_level(lvl)
	var needed_xp := 100 * lvl
	var current_xp := xp - base_xp
	var ratio := clampf(float(current_xp) / float(maxi(needed_xp, 1)), 0.0, 1.0)
	return {
		"level": lvl,
		"current_xp": current_xp,
		"needed_xp": needed_xp,
		"ratio": ratio,
	}


func get_level() -> int:
	return level_for_xp(lifetime_xp)


func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	var old_level := get_level()
	lifetime_xp += amount
	xp_gained.emit(amount, lifetime_xp)
	var new_level := get_level()
	if new_level > old_level:
		level_up.emit(new_level)
		if has_node("/root/Sfx"):
			var sfx: Node = get_node("/root/Sfx")
			if sfx.has_method("play"):
				sfx.call("play", &"level_up")
	save_progression()


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	coins_changed.emit(coins)
	save_progression()


func can_afford(cost: int) -> bool:
	return cost <= 0 or coins >= cost


func spend_coins(cost: int) -> bool:
	if cost <= 0:
		return true
	if coins < cost:
		return false
	coins -= cost
	coins_changed.emit(coins)
	_sync_to_active_profile()
	save_progression()
	return true


func _default_profile_dict(_is_p2: bool = false) -> Dictionary:
	return {
		"lifetime_xp": 0,
		"coins": STARTING_COINS,
		"unlocked_hats": DEFAULT_HATS.duplicate(),
		"unlocked_colors": DEFAULT_COLORS.duplicate(),
		"unlocked_skins": DEFAULT_SKINS.duplicate(),
	}


func _sync_active_profile() -> void:
	if profiles.size() < 2:
		profiles = [_default_profile_dict(false), _default_profile_dict(true)]
	var cur: Dictionary = profiles[clampi(active_profile_index, 0, profiles.size() - 1)]
	lifetime_xp = int(cur.get("lifetime_xp", 0))
	coins = int(cur.get("coins", STARTING_COINS))
	var raw_hats: Array = cur.get("unlocked_hats", DEFAULT_HATS.duplicate())
	unlocked_hats.clear()
	for h in raw_hats:
		unlocked_hats.append(StringName(str(h)))
	var raw_colors: Array = cur.get("unlocked_colors", DEFAULT_COLORS.duplicate())
	unlocked_colors.clear()
	for c in raw_colors:
		unlocked_colors.append(int(c))
	var raw_skins: Array = cur.get("unlocked_skins", DEFAULT_SKINS.duplicate())
	unlocked_skins.clear()
	for s in raw_skins:
		unlocked_skins.append(StringName(str(s)))


func _sync_to_active_profile() -> void:
	if profiles.size() < 2:
		profiles = [_default_profile_dict(false), _default_profile_dict(true)]
	var cur: Dictionary = profiles[clampi(active_profile_index, 0, profiles.size() - 1)]
	cur["lifetime_xp"] = lifetime_xp
	cur["coins"] = coins
	cur["unlocked_hats"] = unlocked_hats.duplicate()
	cur["unlocked_colors"] = unlocked_colors.duplicate()
	cur["unlocked_skins"] = unlocked_skins.duplicate()


func get_profile_count() -> int:
	return maxi(profiles.size(), 2)


func set_active_profile(idx: int) -> void:
	_sync_to_active_profile()
	active_profile_index = clampi(idx, 0, 1)
	_sync_active_profile()
	coins_changed.emit(coins)
	progression_saved.emit()


func get_profile_data(idx: int = active_profile_index) -> Dictionary:
	_sync_to_active_profile()
	var p_idx := clampi(idx, 0, 1)
	if profiles.size() < 2:
		profiles = [_default_profile_dict(false), _default_profile_dict(true)]
	var prof: Dictionary = profiles[p_idx].duplicate(true)
	if p_idx == 0:
		prof["name"] = GameSettings.display_name()
		prof["color"] = GameSettings.player_color
		prof["hat"] = GameSettings.player_hat
		prof["skin"] = GameSettings.player_skin
	else:
		prof["name"] = GameSettings.display_name_p2()
		prof["color"] = GameSettings.player2_color
		prof["hat"] = GameSettings.player2_hat
		prof["skin"] = GameSettings.player2_skin
	prof["level"] = level_for_xp(int(prof.get("lifetime_xp", 0)))
	return prof


func award_match_rewards(player_idx: int, tags: int, won: bool, finished: bool) -> void:
	var xp := (tags * XP_PER_TAG) + (XP_MATCH_FINISH if finished else 0) + (XP_MATCH_WIN if won else 0)
	var earned_coins := (tags * COINS_PER_TAG) + (COINS_MATCH_FINISH if finished else 0) + (COINS_MATCH_WIN if won else 0)
	if player_idx == active_profile_index:
		add_xp(xp)
		add_coins(earned_coins)
	elif player_idx >= 0 and player_idx < profiles.size():
		var p: Dictionary = profiles[player_idx]
		p["lifetime_xp"] = int(p.get("lifetime_xp", 0)) + xp
		p["coins"] = int(p.get("coins", STARTING_COINS)) + earned_coins
		save_progression()


func activate_boss_mode() -> void:
	_sync_to_active_profile()
	if profiles.size() < 2:
		profiles = [_default_profile_dict(false), _default_profile_dict(true)]
	for p in profiles:
		p["coins"] = 99999
		p["lifetime_xp"] = maxi(int(p.get("lifetime_xp", 0)), 5000)
		var all_hats: Array[StringName] = []
		for h in Cosmetics.HATS:
			all_hats.append(h["id"])
		p["unlocked_hats"] = all_hats
		var all_colors: Array[int] = []
		for ci in Cosmetics.COLORS.size():
			all_colors.append(ci)
		p["unlocked_colors"] = all_colors
		var all_skins: Array[StringName] = []
		for s in Cosmetics.SKINS:
			all_skins.append(s["id"])
		p["unlocked_skins"] = all_skins
	_sync_active_profile()
	save_progression()
	coins_changed.emit(coins)
	for h in Cosmetics.HATS:
		item_unlocked.emit(&"hat", h["id"])
	for ci in Cosmetics.COLORS.size():
		item_unlocked.emit(&"color", ci)
	for s in Cosmetics.SKINS:
		item_unlocked.emit(&"skin", s["id"])


func is_unlocked(category: StringName, id: Variant) -> bool:
	match category:
		&"hat":
			var hat_id := StringName(str(id))
			return Cosmetics.is_default_hat(hat_id) or unlocked_hats.has(hat_id)
		&"color":
			var color_index := int(id)
			return Cosmetics.is_default_color(color_index) or unlocked_colors.has(color_index)
		&"skin":
			var skin_id := StringName(str(id))
			return Cosmetics.is_default_skin(skin_id) or unlocked_skins.has(skin_id)
	return false


func unlock_item(category: StringName, id: Variant) -> bool:
	if is_unlocked(category, id):
		return true
	match category:
		&"hat":
			var hat_id := StringName(str(id))
			if not Cosmetics.has_hat(hat_id):
				return false
			unlocked_hats.append(hat_id)
			item_unlocked.emit(category, hat_id)
			save_progression()
			return true
		&"color":
			var color_index := int(id)
			if color_index < 0 or color_index >= Cosmetics.COLORS.size():
				return false
			unlocked_colors.append(color_index)
			item_unlocked.emit(category, color_index)
			save_progression()
			return true
		&"skin":
			var skin_id := StringName(str(id))
			if not Cosmetics.has_skin(skin_id):
				return false
			unlocked_skins.append(skin_id)
			item_unlocked.emit(category, skin_id)
			save_progression()
			return true
	return false


## Called when a combat event occurs (e.g. &"ricochet_tag", &"chain_zap", etc.)
func notify_event(event_type: StringName, count: int = 1) -> void:
	if count <= 0:
		return
	for i in active_missions.size():
		var mission: Dictionary = active_missions[i]
		if mission.get("event") == event_type:
			var target: int = mission.get("target", 1)
			var current: int = mission.get("progress", 0)
			if current < target:
				var updated: int = mini(current + count, target)
				mission["progress"] = updated
				mission_progress.emit(mission["id"], updated, target)
				if updated >= target:
					_complete_mission(i)
					save_progression()
					break  # Only one mission finished per single event iteration


func _complete_mission(index: int) -> void:
	if index < 0 or index >= active_missions.size():
		return
	var completed_mission: Dictionary = active_missions[index].duplicate()
	var xp_reward: int = completed_mission.get("xp_reward", XP_MISSION_REWARD)
	var coin_reward: int = completed_mission.get("coin_reward", COINS_MISSION_REWARD)
	mission_completed.emit(completed_mission)
	add_xp(xp_reward)
	add_coins(coin_reward)

	# Replace with a new mission from the pool
	var new_mission := _roll_new_mission()
	if not new_mission.is_empty():
		active_missions[index] = new_mission
	save_progression()


func _roll_new_mission() -> Dictionary:
	var active_ids: Array[StringName] = []
	for m in active_missions:
		active_ids.append(m.get("id", &""))
	var available: Array[Dictionary] = []
	for pool_entry in MISSION_POOL:
		if not active_ids.has(pool_entry["id"]):
			available.append(pool_entry)
	if available.is_empty():
		available = MISSION_POOL.duplicate()
	var chosen: Dictionary = available[randi() % available.size()].duplicate()
	chosen["progress"] = 0
	return chosen


func ensure_active_missions() -> void:
	# Prune any duplicates or invalid missions
	var valid_missions: Array[Dictionary] = []
	var seen_ids: Array[StringName] = []
	for m in active_missions:
		var mid: StringName = m.get("id", &"")
		if not seen_ids.has(mid) and _has_pool_mission(mid):
			seen_ids.append(mid)
			valid_missions.append(m)
	active_missions = valid_missions

	while active_missions.size() < ACTIVE_MISSION_COUNT:
		var new_mission := _roll_new_mission()
		if new_mission.is_empty():
			break
		active_missions.append(new_mission)


func _has_pool_mission(id: StringName) -> bool:
	for entry in MISSION_POOL:
		if entry["id"] == id:
			return true
	return false


func reset_to_defaults() -> void:
	profiles = [
		_default_profile_dict(false),
		_default_profile_dict(true),
	]
	active_profile_index = 0
	_sync_active_profile()
	active_missions.clear()
	ensure_active_missions()
	save_progression()


func load_progression() -> void:
	var file := ConfigFile.new()
	var loaded := file.load(SAVE_PATH) == OK
	if not loaded and FileAccess.file_exists(SAVE_PATH + ".tmp"):
		loaded = file.load(SAVE_PATH + ".tmp") == OK

	if not loaded:
		# First run or missing/corrupted file: initialize defaults
		reset_to_defaults()
		progression_loaded.emit()
		return

	profiles = []
	for p_idx in 2:
		var sec := "profile_%d" % p_idx
		var p_dict := _default_profile_dict(p_idx == 1)
		if file.has_section(sec):
			p_dict["lifetime_xp"] = maxi(int(file.get_value(sec, "lifetime_xp", 0)), 0)
			p_dict["coins"] = maxi(int(file.get_value(sec, "coins", STARTING_COINS)), 0)
			var s_hats: Array = file.get_value(sec, "hats", [])
			var u_hats := DEFAULT_HATS.duplicate()
			for h in s_hats:
				var sh := StringName(str(h))
				if not u_hats.has(sh) and Cosmetics.has_hat(sh):
					u_hats.append(sh)
			p_dict["unlocked_hats"] = u_hats

			var s_colors: Array = file.get_value(sec, "colors", [])
			var u_colors := DEFAULT_COLORS.duplicate()
			for c in s_colors:
				var ci := int(c)
				if not u_colors.has(ci) and ci >= 0 and ci < Cosmetics.COLORS.size():
					u_colors.append(ci)
			p_dict["unlocked_colors"] = u_colors

			var s_skins: Array = file.get_value(sec, "skins", [])
			var u_skins := DEFAULT_SKINS.duplicate()
			for sk in s_skins:
				var skid := StringName(str(sk))
				if not u_skins.has(skid) and Cosmetics.has_skin(skid):
					u_skins.append(skid)
			p_dict["unlocked_skins"] = u_skins
		elif p_idx == 0:
			# Backwards compatibility: load from legacy sections
			p_dict["lifetime_xp"] = maxi(int(file.get_value("progression", "lifetime_xp", 0)), 0)
			p_dict["coins"] = maxi(int(file.get_value("progression", "coins", STARTING_COINS)), 0)
			var s_hats: Array = file.get_value("unlocks", "hats", [])
			var u_hats := DEFAULT_HATS.duplicate()
			for h in s_hats:
				var sh := StringName(str(h))
				if not u_hats.has(sh) and Cosmetics.has_hat(sh):
					u_hats.append(sh)
			p_dict["unlocked_hats"] = u_hats

			var s_colors: Array = file.get_value("unlocks", "colors", [])
			var u_colors := DEFAULT_COLORS.duplicate()
			for c in s_colors:
				var ci := int(c)
				if not u_colors.has(ci) and ci >= 0 and ci < Cosmetics.COLORS.size():
					u_colors.append(ci)
			p_dict["unlocked_colors"] = u_colors

			var s_skins: Array = file.get_value("unlocks", "skins", [])
			var u_skins := DEFAULT_SKINS.duplicate()
			for sk in s_skins:
				var skid := StringName(str(sk))
				if not u_skins.has(skid) and Cosmetics.has_skin(skid):
					u_skins.append(skid)
			p_dict["unlocked_skins"] = u_skins
		profiles.append(p_dict)

	active_profile_index = clampi(int(file.get_value("meta", "active_profile", 0)), 0, 1)
	_sync_active_profile()

	active_missions.clear()
	var saved_missions: Array = file.get_value("missions", "active", [])
	for m in saved_missions:
		if m is Dictionary:
			var mid: StringName = m.get("id", &"")
			for pool_entry in MISSION_POOL:
				if pool_entry["id"] == mid:
					var inst: Dictionary = pool_entry.duplicate()
					inst["progress"] = clampi(int(m.get("progress", 0)), 0, int(pool_entry["target"]))
					active_missions.append(inst)
					break

	ensure_active_missions()
	progression_loaded.emit()


func save_progression() -> void:
	_sync_to_active_profile()
	var file := ConfigFile.new()
	file.set_value("meta", "version", PROGRESSION_VERSION)
	file.set_value("meta", "active_profile", active_profile_index)
	# Legacy keys for backward compatibility
	file.set_value("progression", "lifetime_xp", lifetime_xp)
	file.set_value("progression", "coins", coins)

	var hats_save: Array[String] = []
	for h in unlocked_hats:
		hats_save.append(String(h))
	file.set_value("unlocks", "hats", hats_save)

	var colors_save: Array[int] = []
	for c in unlocked_colors:
		colors_save.append(c)
	file.set_value("unlocks", "colors", colors_save)

	var skins_save: Array[String] = []
	for sk in unlocked_skins:
		skins_save.append(String(sk))
	file.set_value("unlocks", "skins", skins_save)

	# Save individual profiles
	for p_idx in profiles.size():
		var sec := "profile_%d" % p_idx
		var p: Dictionary = profiles[p_idx]
		file.set_value(sec, "lifetime_xp", int(p.get("lifetime_xp", 0)))
		file.set_value(sec, "coins", int(p.get("coins", STARTING_COINS)))
		var p_hats: Array[String] = []
		for h in p.get("unlocked_hats", []):
			p_hats.append(String(h))
		file.set_value(sec, "hats", p_hats)
		var p_colors: Array[int] = []
		for c in p.get("unlocked_colors", []):
			p_colors.append(int(c))
		file.set_value(sec, "colors", p_colors)
		var p_skins: Array[String] = []
		for s in p.get("unlocked_skins", []):
			p_skins.append(String(s))
		file.set_value(sec, "skins", p_skins)

	var missions_save: Array[Dictionary] = []
	for m in active_missions:
		missions_save.append({
			"id": String(m.get("id", &"")),
			"progress": int(m.get("progress", 0)),
		})
	file.set_value("missions", "active", missions_save)

	var tmp_path := SAVE_PATH + ".tmp"
	var err := file.save(tmp_path)
	if err == OK:
		var copy_err := DirAccess.copy_absolute(tmp_path, SAVE_PATH)
		if copy_err != OK:
			file.save(SAVE_PATH)
	else:
		file.save(SAVE_PATH)
	progression_saved.emit()
