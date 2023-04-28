extends Node2D
class_name WarningArrow

@onready var warning_timer := $WarningTime
@onready var label := $Label
@onready var rotation_control := $RotationControl

@export var margin:float = 0.0

var target:Node2D = null
var warning_time:float = 3.0
var camera:Camera2D = null

signal warning_timeout

func init(in_target:Node2D, time_to_show:float = 3.0) -> WarningArrow:
	target = in_target
	return self

func _ready():
	warning_timer.start(warning_time)
	camera = get_tree().get_first_node_in_group("camera")

func _process(_delta):
	if warning_timer.is_stopped():
		label.text = "0.0"
	else:
		label.text = str(warning_timer.time_left).pad_decimals(1)
		
	position_warning()
	
		
func position_warning():
	var offset_from_center = target.global_position - camera.get_screen_center_position()
	var half_extents = get_viewport_rect().size * 0.5
	half_extents.x -= margin
	half_extents.y -= margin
	
	var off_v = absf(offset_from_center.y) > absf(half_extents.y)	
	
	var m = half_extents.y / half_extents.x
	
	var final_offset = Vector2(
		clampf(offset_from_center.x, -half_extents.x, half_extents.x),
		clampf(offset_from_center.y, -half_extents.y, half_extents.y)
	)
	
	
	
	global_position = camera.get_screen_center_position() + final_offset
	rotation_control.look_at(target.global_position)
	
	
func _on_warning_time_timeout():
	warning_timeout.emit()
	queue_free()
