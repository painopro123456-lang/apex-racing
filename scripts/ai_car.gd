extends Node3D

# Lightweight waypoint racing AI. Uses the generated circuit centreline rather
# than assuming every circuit is a circle.
var track_points: Array[Vector3] = []
var phase := 0.0
var speed_factor := 0.85
var lane_offset := 0.0
var driver_name := "AI Driver"
var driver_number := "0"
var collision_area: Area3D
var progress_index := 0
var completed_laps := 0
var current_speed := 0.0
var target_speed := 34.0
var base_lane := 0.0
var overtake_offset := 0.0
var overtake_timer := 0.0

const LOOKAHEAD_POINTS := 7
const TRACK_HALF_WIDTH := 7.5
const LANE_CHANGE_SPEED := 4.0

func _ready() -> void:
	base_lane = lane_offset
	add_to_group("ai_cars")
	if track_points.size() > 0:
		progress_index = int(fposmod(phase, 1.0) * track_points.size()) % track_points.size()
		global_position = _lane_point(progress_index, base_lane)
		var previous: Vector3 = track_points[(progress_index - 1 + track_points.size()) % track_points.size()]
		var next_point: Vector3 = track_points[(progress_index + 1) % track_points.size()]
		var tangent := (next_point - previous).normalized()
		rotation.y = atan2(-tangent.x, -tangent.z)
		# Grid cars begin on the previous lap, just before crossing the timing line.
		completed_laps = -1 if phase > 0.5 else 0
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

func reset_to_grid(grid_position: int) -> void:
	if track_points.size() < 3:
		return
	if grid_position <= 1:
		phase = 0.0
		progress_index = 0
		completed_laps = 0
		lane_offset = -2.1
	else:
		var row := int((grid_position - 2) / 2) + 1
		phase = fposmod(1.0 - float(row * 4) / float(track_points.size()), 1.0)
		var row_start := int(phase * track_points.size()) % track_points.size()
		progress_index = (row_start + (1 if grid_position % 2 == 0 else 0)) % track_points.size()
		completed_laps = -1
		lane_offset = -2.1 if grid_position % 2 == 0 else 2.1
	base_lane = lane_offset
	global_position = _lane_point(progress_index, base_lane)
	var previous: Vector3 = track_points[(progress_index - 1 + track_points.size()) % track_points.size()]
	var next_point: Vector3 = track_points[(progress_index + 1) % track_points.size()]
	var tangent := (next_point - previous).normalized()
	rotation.y = atan2(-tangent.x, -tangent.z)
	current_speed = 0.0
	overtake_offset = 0.0
	overtake_timer = 0.0

func _process(delta: float) -> void:
	if track_points.size() < 4:
		return
	var avoid := _find_nearby_opponent()
	if avoid != 0.0:
		overtake_offset = move_toward(overtake_offset, avoid, LANE_CHANGE_SPEED * delta)
		overtake_timer = 1.0
	elif overtake_timer > 0.0:
		overtake_timer -= delta
	else:
		overtake_offset = move_toward(overtake_offset, 0.0, LANE_CHANGE_SPEED * delta)

	var desired_lane := clamp(base_lane + overtake_offset, -TRACK_HALF_WIDTH + 1.2, TRACK_HALF_WIDTH - 1.2)
	var target_index := (progress_index + LOOKAHEAD_POINTS) % track_points.size()
	var target_point := _lane_point(target_index, desired_lane)
	var to_target := target_point - global_position
	to_target.y = 0.0
	if to_target.length() > 0.05:
		var desired_yaw := atan2(-to_target.x, -to_target.z)
		rotation.y = lerp_angle(rotation.y, desired_yaw, clamp(delta * 3.8, 0.0, 1.0))

	var speed_multiplier := speed_factor
	if avoid != 0.0:
		speed_multiplier = max(0.62, speed_multiplier - 0.08)
	current_speed = move_toward(current_speed, target_speed * speed_multiplier, 12.0 * delta)
	var forward := -global_transform.basis.z
	global_position += forward * current_speed * delta
	global_position.y = 0.45
	_advance_progress(desired_lane)

func _lane_point(index: int, offset: float) -> Vector3:
	var centre: Vector3 = track_points[index]
	var previous: Vector3 = track_points[(index - 1 + track_points.size()) % track_points.size()]
	var next_point: Vector3 = track_points[(index + 1) % track_points.size()]
	var tangent := (next_point - previous).normalized()
	var lateral := Vector3(-tangent.z, 0.0, tangent.x)
	return centre + lateral * offset + Vector3.UP * 0.45

func _advance_progress(desired_lane: float) -> void:
	var next_index := (progress_index + 1) % track_points.size()
	# Measure against the same offset racing line the AI is actually following.
	var next_point := _lane_point(next_index, desired_lane)
	if global_position.distance_squared_to(next_point) < 12.25:
		if next_index == 0:
			completed_laps += 1
		progress_index = next_index

func _find_nearby_opponent() -> float:
	var chosen_offset := 0.0
	var nearest_distance := 9.0
	var forward := -global_transform.basis.z
	var nearby_cars := get_tree().get_nodes_in_group("ai_cars") + get_tree().get_nodes_in_group("player_car")
	for other in nearby_cars:
		if other == self or not is_instance_valid(other):
			continue
		var offset: Vector3 = other.global_position - global_position
		var distance := offset.length()
		if distance < nearest_distance and distance > 0.1 and forward.dot(offset.normalized()) > 0.25:
			nearest_distance = distance
			# Pick the clearer side deterministically so cars do not all move identically.
			chosen_offset = 3.0 if int(get_instance_id()) % 2 == 0 else -3.0
	return chosen_offset

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("apply_collision"):
		var impact_direction := (body.global_position - global_position).normalized()
		body.apply_collision(impact_direction)
