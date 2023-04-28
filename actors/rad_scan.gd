extends Node2D
class_name RadiationScanner

@onready var warmup_timer := $WarmupTimer
@onready var warmup_vfx := $Indicator
@onready var scan_vfx := $ActiveScan
@onready var scan_cast := $ScanCast

@export var warmup_time:float = 5.0

signal scan_complete(scan_object, asteroids, player)

var current_camera:Camera2D = null
var offset:Vector2

func _enter_tree():
	request_ready()

func _exit_tree():
	reset()

func _ready():
	var lifetime = max(0.0, warmup_time - 1.0)
	warmup_vfx.emitting = true
	warmup_vfx.amount = round(warmup_time)
	warmup_vfx.lifetime = warmup_time
	warmup_timer.start(warmup_time)
	
	if current_camera == null:
		current_camera = get_tree().get_first_node_in_group("camera")

func _process(_delta):
	pass #position = offset

func reset():
	warmup_vfx.emitting = false
	scan_vfx.emitting = false
	scan_cast.enabled = false
	scan_cast.position = Vector2.ZERO

func _on_warmup_timer_timeout():
	warmup_vfx.emitting = false
	scan_vfx.emitting = true
	
	scan_cast.global_position = current_camera.get_screen_center_position()
	scan_cast.enabled = true
	scan_cast.force_shapecast_update()	
	
	var player_ship:PlayerShip = null
	var scanned_asteroids:Array[Asteroid] = []
	for i in range(scan_cast.get_collision_count()):
		var collider = scan_cast.get_collider(i)
		if collider is PlayerShip:
			if collider.radiation > collider.radiation_blocked_amount:
				player_ship = collider
		elif collider is Asteroid:
			scanned_asteroids.push_back(collider)
			
	scan_complete.emit(self, scanned_asteroids, player_ship)
