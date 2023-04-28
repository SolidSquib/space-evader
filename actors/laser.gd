extends Node2D
class_name Laser

const laser_length:float = 1500.0

@onready var animation_player := $AnimationPlayer
@onready var laser_layer := $CanvasModulate
@onready var laser_collision := $LaserCollision

@export var laser_width:float = 1.0
@export var follow_speed:float = 100.0

var target_vector:Vector2 = Vector2.ZERO
var target_node:Node2D = null

func init(width:float, target_location:Vector2, follow_target:Node2D = null) -> Laser:
	laser_width = width
	target_vector = target_location
	target_node = follow_target
	return self
	
func _ready():
	look_at(target_vector)
	laser_layer.apply_scale(Vector2(laser_width, laser_length))
	laser_collision.shape.size = Vector2(laser_width, laser_length)
	laser_collision.position = Vector2(laser_length/2, 0.0)
	animation_player.play("indicate")

func _process(delta):
	if target_node:
		target_vector = target_vector.move_toward(target_node.global_position, delta * follow_speed)
		look_at(target_vector)

func _on_animation_player_animation_finished(anim_name):
	match anim_name:
		"indicate":
			animation_player.play("fire_start")
		"fire_start":
			animation_player.play("fire_end")
			process_laser()
		"fire_end":
			queue_free()

func process_laser():
	pass
