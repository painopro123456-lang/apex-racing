extends CharacterBody3D

var speed := 0.0
var max_speed := 78.0
var acceleration := 31.0
var braking := 58.0
var steering_rate := 1.55

func _physics_process(delta: float) -> void:
	var throttle := Input.get_action_strength("accelerate")
	var brake_value := Input.get_action_strength("brake")
	var steer := Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
	speed += throttle * acceleration * delta
	speed -= brake_value * braking * delta
	if throttle < 0.01 and brake_value < 0.01:
		speed = move_toward(speed, 0.0, 4.5 * delta)
	speed = clamp(speed, -10.0, max_speed)
	var steering_factor := clamp(abs(speed) / 20.0, 0.1, 1.0)
	rotation.y -= steer * steering_rate * steering_factor * delta * sign(speed if abs(speed) > 0.1 else 1.0)
	var forward := -global_transform.basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	velocity.y = -1.0
	move_and_slide()
