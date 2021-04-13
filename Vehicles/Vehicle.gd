extends RigidBody

func _input(event):
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

func _ready():
	# The higher the value - the higher the friction
	linear_damp = 0 # 0.4
	angular_damp = 0
	gravity_scale = 5
	# mass = 1000
	# gravity_scale = 1
	


func _physics_process(delta):
	if Input.is_action_just_pressed("jump"):
		apply_central_impulse(Vector3.UP*500)

	# Air resistance
	var velSquared = linear_velocity.length_squared() * linear_velocity.normalized()
	add_central_force(-velSquared*0.15)

	# tilt body for effect
	var steering = Input.get_action_strength("left") - Input.get_action_strength("right")
	var t = -steering * linear_velocity.length() * 0.005
	$Car.rotation.z = lerp($Car.rotation.z, t, 2 * delta)
	
	# steer(delta)
	# kill_orthogonal_velocity()

func steer(delta):
	var steering = Input.get_action_strength("left") - Input.get_action_strength("right")
	add_torque(Vector3(0,steering*100,0))

func kill_orthogonal_velocity():
	var forward = -global_transform.basis.z 
	var right = global_transform.basis.x
	var forward_velocity = forward*linear_velocity.dot(forward)
	var right_velocity = right*linear_velocity.dot(right)
	var drift = 0
	linear_velocity = forward_velocity  + right_velocity * drift
	# car.Velocity = forwardVelocity;
