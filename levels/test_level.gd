extends Node2D

@onready var dummy := $Dummy

@export_category("spawn area")
@export var spawn_area_margin:float = 0.0
@export var num_points_to_spawn:int = 10

var spawned_points:Array[Vector2] = []

func _ready():
	spawn_area_points()
		
func _draw():
	for i in range(spawned_points.size()):
		draw_circle(spawned_points[i], 10, Color.MEDIUM_VIOLET_RED)

func _process(_delta):
	if Input.is_physical_key_pressed(KEY_0):
		spawn_area_points()
	if Input.is_action_just_pressed("tractor_push"):
		spawn_beacon()
		
func spawn_area_points():
	spawned_points.clear()
	for i in range(num_points_to_spawn):
		spawned_points.push_back(%SpawnArea.get_random_point_along_border(spawn_area_margin))
	queue_redraw()
	
func spawn_beacon():
	GameManager.request_random_spawn_scan_beacon(dummy)
	
