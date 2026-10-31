extends Node3D

var lane_offset := 0.0
var phase := 0.0
var speed_factor := 0.85
var track_radius := 52.0
var angle := 0.0
var driver_name := "AI Driver"
var driver_number := "0"
var collision_area: Area3D

func _ready() -> void:
	angle = phase
	collision_area = Area3D.new()
	collision_area.collision_layer = 0
	collision_area.collision_mask = 1
	var hitbox := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.8, 1.2, 4.0)
	hitbox.shape = shape
	collision_area.add_child(hitbox)
	add_child(collision_area)
	collision_area.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	angle += delta * 0.42 * speed_factor
	var radius := track_radius + lane_offset
	position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
	rotation.y = -angle - PI * 0.5

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("apply_collision"):
		var impact_direction := (body.global_position - global_position).normalized()
		body.apply_collision(impact_direction)
