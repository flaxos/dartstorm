class_name TacticalMinimap
extends Control
## Circular tactical minimap / radar for DARTSTORM 1.0.
## Shows arena cover geometry silhouettes, player heading + FOV cone, teammates,
## enemy gunshot/proximity blips, Bomb Sites A/B, dropped/planted bomb,
## CTF flags & pedestals, Zombie Siege Base Core, Ammo Buckets, and Power-Ups.

const RADAR_RANGE := 38.0
const BLIP_DURATION := 2.0
const PROXIMITY_REVEAL := 11.5

var _player: Player
var _controller: MatchController
var _cover_boxes: Array[Dictionary] = []
var _enemy_blips: Dictionary = {} # instance_id -> { "pos": Vector3, "time": float, "color": Color }
var _cover_scanned: bool = false
var _pulse_time: float = 0.0
var _connected_actors: Dictionary = {} # instance_id -> true
var _clip_circle: PackedVector2Array = PackedVector2Array()
var _clip_radius: float = -1.0
var _clip_centre: Vector2 = Vector2.ZERO


func setup(player: Player, controller: MatchController, diameter: float = 152.0) -> void:
	_player = player
	_controller = controller
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(diameter, diameter)
	size = Vector2(diameter, diameter)
	_scan_arena_cover()
	_watch_actors()


func _process(delta: float) -> void:
	_pulse_time += delta
	if _player == null or _controller == null or not is_instance_valid(_player):
		return
	if not _cover_scanned:
		_scan_arena_cover()
	_watch_actors()
	# Decay enemy gunfire blips
	for key: int in _enemy_blips.keys():
		var info: Dictionary = _enemy_blips[key]
		info["time"] = float(info["time"]) - delta
		if float(info["time"]) <= 0.0:
			_enemy_blips.erase(key)
	queue_redraw()


func _watch_actors() -> void:
	if _controller == null:
		return
	for actor in _controller.actors:
		if actor == null or not is_instance_valid(actor) or actor == _player:
			continue
		var iid := actor.get_instance_id()
		if _connected_actors.has(iid):
			continue
		_connected_actors[iid] = true
		if actor.has_signal(&"shot_fired"):
			actor.shot_fired.connect(_on_actor_fired.bind(actor))


func _on_actor_fired(_state: WeaponState, actor: Actor) -> void:
	if actor == null or not is_instance_valid(actor) or _player == null or not is_instance_valid(_player):
		return
	if _is_teammate(actor):
		return
	_enemy_blips[actor.get_instance_id()] = {
		"pos": actor.global_position,
		"time": BLIP_DURATION,
		"color": actor.color.lightened(0.15),
	}


func _is_teammate(other: Actor) -> bool:
	if _controller == null or _controller.mode == null or _player == null:
		return false
	if not _controller.mode.is_team_mode():
		return false
	return other.team_id >= 0 and other.team_id == _player.team_id


func _scan_arena_cover() -> void:
	_cover_boxes.clear()
	if _controller == null or _controller.arena == null or _controller.arena.geometry == null:
		return
	_collect_boxes_recursive(_controller.arena.geometry)
	_cover_scanned = true


func _collect_boxes_recursive(node: Node) -> void:
	if node is StaticBody3D:
		var body := node as StaticBody3D
		for child in body.get_children():
			if child is CollisionShape3D:
				var cs := child as CollisionShape3D
				if cs.shape is BoxShape3D:
					var bs := cs.shape as BoxShape3D
					var sz := bs.size
					# Keep tactical walls, crates, forts & platforms; skip flat ground slabs & sky blockers
					if sz.y >= 0.65 and sz.y <= 9.0 and maxf(sz.x, sz.z) <= 32.0 and cs.global_position.y < 6.0:
						var yaw := cs.global_rotation.y
						_cover_boxes.append({
							"pos": Vector2(cs.global_position.x, cs.global_position.z),
							"half": Vector2(sz.x * 0.5, sz.z * 0.5),
							"yaw": yaw,
						})
	for child in node.get_children():
		_collect_boxes_recursive(child)


func _world_to_radar(world_pos: Vector3, centre: Vector2, radius: float, p_pos: Vector3, p_yaw: float) -> Vector2:
	var rel := Vector2(world_pos.x - p_pos.x, world_pos.z - p_pos.z)
	# Rotate by +p_yaw so player forward (-Z in world -> -Y on screen) points straight UP
	var c := cos(p_yaw)
	var s := sin(p_yaw)
	var rx := rel.x * c - rel.y * s
	var ry := rel.x * s + rel.y * c
	var scaled := Vector2(rx, ry) * (radius / RADAR_RANGE)
	var max_r := radius - 7.0
	if scaled.length() > max_r:
		scaled = scaled.normalized() * max_r
	return centre + scaled


