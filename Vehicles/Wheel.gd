extends Spatial



onready var car = get_parent()
onready var ray = $RayCast
onready var collision_point = $CollisionPoint
onready var wheel_mesh = $WheelMesh
onready var tire_tracks = $TireTrack
export(float) var wheel_radius = 0.35
export(bool) var is_right = false

# Driving
export var is_driving = false
export var power = 25000 # *100

# Steering
export var is_steering = false
export var max_angle = 21.0
var steering_speed = 0.1

# Traction
export var regular_traction = 2000
export var drift_traction = 800
var current_traction = regular_traction

# Drifting
export (float) var drift_velocity = 0.5
export (float) var drift_angle = 0.4

# Suspension
export(float) var force_multiplier = 300000.0 # *25
export(float) var stiffness = 0.25 # 0.45 # Hire means stiffer, more resistance to gravity
export(float) var damping = 1 # higher means less boucning
export(float) var suspension_height = 1.2

var prev_compression = 0.0
var compression = 0.0 # 0 means uncompressed, full height, 1 is completely compressed

# Calculate wheel velocity
onready var last_position = global_transform.origin
onready var linear_velocity = global_transform.origin - last_position
var forward = Vector3()

func _ready():
	ray.cast_to.y = -suspension_height
	ray.add_exception(get_parent())
	if is_right: wheel_mesh.rotation_degrees.y = 180
	# $TireTrack.set_as_toplevel(true)




func _physics_process(delta):
	update_useful_vars()
	steer(delta)
	accelerate(delta)
	drifting()
	traction()


	suspension(delta)
	spin_wheel(delta)
	#tire_tracks.emitting = car.is_drifting
	# $TireTrack.global_transform.origin = global_transform.origin


func steer(delta):
	if not is_steering: return

	var desired_angle = 0
	desired_angle += Input.get_action_strength("left") * max_angle
	desired_angle -= Input.get_action_strength("right") * max_angle
	
	rotation_degrees.y = lerp(rotation_degrees.y, desired_angle, steering_speed)


func accelerate(delta):
	if not is_on_floor(): return
	if not is_driving: return

	var acc_input = Input.get_action_strength("forward") - Input.get_action_strength("back")
	var acc_force = forward * acc_input * power * delta
	
	var car_to_wheel = global_transform.origin - car.global_transform.origin
	car_to_wheel.y = 0
	# car.apply_impulse(car_to_wheel, acc_force)
	car.add_force(acc_force, car_to_wheel)

func traction():
	if not is_on_floor(): return
	var right = global_transform.basis.x
	var lateral_velocity = -linear_velocity.dot(right) * right
	var car_to_wheel = global_transform.origin - car.global_transform.origin
	car_to_wheel.y = 0
	# var vel = clamp(linear_velocity.length(), 0, drift_velocity)
	# current_traction = range_lerp(vel, 0, drift_velocity, regular_traction*2, drift_traction)
	car.add_force(lateral_velocity * current_traction, car_to_wheel)

func drifting():
	var moving_speed = linear_velocity.length()
	var turning_speed = car.linear_velocity.angle_to(-car.global_transform.basis.z)
	# print("moving_speed ", moving_speed, " \t", turning_speed)
	if moving_speed  > drift_velocity and turning_speed > drift_angle or Input.is_action_pressed("drift"): 
		current_traction = lerp(current_traction, drift_traction, 0.1)
		$TireTrack.render = true
	else:
		current_traction = lerp(current_traction, regular_traction, 0.01)
		$TireTrack.render = false
		

func spin_wheel(delta):
	if linear_velocity.dot(forward) > 0: # If I'm moving forward
		wheel_mesh.rotate_x(-linear_velocity.length() * delta * 0.81)
	else:
		wheel_mesh.rotate_x(car.linear_velocity.length() * delta * 0.81)

var prev_impact_point = Vector3()
var prev_impact_normal = Vector3()

func suspension(delta):
	if(ray.is_colliding()):
		prev_compression = compression
		#prev_impact_point = ray.get_collision_point()
		#prev_impact_normal = ray.get_collision_normal()
		# 1 - fully compressed, 0 - no compression, extended at full height
		var ground = ray.get_collision_point()
		var current_height = global_transform.origin.distance_to(ground)
		compression = (suspension_height - current_height)/suspension_height
		# As spring gets more compressed, the force increases
		var spring_force = stiffness * compression
		# Positive if it got shorter, negative if it got longer.
		# Points in the opposite direction of compression change
		var damping_force = damping * (compression - prev_compression)
		var up = car.global_transform.basis.y
		var force = up * (spring_force+damping_force) * force_multiplier * delta
		#print(name, " ", force.length())
		var position = global_transform.origin - car.global_transform.origin
		car.add_force(force, position) # apply force at wheel's position

		#print(compression)
		collision_point.global_transform.origin = ray.get_collision_point()
		wheel_mesh.global_transform.origin = ray.get_collision_point() + Vector3(0,wheel_radius,0)
		# tire_tracks.global_transform.origin  = ray.get_collision_point()  + Vector3(0,0.01,0)
	else:
		wheel_mesh.global_transform.origin = global_transform.origin - global_transform.basis.y + Vector3(0,wheel_radius,0)

func is_on_floor():
	if(ray.is_colliding()): return true
	else: return false

func update_useful_vars():
	# Project forward direction onto the ground, so that if the car is tilted upwards
	# Velocity won't keep pushing it up into the sky
	forward = -global_transform.basis.z 
	forward.y = 0
	forward = forward.normalized()
	
	linear_velocity = global_transform.origin - last_position
	linear_velocity.y = 0
	last_position = global_transform.origin
