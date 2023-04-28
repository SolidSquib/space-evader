extends CharacterBody2D
class_name RailgunRound

@export var speed = 1000.0

var target:Node2D = null

func init(in_target:Node2D) -> RailgunRound:
	target = in_target
	return self
	
func _physics_process(delta):
	if is_instance_valid(target):
		look_at(target.global_position)
		var direction = target.global_position - global_position
		velocity = direction.normalized() * speed
		
	var collision = move_and_collide(velocity * delta)
	if collision:
		if collision.get_collider() == target:
			target = null
		
		if collision.get_collider() is PlayerShip:
			collision.get_collider().damage(1000000)
		elif collision.get_collider() is Asteroid:
			collision.get_collider().damage(1000000, collision.get_position())
			
		


func _on_lifetime_timeout():
	queue_free()
