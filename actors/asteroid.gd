@tool
extends RigidBody2D
class_name Asteroid

const time_before_despawn = 1.0
const SPAWN_IMMUNITY_TIME = 1.0
const DESPAWN_OFF_SCREEN = false
const RESOURCE_CLASS = preload("res://actors/uranium.tscn")

@onready var timer := $Timer
@onready var immunity_timer := $SpawnImmunityTimer
@onready var visibility_notifier := $VisibleOnScreenNotifier2D

@export var preset:AsteroidPreset = preload("res://resources/asteroid_medium.tres") : set = _set_preset
@export_flags_2d_physics var on_screen_collision
@export_flags_2d_physics var off_screen_collision

var current_integrity:float
var resources_remaining:float
var resource_spawn_threshold:float

signal damaged(asteroid, amount, current)
signal destroyed(asteroid)
signal timed_out(asteroid)

func _set_preset(value:AsteroidPreset):
	preset = value
	$CollisionShape2D.shape = preset.collision_shape
	$CollisionShape2D.position = preset.collision_shape_offset
	$Sprite2D.texture = preset.texture
	$VisibleOnScreenNotifier2D.rect = $CollisionShape2D.shape.get_rect()
	$VisibleOnScreenNotifier2D.position = preset.collision_shape_offset
	mass = preset.mass
	current_integrity = preset.max_integrity
	resources_remaining = preset.num_resources
	resource_spawn_threshold = preset.max_integrity / preset.num_resources

func _enter_tree():
	if Engine.is_editor_hint():
		return
		
	request_ready()

func _ready():
	if Engine.is_editor_hint():
		return
		
	if not visibility_notifier.is_on_screen():
		_on_screen_exited()
		start_despawn_timer()
	else:
		_on_screen_entered()
		
	immunity_timer.start(SPAWN_IMMUNITY_TIME)
	
func start_despawn_timer():
	timer.start(time_before_despawn)
	
func stop_despawn_timer():
	timer.stop()

func destroy():
	destroyed.emit(self)
	for i in range(preset.num_resources_on_explode):
		GameManager.spawn_resource(RESOURCE_CLASS, global_position)

func _on_screen_exited():
	if Engine.is_editor_hint():
		return
	
	start_despawn_timer()
	
	collision_layer = off_screen_collision

func _on_screen_entered():
	if Engine.is_editor_hint():
		return
		
	stop_despawn_timer()
	collision_layer = on_screen_collision

func _on_timer_timeout():
	if Engine.is_editor_hint():
		return
	
	if DESPAWN_OFF_SCREEN:
		timed_out.emit(self)	

func _integrate_forces(state:PhysicsDirectBodyState2D):
	if !immunity_timer.is_stopped():
		return 
	if state.get_contact_count() > 0: 
		var contact = state.get_contact_collider_object(0)
		var contact_velocity = state.get_contact_collider_velocity_at_position(0)
		#if contact is PlayerShip: # handled in PlayerShip, just here for readability
		if contact is Asteroid:
			var contact_force = contact_velocity.length() * contact.mass
			#print(contact_force)
			state.get_contact_collider_position(0)
			damage(contact_force * GameManager.DAMAGE_RATIO, state.get_contact_collider_position(0))

func damage(amount:float, impact_point:Vector2):
	current_integrity -= amount
	damaged.emit(self, amount, current_integrity)
	
	var next_resource_threshold = (resources_remaining-1) * resource_spawn_threshold
	while current_integrity <= next_resource_threshold and resources_remaining > 0:
		var surface_direction = impact_point - global_position
		GameManager.spawn_resource(RESOURCE_CLASS, impact_point + (surface_direction.normalized() * 4.0))
		resources_remaining -= 1
		next_resource_threshold -= resource_spawn_threshold
	
	if current_integrity <= 0:
		destroy()

func _on_body_entered(body):
	pass # Replace with function body.
