class_name AmmoBucket
extends Node3D
## A bucket of foam darts. Stand next to it to refill your blasters.
## It drains as darts are taken, shows when it is empty, and refills itself
## after `regen_delay` seconds. The Chainstorm drinks buckets dry very quickly,
## so holding a bucket matters.

signal stock_changed(stock: int, capacity: int)

@export var capacity: int = 150
@export var regen_delay: float = 14.0
@export var can_regenerate: bool = true
## Darts handed over per second while someone stands in range.
@export var transfer_per_second: float = 90.0
@export var radius: float = 1.9
@export var bucket_color: Color = Color(0.95, 0.95, 0.9)

var stock: int = 0

var _regen_left: float = 0.0
var _carry: float = 0.0
var _area: Area3D
var _pile: Node3D
var _label: Label3D
var _ring: MeshInstance3D
var _time: float = 0.0
var _last_reported_stock: int = -1
var _last_regen_sec: int = -1


func _ready() -> void:
	add_to_group(&"ammo_buckets")
	stock = capacity
	_build()
	_refresh()


func is_empty() -> bool:
	return stock <= 0


func _physics_process(delta: float) -> void:
	_time += delta
	_label.position.y = 1.55 + sin(_time * 2.5) * 0.06
	if stock <= 0:
		if not can_regenerate:
			if _last_reported_stock != 0 or _label.text != "DEPLETED":
				_refresh()
			return
		_regen_left -= delta
		if _regen_left <= 0.0:
			stock = capacity
			Sfx.play_at(&"ammo", global_position, 0.7)
			_refresh()
		else:
			var sec := int(ceilf(maxf(_regen_left, 0.0)))
			if sec != _last_regen_sec or _last_reported_stock != 0:
				_refresh()
		return

	_carry = minf(_carry + transfer_per_second * delta, 30.0)
	var budget := int(_carry)
	if budget <= 0:
		return
	var changed := false
	for body in _area.get_overlapping_bodies():
		var actor := body as Actor
		if actor == null or not actor.alive or actor.is_tagged_out or actor.is_zombie:
			continue
		var taken := actor.collect_ammo(mini(budget, stock))
		if taken <= 0:
			continue
		stock -= taken
		budget -= taken
		_carry -= float(taken)
		changed = true
		if stock <= 0:
			_regen_left = regen_delay
			break
		if budget <= 0:
			break
	if changed:
		_refresh()


func _refresh() -> void:
	var ratio := float(stock) / float(maxi(capacity, 1))
	_pile.visible = stock > 0
	_pile.position.y = lerpf(0.05, 0.42, ratio)
	if stock > 0:
		_label.text = "AMMO\n%d" % stock
		_label.modulate = UiKit.CREAM
		_last_regen_sec = -1
	elif not can_regenerate:
		_label.text = "DEPLETED"
		_label.modulate = UiKit.GREY
		_last_regen_sec = -1
	else:
		var sec := int(ceilf(maxf(_regen_left, 0.0)))
		_last_regen_sec = sec
		_label.text = "EMPTY\n%d" % sec
		_label.modulate = UiKit.GREY
	_ring.visible = stock > 0
	if stock != _last_reported_stock:
		_last_reported_stock = stock
		stock_changed.emit(stock, capacity)


func _build() -> void:
	# The bucket itself is a small solid obstacle.
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	var shape := CylinderShape3D.new()
	shape.radius = 0.5
	shape.height = 0.75
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 0.375
	body.add_child(collision)
	add_child(body)

	ArenaKit.deco_cylinder(self, 0.42, 0.75, Vector3(0.0, 0.375, 0.0), bucket_color, Vector3.ZERO, 0.56)
	ArenaKit.deco_cylinder(self, 0.6, 0.08, Vector3(0.0, 0.76, 0.0), bucket_color.darkened(0.25), Vector3.ZERO, 0.6)

	# A pile of darts poking out of the top; it sinks as the bucket drains.
	_pile = Node3D.new()
	add_child(_pile)
	for i in 9:
		var angle := TAU * float(i) / 9.0
		var spot := Vector3(cos(angle), 0.0, sin(angle)) * (0.28 if i > 0 else 0.0)
		var dart := Node3D.new()
		dart.position = spot + Vector3(0.0, 0.3, 0.0)
		dart.rotation = Vector3(spot.z * 1.4, 0.0, -spot.x * 1.4)
		_pile.add_child(dart)
		ArenaKit.deco_cylinder(dart, 0.07, 0.42, Vector3.ZERO, Color(0.25, 0.6, 1.0))
		ArenaKit.deco_cylinder(dart, 0.085, 0.1, Vector3(0.0, 0.26, 0.0), Color(1.0, 0.45, 0.05))

	# Ring on the grass showing the refill range.
	_ring = MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = radius - 0.12
	ring_mesh.outer_radius = radius
	_ring.mesh = ring_mesh
	var ring_material := StandardMaterial3D.new()
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.albedo_color = Color(bucket_color.lightened(0.3), 0.55)
	_ring.material_override = ring_material
	_ring.position.y = 0.03
	_ring.scale.y = 0.15
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)

	_label = Label3D.new()
	_label.font = UiKit.font()
	_label.font_size = 64
	_label.pixel_size = 0.006
	_label.outline_size = 14
	_label.outline_modulate = UiKit.NAVY_DARK
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = 1.55
	add_child(_label)

	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = Layers.ACTORS
	_area.monitorable = false
	var area_shape := CylinderShape3D.new()
	area_shape.radius = radius
	area_shape.height = 2.4
	var area_collision := CollisionShape3D.new()
	area_collision.shape = area_shape
	area_collision.position.y = 1.2
	_area.add_child(area_collision)
	add_child(_area)
