extends Node2D
class_name ScanBeacon

@onready var targeting_laser := $TargetingLaser
@onready var indicator_laser := $TargetingLaser/Indicator
@onready var railgun_timer := $RailgunTimer


const warning_arrow_class = preload("res://actors/warning_arrow.tscn")
const railgun_round_class = preload("res://actors/railgun_round.tscn")

@export var fire_delay = 3.0

var target:Node2D = null
var countdown:float = 3.0

signal deactivate(beacon)
signal target_detected(beacon, target)

func init(in_target:Node2D, in_countdown:float = 3.0) -> ScanBeacon:
	target = in_target
	countdown = in_countdown	
	return self

func _ready():
	targeting_laser.target = target
	
	if countdown > 0.0:
		var warning = warning_arrow_class.instantiate().init(self, countdown)
		warning.connect("warning_timeout", _on_warning_timeout)
		get_tree().current_scene.add_child.call_deferred(warning)
		warning.global_position = global_position
	else:
		do_scan()
	
	targeting_laser.color_tween_time = countdown
	targeting_laser.is_casting = true
	
	indicator_laser.color_tween_time = 0.5
	indicator_laser.is_casting = true
	

func _process(_delta):
	if is_instance_valid(target): 
		look_at(target.global_position)
	indicator_laser.position = targeting_laser.target_position

func _on_warning_timeout():
	do_scan()
		
func do_scan():
	if targeting_laser.is_colliding() and targeting_laser.target_locked:# and targeting_laser.get_collider() is PlayerShip:
		target_detected.emit(self, targeting_laser.get_collider())
		start_firing()
	else:
		targeting_laser.is_casting = false
		indicator_laser.is_casting = false
		deactivate.emit(self)
		await get_tree().create_timer(0.5).timeout
		queue_free()
		
		
func start_firing():
	railgun_timer.start(fire_delay)


func _on_railgun_timer_timeout():
	if is_instance_valid(target):
		var railgun = railgun_round_class.instantiate().init(target)
		get_tree().current_scene.add_child.call_deferred(railgun)
		railgun.global_position = global_position
	
	await get_tree().create_timer(3.0).timeout
	
	if is_instance_valid(target): # fire again, to be sure
		railgun_timer.start(fire_delay)
