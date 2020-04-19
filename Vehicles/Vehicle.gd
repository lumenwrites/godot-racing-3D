extends RigidBody

var engine_force = 2000
var steering_force = 500

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

func _ready():
	linear_damp = 0.6
	angular_damp = 0.8
	gravity_scale = 5

func _physics_process(delta):
	var forward_dir = global_transform.basis.z
	# Project forward direction onto the ground, so that if the car is tilted upwards
	# Velocity won't keep pushing it up into the sky
	forward_dir.y = 0
	forward_dir = forward_dir.normalized()
	
	var acc_force = Vector3()

		
	if Input.is_action_pressed("forward"):
		acc_force = forward_dir * -engine_force * delta
	if Input.is_action_pressed("back"):
		acc_force = forward_dir * engine_force * delta

	#var position = Vector3(0,-0.3, -0.8)# - global_transform.basis.y * 0.3 - global_transform.basis.z * 0.8
	#$Visualizer1.transform.origin = position
	# Apply force below center of gravity, making vehicle tilt backward/forward as you accelerate/break
	add_force(acc_force, Vector3(0, -1.5,-0.3))
	#add_central_force(acc_force)
	steer(delta)
	traction(delta)

func traction(delta):
	var horizontal_vel = linear_velocity * Vector3(1,0,1)
	var forward_dir = (-global_transform.basis.z * Vector3(1,0,1)).normalized()
	# var correction = ??
	# add_central_force(correction)
	
func steer(delta):
	# Horizontal direction of the car, horizontal velocity
	# If they point in the same direction - Im moving forward
	var forward_dir = (-global_transform.basis.z * Vector3(1,0,1)).normalized()
	var velocity_dir = (linear_velocity * Vector3(1,0,1)).normalized()
	var is_moving_forward = velocity_dir.dot(forward_dir) > 0
	if is_moving_forward:
		if Input.is_action_pressed("left"):
			add_torque(Vector3.UP * steering_force * delta)
		if Input.is_action_pressed("right"):
			add_torque(Vector3.UP * -steering_force * delta)
	else:
		if Input.is_action_pressed("left"):
			add_torque(Vector3.UP * -steering_force * delta)
		if Input.is_action_pressed("right"):
			add_torque(Vector3.UP * steering_force * delta)
