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

var throttle_input := 0.0
var brake_input := 0.0
var steer_input := 0.0
var controls_enabled := true

func _physics_process(delta: float) -> void:
	if not controls_enabled:
		velocity = Vector3.ZERO
		speed = 0.0
		return
	throttle_input = Input.get_action_strength("accelerate")
	brake_input = Input.get_action_strength("brake")
	steer_input = Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")

	var forward := -global_transform.basis.z
	var side := global_transform.basis.x
	var forward_speed := velocity.dot(forward)
	var side_speed := velocity.dot(side)

	# Braking while moving forward slows the car; braking at a standstill selects reverse.
	if throttle_input > 0.01:
		if forward_speed < -0.5:
			forward_speed = move_toward(forward_speed, 0.0, braking * delta)
		else:
			forward_speed = move_toward(forward_speed, max_speed, acceleration * delta * throttle_input)
	elif brake_input > 0.01:
		if forward_speed > 0.5:
			forward_speed = move_toward(forward_speed, 0.0, braking * delta * brake_input)
		else:
			forward_speed = move_toward(forward_speed, -reverse_speed, acceleration * 0.48 * delta * brake_input)
	else:
		forward_speed = move_toward(forward_speed, 0.0, rolling_resistance * delta)

	# Aerodynamic drag increases with speed. Downforce improves high-speed cornering grip.
	var drag := aerodynamic_drag * forward_speed * forward_speed
	forward_speed = move_toward(forward_speed, 0.0, drag * delta)
	var downforce_grip := min(abs(forward_speed) * 0.055, 4.0)
	var available_grip := lateral_grip + downforce_grip
	side_speed = move_toward(side_speed, 0.0, available_grip * delta)

	# Steering response builds with speed, while very high speed slightly limits yaw rate.
	var speed_ratio := clamp(abs(forward_speed) / 24.0, 0.0, 1.0)
	var steering_authority := lerp(0.22, 1.0, speed_ratio)
	var high_speed_limit := 1.0 / (1.0 + max(abs(forward_speed) - 42.0, 0.0) * 0.018)
	if abs(forward_speed) > 0.8:
		rotation.y -= steer_input * steering_rate * steering_authority * high_speed_limit * delta * sign(forward_speed)

	forward = -global_transform.basis.z
	side = global_transform.basis.x
	velocity.x = forward.x * forward_speed + side.x * side_speed
	velocity.z = forward.z * forward_speed + side.z * side_speed
	velocity.y = -1.0
	speed = abs(forward_speed)
	move_and_slide()

func apply_collision(impact_direction: Vector3) -> void:
	# Basic impact response; detailed damage and deformable physics are future work.
	var impact := impact_direction.normalized()
	velocity.x += impact.x * 9.0
	velocity.z += impact.z * 9.0
	velocity *= 0.72
	rotation.y += 0.12 * sign(impact.x if abs(impact.x) > 0.1 else 1.0)
	speed *= 0.72