func _draw() -> void:
	if _player == null or _controller == null or not is_instance_valid(_player):
		return
	var centre := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 3.0
	var p_pos := _player.global_position
	var p_yaw := _player.rotation.y
	var scale_px := radius / RADAR_RANGE

	# Circular tactical radar backdrop
	draw_circle(centre, radius + 2.0, Color(UiKit.NAVY_DARK, 0.92))
	draw_circle(centre, radius, Color(0.05, 0.11, 0.24, 0.82))

	# Subtle range rings & cross axes
	draw_arc(centre, radius * 0.5, 0.0, TAU, 36, Color(UiKit.SKY, 0.18), 1.2, true)
	draw_line(centre - Vector2(radius, 0.0), centre + Vector2(radius, 0.0), Color(UiKit.SKY, 0.12), 1.0, true)
	draw_line(centre - Vector2(0.0, radius), centre + Vector2(0.0, radius), Color(UiKit.SKY, 0.12), 1.0, true)

	# Player FOV cone wedge pointing up
	var fov_pts := PackedVector2Array([
		centre,
		centre + Vector2(-sin(0.55), -cos(0.55)) * (radius * 0.72),
		centre + Vector2(0.0, -radius * 0.78),
		centre + Vector2(sin(0.55), -cos(0.55)) * (radius * 0.72),
	])
	draw_colored_polygon(fov_pts, Color(UiKit.SKY, 0.11))

	# Arena tactical cover footprints clipped cleanly inside the radar circle
	var clip_r := radius - 2.5
	if not is_equal_approx(_clip_radius, clip_r) or _clip_centre != centre:
		_clip_radius = clip_r
		_clip_centre = centre
		_clip_circle = PackedVector2Array()
		const SEGMENTS := 28
		for i in SEGMENTS:
			var ang := TAU * float(i) / float(SEGMENTS)
			_clip_circle.append(centre + Vector2(cos(ang), sin(ang)) * clip_r)

	var c_p := cos(p_yaw)
	var s_p := sin(p_yaw)
	var cover_col := Color(0.52, 0.70, 0.92, 0.24)
	for box_info: Dictionary in _cover_boxes:
		var bpos: Vector2 = box_info["pos"]
		var half: Vector2 = box_info["half"]
		var rel := Vector2(bpos.x - p_pos.x, bpos.y - p_pos.z)
		if rel.length() - half.length() > RADAR_RANGE:
			continue
		var byaw: float = box_info["yaw"]
		var cb := cos(-byaw)
		var sb := sin(-byaw)
		var corners := PackedVector2Array()
		for sign_v: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			var local_c := Vector2(sign_v.x * half.x, sign_v.y * half.y)
			var wx := bpos.x + local_c.x * cb - local_c.y * sb - p_pos.x
			var wz := bpos.y + local_c.x * sb + local_c.y * cb - p_pos.z
			var rx := wx * c_p - wz * s_p
			var ry := wx * s_p + wz * c_p
			corners.append(centre + Vector2(rx, ry) * scale_px)
		for clipped: PackedVector2Array in Geometry2D.intersect_polygons(corners, _clip_circle):
			if clipped.size() >= 3 and not Geometry2D.triangulate_polygon(clipped).is_empty():
				draw_colored_polygon(clipped, cover_col)

	var arena := _controller.arena
	if arena != null:
		# Ammo buckets (subtle amber pips)
		for bucket in arena.buckets:
			if bucket != null and is_instance_valid(bucket) and bucket.visible:
				var bp := _world_to_radar(bucket.global_position, centre, radius, p_pos, p_yaw)
				draw_circle(bp, 2.5, Color(1.0, 0.82, 0.22, 0.72))

		# Bomb Sites A & B
		if _controller.mode is PlantTheBombMode:
			var font := UiKit.font()
			for site_id: String in arena.bomb_sites:
				var spos: Vector3 = arena.bomb_sites[site_id]
				var rp := _world_to_radar(spos, centre, radius, p_pos, p_yaw)
				_draw_diamond(rp, 7.5, UiKit.ORANGE_HOT)
				if font != null:
					draw_string(font, rp + Vector2(-4.0, 4.5), site_id, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiKit.NAVY_DARK)

	# Active Bomb marker
	if _controller.mode is PlantTheBombMode:
		var bomb: BombTarget = get_tree().get_first_node_in_group(&"bomb_target") as BombTarget
		if bomb != null and is_instance_valid(bomb):
			var b_world := bomb.carrier.global_position if (bomb.carrier != null and is_instance_valid(bomb.carrier)) else bomb.global_position
			var bp := _world_to_radar(b_world, centre, radius, p_pos, p_yaw)
			var pulse := 1.0 + 0.35 * sin(_pulse_time * 8.0)
			var bcol := Color(1.0, 0.25, 0.2) if bomb.state == BombTarget.BombState.PLANTED else UiKit.ORANGE_HOT
			draw_arc(bp, 6.5 * pulse, 0.0, TAU, 16, bcol, 2.0, true)
			draw_circle(bp, 3.5, bcol)

	# CTF Flags & Pedestals
	if _controller.mode is CaptureTheFlagMode:
		for node in get_tree().get_nodes_in_group(&"flags"):
			var fl := node as FlagPickup
			if fl != null and is_instance_valid(fl):
				var fcol := GameMode.team_color(fl.team_id).lightened(0.25)
				var ped_p := _world_to_radar(fl.base_position, centre, radius, p_pos, p_yaw)
				draw_arc(ped_p, 5.5, 0.0, TAU, 14, Color(fcol, 0.55), 1.5, true)
				var fp := _world_to_radar(fl.get_flag_position(), centre, radius, p_pos, p_yaw)
				_draw_diamond(fp, 6.5, fcol)

	# Zombie Siege Base Core
	if _controller.mode is ZombieSiegeMode:
		var core: BaseCore = get_tree().get_first_node_in_group(&"base_core") as BaseCore
		if core != null and is_instance_valid(core):
			var cp := _world_to_radar(core.global_position, centre, radius, p_pos, p_yaw)
			_draw_diamond(cp, 7.0, UiKit.SKY)
			draw_circle(cp, 3.0, UiKit.CREAM)

	# Actors (Teammates always shown; enemies shown on proximity, zombie siege close-range, or gunfire blip)
	for actor in _controller.actors:
		if actor == null or not is_instance_valid(actor) or actor == _player or not actor.alive:
			continue
		var dist := p_pos.distance_to(actor.global_position)
		if _is_teammate(actor):
			var tp := _world_to_radar(actor.global_position, centre, radius, p_pos, p_yaw)
			draw_circle(tp, 4.5, UiKit.NAVY_DARK)
			draw_circle(tp, 3.2, UiKit.LIME if actor.is_human else UiKit.SKY)
		elif dist <= PROXIMITY_REVEAL or (actor.is_zombie and dist <= 26.0):
			var ep := _world_to_radar(actor.global_position, centre, radius, p_pos, p_yaw)
			var ecol := Color(0.45, 0.95, 0.35) if actor.is_zombie else Color(1.0, 0.32, 0.22)
			draw_circle(ep, 4.4, UiKit.NAVY_DARK)
			draw_circle(ep, 3.1, ecol)

	# Fading gunfire blips for distant shooting rivals
	for info_v: Variant in _enemy_blips.values():
		var info: Dictionary = info_v
		var alpha := clampf(float(info["time"]) / BLIP_DURATION, 0.0, 1.0)
		var bp := _world_to_radar(info["pos"] as Vector3, centre, radius, p_pos, p_yaw)
		draw_circle(bp, 4.2, Color(1.0, 0.35, 0.15, alpha * 0.92))
		draw_arc(bp, 4.2 + (1.0 - alpha) * 6.0, 0.0, TAU, 14, Color(1.0, 0.6, 0.2, alpha * 0.65), 1.4, true)

	# Outer tactical ring + rotating North pip
	draw_arc(centre, radius, 0.0, TAU, 56, UiKit.SKY, 2.8, true)
	var north_dir := Vector2(sin(p_yaw), -cos(p_yaw))
	var n_pos := centre + north_dir * (radius - 1.0)
	draw_circle(n_pos, 8.0, UiKit.NAVY_DARK)
	draw_arc(n_pos, 8.0, 0.0, TAU, 16, UiKit.ORANGE_HOT, 1.8, true)
	var font_n := UiKit.font()
	if font_n != null:
		draw_string(font_n, n_pos + Vector2(-4.5, 4.5), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiKit.ORANGE_HOT)

	# Local player chevron dead-center pointing straight up
	var arrow := PackedVector2Array([
		centre + Vector2(0.0, -7.5),
		centre + Vector2(5.5, 5.5),
		centre + Vector2(0.0, 2.5),
		centre + Vector2(-5.5, 5.5),
	])
	draw_colored_polygon(arrow, UiKit.CREAM)
	draw_polyline(PackedVector2Array([arrow[0], arrow[1], arrow[2], arrow[3], arrow[0]]), UiKit.NAVY_DARK, 1.6, true)


func _draw_diamond(at: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array([
		at + Vector2(0.0, -r),
		at + Vector2(r, 0.0),
		at + Vector2(0.0, r),
		at + Vector2(-r, 0.0),
	])
	draw_colored_polygon(pts, col)
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), UiKit.NAVY_DARK, 1.4, true)
