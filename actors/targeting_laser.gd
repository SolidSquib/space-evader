extends RayCast2D
class_name TargetingLaser

@onready var line := $Line2D
@onready var casting_vfx := $CastingVFX
@onready var beam_vfx := $BeamVFX
@onready var safety_net := $SafetyNet

@export var beam_width:float = 3.0
@export var max_length:float = 5000.0
@export var cooldown:float = 0.1
@export var damage:float = 1.0
@export var color:Color = Color.DARK_RED

var is_casting:bool = false : set = _set_is_casting
var active_tween:Tween
var color_tween:Tween
var color_tween_time:float
var current_length:float
var target
var target_locked:bool = false

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
		disappear()

func _ready():
	set_physics_process(false)
	line.points[1] = Vector2.ZERO
	target_position = Vector2(max_length, 0.0)

func _physics_process(_delta):
	var cast_point := target_position
	force_raycast_update()
	
	if is_colliding():
		cast_point = to_local(get_collision_point())
	
	if is_instance_valid(target) and get_collider() == target:
		if safety_net.is_stopped():
			safety_net.start(1.0)
	else:
		target_locked = false
		safety_net.stop()
	
	line.points[1] = cast_point
	beam_vfx.position = cast_point * 0.5
	beam_vfx.process_material.emission_box_extents.x = cast_point.length() * 0.5

func appear() -> void:
	if is_instance_valid(active_tween):
		active_tween.stop()
		
	if is_instance_valid(color_tween):
		color_tween.stop()
		
	active_tween = get_tree().create_tween()
	active_tween.tween_property(line, "width", beam_width, 0.5)
	
	color_tween = get_tree().create_tween()
	color_tween.tween_property(self, "modulate", Color.DARK_RED, color_tween_time)
	
func disappear() -> void:
	if is_instance_valid(active_tween):
		active_tween.stop()
		
	if is_instance_valid(color_tween):
		color_tween.stop()
		
	active_tween = get_tree().create_tween()
	active_tween.tween_property(line, "width", 0.0, 0.3)
	
	color_tween = get_tree().create_tween()
	color_tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3)


func _on_safety_net_timeout():
	target_locked = true
