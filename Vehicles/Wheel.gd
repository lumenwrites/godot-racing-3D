extends Spatial

export(float) var ForcePower = 300.0
export(float) var Stiffness = 0.1
export(float) var Damping = 0.1
export(float) var HoverHeight = 1.0


var ForceToAdd = Vector3()
var Displacement = 0.0
var PrevDisplacement = 0.0
var Speed = 0.0

onready var car = get_parent()
onready var ray = $RayCast
onready var collision_point = $CollisionPoint


func _ready():
	ray.cast_to.y = -HoverHeight
	ray.add_exception(get_parent())

func _physics_process(Delta):
	if(ray.is_colliding()):
		collision_point.show()
		PrevDisplacement = Displacement
		#Displacement = (ray.cast_to - global_transform.xform_inv(ray.get_collision_point())).length()
		Displacement = HoverHeight - global_transform.origin.distance_to(ray.get_collision_point())
		Speed = (Displacement - PrevDisplacement) / Delta
		var SpringForce = car.gravity_scale * car.weight * Stiffness * Displacement
		var DampingForce = Damping * Speed # Makes spring stop bouncing?
		ForceToAdd = clamp(SpringForce + DampingForce, 0, 50)
		collision_point.global_transform.origin = ray.get_collision_point()

		var force = car.global_transform.basis.y * ForceToAdd * Delta * ForcePower
		var position = global_transform.origin - car.global_transform.origin
		car.add_force(force, position)
	else:
		collision_point.hide()
	



#	PrevDisplacement = Displacement
#	Displacement = (ray.cast_to - global_transform.xform_inv(ray.get_collision_point())).length()
#	Speed = (Displacement - PrevDisplacement) / Delta
#	var SpringForce = car.gravity_scale * car.weight * Stiffness * Displacement
#	var DampingForce = Damping * Speed
#	ForceToAdd = Vector3.UP * clamp(SpringForce + DampingForce, 0, 50)
#
#	# Apply force to the car at the position of the wheel
#	var force = car.global_transform.basis.xform(ForceToAdd * Delta * ForcePower)
#	var position = global_transform.origin - car.global_transform.origin
#	car.add_force(force, position)
#











