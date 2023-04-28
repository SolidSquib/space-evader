extends RigidBody2D
class_name Uranium

@export var follow_speed:float = 200.0
@export var value:int = 1

var target_node:Node2D = null : set = _set_target_node

func _set_target_node(value):
	target_node = value
	# play some juicy audio

func _physics_process(delta):
	if is_instance_valid(target_node):
		var direction_to_target = target_node.global_position - global_position
		apply_central_force(direction_to_target.normalized() * follow_speed)
	
func _on_pickup_radius_body_entered(body):
	if body is PlayerShip:
		target_node = body

func _on_absorb_radius_body_entered(body):
	if body is PlayerShip:
		body.collect_resource(self)
		queue_free()
