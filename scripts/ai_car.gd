extends Node3D

var lane_offset := 0.0
var phase := 0.0
var speed_factor := 0.85
var track_radius := 52.0
var angle := 0.0

func _ready() -> void:
	angle = phase

func _process(delta: float) -> void:
	angle += delta * 0.42 * speed_factor
	var radius := track_radius + lane_offset
	position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
	rotation.y = -angle - PI * 0.5
