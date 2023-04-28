extends RayCast2D
class_name MiningLaser

@onready var line := $Line2D
@onready var casting_vfx := $CastingVFX
@onready var collision_vfx := $CollisionVFX
@onready var beam_vfx := $BeamVFX
@onready var cooldown_timer := $CooldownTimer

@export var beam_width:float = 3.0
@export var max_length:float = 100.0
@export var cooldown:float = 0.1
@export var damage:float = 1.0

var is_casting:bool = false : set = _set_is_casting
var active_tween:Tween

func _set_is_casting(value):
	if is_casting == value:
		return 
		
	is_casting = value
	set_physics_process(is_casting)
	casting_vfx.emitting = is_casting
	beam_vfx.emitting = is_casting
	
	if is_casting:		
		appear()
	else:
		collision_vfx.emitting = false
		disappear()

func _ready():
	set_physics_process(false)
	line.points[1] = Vector2.ZERO
	target_position = Vector2(max_length, 0.0)

func _physics_process(_delta):
	var cast_point := target_position
	force_raycast_update()
	
	collision_vfx.emitting = is_colliding()
	
	if is_colliding():
		cast_point = to_local(get_collision_point())		
		collision_vfx.global_rotation = get_collision_normal().angle()
		collision_vfx.position = cast_point
		
		if cooldown_timer.is_stopped():
			if get_collider().has_method("damage"):
				get_collider().damage(damage, get_collision_point())
				cooldown_timer.start(cooldown)
		
	line.points[1] = cast_point
	beam_vfx.position = cast_point * 0.5
	beam_vfx.process_material.emission_box_extents.x = cast_point.length() * 0.5

func appear() -> void:
	if is_instance_valid(active_tween):
		active_tween.stop()
		
	active_tween = get_tree().create_tween()
	active_tween.tween_property(line, "width", beam_width, 0.2)
	#active_tween.start()
	
func disappear() -> void:
	if is_instance_valid(active_tween):
		active_tween.stop()
		
	active_tween = get_tree().create_tween()
	active_tween.tween_property(line, "width", 0.0, 0.2)
	#active_tween.start()
