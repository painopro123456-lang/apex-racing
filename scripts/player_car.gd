extends CharacterBody3D

# Arcade-simulation hybrid tuned to remain inexpensive on integrated graphics.
# World units are treated as metres; the HUD converts m/s to km/h.
var speed := 0.0
var max_speed := 88.0
var acceleration := 25.0
var braking := 46.0
var reverse_speed := 11.0
var steering_rate := 1.9
var lateral_grip := 8.5
var rolling_resistance := 1.2
var aerodynamic_drag := 0.0022
var brake_bias := 56.0
var aero_level := 60.0
var front_wing := 60.0
var rear_wing := 60.0
var damage := 0.0
var collision_count := 0
var collision_cooldown := 0.0
var tyre_punctured := false

var throttle_input := 0.0
var brake_input := 0.0
var steer_input := 0.0
var controls_enabled := true
var tyre_compound := "MEDIUM"
var tyre_wear := 100.0
var fuel_remaining := 100.0
var ers_charge := 100.0
var drs_zone := false
var drs_active := false

func _physics_process(delta: float) -> void:
	if not controls_enabled:
		velocity = Vector3.ZERO
		speed = 0.0
		return
	throttle_input = Input.get_action_strength("accelerate")
	brake_input = Input.get_action_strength("brake")
	steer_input = Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
	var ers_requested := Input.is_action_pressed("ers_boost") and ers_charge > 0.5
	drs_active = Input.is_action_pressed("drs") and drs_zone and abs(speed) > 25.0

	var forward := -global_transform.basis.z
	var side := global_transform.basis.x
	var forward_speed := velocity.dot(forward)
	var side_speed := velocity.dot(side)

	# Braking while moving forward slows the car; braking at a standstill selects reverse.
	if throttle_input > 0.01:
		if forward_speed < -0.5:
			forward_speed = move_toward(forward_speed, 0.0, braking * _brake_effectiveness() * delta)
		else:
			var fuel_power: float = clamp(1.0 - damage * 0.0035, 0.62, 1.0)
			var ers_power: float = 8.0 if ers_requested else 0.0
			var speed_cap: float = max_speed + (8.0 if drs_active else 0.0) + ers_power
			forward_speed = move_toward(forward_speed, speed_cap, (acceleration * fuel_power + ers_power * 0.9) * delta * throttle_input)
	elif brake_input > 0.01:
		if forward_speed > 0.5:
			forward_speed = move_toward(forward_speed, 0.0, braking * _brake_effectiveness() * delta * brake_input)
		else:
			forward_speed = move_toward(forward_speed, -reverse_speed, acceleration * 0.48 * delta * brake_input)
	else:
		forward_speed = move_toward(forward_speed, 0.0, rolling_resistance * delta)

	# Aerodynamic drag increases with speed. Downforce improves high-speed cornering grip.
	var drag_factor: float = 0.78 if drs_active else 1.0
	var wing_drag: float = lerp(0.82, 1.35, aero_level / 100.0) * lerp(0.90, 1.16, (front_wing + rear_wing) / 200.0)
	var drag: float = aerodynamic_drag * wing_drag * drag_factor * forward_speed * forward_speed
	forward_speed = move_toward(forward_speed, 0.0, drag * delta)
	var downforce_grip: float = min(abs(forward_speed) * 0.055, 4.0)
	var compound_grip: float = 1.08 if tyre_compound == "SOFT" else (0.92 if tyre_compound == "HARD" else 1.0)
	var wear_grip: float = lerp(0.58, 1.0, tyre_wear / 100.0)
	var wing_grip: float = lerp(0.82, 1.22, (front_wing + rear_wing) / 200.0)
	var damage_grip: float = clamp(1.0 - damage * 0.0028, 0.68, 1.0)
	var puncture_grip: float = 0.52 if tyre_punctured else 1.0
	var available_grip: float = (lateral_grip + downforce_grip) * compound_grip * wear_grip * wing_grip * damage_grip * puncture_grip
	side_speed = move_toward(side_speed, 0.0, available_grip * delta)

	# Steering response builds with speed, while very high speed slightly limits yaw rate.
	var speed_ratio: float = clamp(abs(forward_speed) / 24.0, 0.0, 1.0)
	var steering_authority: float = lerp(0.22, 1.0, speed_ratio)
	var high_speed_limit: float = 1.0 / (1.0 + max(abs(forward_speed) - 42.0, 0.0) * 0.018)
	if abs(forward_speed) > 0.8:
		rotation.y -= steer_input * steering_rate * steering_authority * high_speed_limit * delta * sign(forward_speed)

	forward = -global_transform.basis.z
	side = global_transform.basis.x
	velocity.x = forward.x * forward_speed + side.x * side_speed
	velocity.z = forward.z * forward_speed + side.z * side_speed
	# Keep the car grounded by the track collider while still allowing it to fall if it leaves the road.
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= 24.0 * delta
	speed = abs(forward_speed)
	collision_cooldown = max(0.0, collision_cooldown - delta)
	if ers_requested and throttle_input > 0.05:
		ers_charge = max(0.0, ers_charge - delta * 24.0)
	elif brake_input > 0.05 or forward_speed < 0.0:
		ers_charge = min(100.0, ers_charge + delta * 10.0)
	if abs(forward_speed) > 5.0:
		var wear_rate := 0.045 if tyre_compound == "SOFT" else (0.022 if tyre_compound == "HARD" else 0.032)
		tyre_wear = max(0.0, tyre_wear - abs(forward_speed) * delta * wear_rate)
	move_and_slide()
	if get_slide_collision_count() > 0 and collision_cooldown <= 0.0 and abs(forward_speed) > 4.0:
		for collision_index in range(get_slide_collision_count()):
			var impact_collision := get_slide_collision(collision_index)
			var impact_normal: Vector3 = impact_collision.get_normal()
			# Ignore the road surface; only side impacts against barriers count.
			if abs(impact_normal.y) < 0.65:
				apply_collision(impact_normal)
				collision_cooldown = 0.65
				break

func _brake_effectiveness() -> float:
	# A little more front bias improves stability under braking; excessive bias costs stopping performance.
	return clamp(1.0 - abs(brake_bias - 56.0) * 0.0025, 0.88, 1.0)

func apply_collision(impact_direction: Vector3) -> void:
	# Barrier impacts damage the car; a puncture is possible, never guaranteed.
	var impact_speed: float = velocity.length()
	damage = min(100.0, damage + clamp(impact_speed * 0.22, 5.0, 22.0))
	if not tyre_punctured and impact_speed > 18.0 and randf() < 0.12:
		tyre_punctured = true
	collision_count += 1
	collision_cooldown = 0.65
	var impact := impact_direction.normalized()
	velocity.x += impact.x * 9.0
	velocity.z += impact.z * 9.0
	velocity *= 0.72
	rotation.y += 0.12 * sign(impact.x if abs(impact.x) > 0.1 else 1.0)
	speed *= 0.72
