extends Node2D
class_name AsteroidSpawner

const asteroid_class = preload("res://actors/Asteroid.tscn")
const laser_class = preload("res://actors/laser.tscn")

const NUM_RAD_SCANS_TO_POOL = 3

@onready var path := $Path2D
@onready var path_follow := $Path2D/PathFollow2D
@onready var spawn_point := $Path2D/PathFollow2D/SpawnLocation
@onready var spawn_delay_timer := $SpawnDelay
@onready var beacon_spawn_delay_timer := $BeaconSpawnDelay

@export_category("Object Pooling")
@export var initial_pool_size:int = 100

@export_category("Spawn Areas")
@export var camera_margin:float = 20.0
@export var spawn_area:SpawnArea = null

@export_category("Curves")
@export var max_time:float = 300
@export var asteroid_spawn_chance_curve:Curve
@export var beacon_spawn_frequency_curve:Curve

@export_category("Asteroid Spawns")
@export var spawn_weights:Dictionary = { 
	preload("res://resources/asteroid_tiny.tres"): 1.0,
	preload("res://resources/asteroid_small.tres"): 1.0,
	preload("res://resources/asteroid_medium.tres"): 2.0,
	preload("res://resources/asteroid_large.tres"): 1.0
}
@export var spawn_group_size:int = 5
@export var initial_spawn_amount:int = 20
@export var spawn_delay_min:float = 0.5
@export var spawn_delay_max:float = 1.5

@export_category("Beacon Spawns")
@export var beacon_initial_spawn_delay:float = 5
@export var beacon_spawn_delay_min:float = 3
@export var beacon_spawn_delay_max:float = 5

var pooled_asteroids:Array[Asteroid]
var total_spawn_weight:float = 0.0
var rng:RandomNumberGenerator = RandomNumberGenerator.new()
var repeat_spawns = true

func _enter_tree():
	GameManager.asteroid_spawner = self

func _ready():
	var viewport = get_viewport_rect()	
	var half_width = viewport.size.x/2
	var half_height = viewport.size.y/2
	path.curve.clear_points()
	path.curve.add_point(Vector2(-half_width-camera_margin, -half_height-camera_margin))
	path.curve.add_point(Vector2(half_width+camera_margin, -half_height-camera_margin))
	path.curve.add_point(Vector2(half_width+camera_margin, half_height+camera_margin))
	path.curve.add_point(Vector2(-half_width-camera_margin, half_height+camera_margin))
	path.curve.add_point(Vector2(-half_width-camera_margin, -half_height-camera_margin))
	
	for n in range(max(initial_spawn_amount, initial_pool_size)):
		_add_asteroid_to_pool()
		
	total_spawn_weight = 0
	for key in spawn_weights:
		total_spawn_weight += spawn_weights[key]
		
	for i in range(initial_spawn_amount):
		spawn_at_random_point_in_area()
	
	spawn_delay_timer.start(rng.randf_range(spawn_delay_min, spawn_delay_max))
	beacon_spawn_delay_timer.start(beacon_initial_spawn_delay)
	

func _add_asteroid_to_pool():
	var asteroid = asteroid_class.instantiate()
	asteroid.connect("destroyed", _on_asteroid_destroyed)
	asteroid.connect("damaged", _on_asteroid_damaged)
	asteroid.connect("timed_out", _on_asteroid_timed_out)
	pooled_asteroids.push_back(asteroid)
	
func _process(delta):
	global_rotation = 0

func _on_asteroid_destroyed(asteroid:Asteroid):
	var center = asteroid.global_position
	var radius = asteroid.preset.texture.get_width() / 2
	var fragments = asteroid.preset.child_presets
	return_to_pool.call_deferred(asteroid)
	var random_angle = rng.randf_range(1.0, 360.0)
	for i in range(fragments.size()):
		var point = i * (360/fragments.size())
		point += random_angle
		var spawn_location = center+Vector2(cos(deg_to_rad(point)), sin(deg_to_rad(point))) * radius
		var break_off_direction = center - spawn_location
		spawn_at(spawn_location, fragments[i], break_off_direction.normalized())
	#$AsteroidDestroyed.global_position = asteroid.global_position	
	#$AsteroidDestroyed.play()
	
func _on_asteroid_damaged(asteroid:Asteroid, amount:float, remaining:float):
	#$AsteroidDamaged.global_position = asteroid.global_position
	#$AsteroidDamaged.play()
	pass
	
func _on_asteroid_timed_out(asteroid):
	return_to_pool.call_deferred(asteroid)
		
func return_to_pool(asteroid):
	get_tree().current_scene.remove_child(asteroid)
	pooled_asteroids.push_back(asteroid)

func spawn_at_random_point_in_area():
	const min_dist_from_player_sqr:float = 300*300
	
	var spawn_location = spawn_area.get_random_point()
	while spawn_location.distance_squared_to(global_position) < min_dist_from_player_sqr:
		spawn_location = spawn_area.get_random_point()
	spawn_at(spawn_location)

func spawn_all_grid_cells(chance:float = 1.0):
	const min_dist_from_player_sqr:float = 300*300
	var locations = spawn_area.get_free_spawn_points()
	for i in range(locations.size()):
		var should_spawn = rng.randf_range(0.0, 1.0) <= chance
		var spawn_location = locations[i] + Vector2(
			rng.randf_range(spawn_area.min_deviation, spawn_area.max_deviation),
			rng.randf_range(spawn_area.min_deviation, spawn_area.max_deviation)
		)
		if should_spawn and spawn_location.distance_squared_to(global_position) >= min_dist_from_player_sqr:
			spawn_at(spawn_location)

func spawn_at(location:Vector2, preset:AsteroidPreset = null, direction:Vector2 = Vector2.ZERO):
	if pooled_asteroids.size() == 0:
		_add_asteroid_to_pool()
		print("Adding new asteroid to pool")
			
	var asteroid = pooled_asteroids.pop_back()
	
	var spawn_preset = preset if preset != null else get_random_asteroid_preset()
	asteroid._set_preset(spawn_preset)
		
	get_tree().current_scene.add_child.call_deferred(asteroid)
	asteroid.global_position = location
	asteroid.rotation = rng.randf_range(0, 2*PI)
	
	if direction != Vector2.ZERO:
		asteroid.linear_velocity = direction * rng.randf_range(spawn_preset.min_spawn_velocity, spawn_preset.max_spawn_velocity)
	else:
		asteroid.linear_velocity = Vector2(
			rng.randf_range(spawn_preset.min_spawn_velocity, spawn_preset.max_spawn_velocity), 
			rng.randf_range(spawn_preset.min_spawn_velocity, spawn_preset.max_spawn_velocity)
			)
		
	asteroid.angular_velocity = rng.randf_range(spawn_preset.min_spawn_spin, spawn_preset.max_spawn_spin)	

func spawn_on_screen(count:int = 1):
	var viewport_rect = get_viewport_rect()	
	var half_width = viewport_rect.size.x / 2
	var half_height = viewport_rect.size.y / 2
	var min = global_position + Vector2(-half_width, -half_height)
	var max = global_position + Vector2(half_width, half_height)
	for n in range(count):
		var spawn_location = Vector2(
			rng.randf_range(min.x, max.x),
			rng.randf_range(min.y, max.y)
			);
		spawn_at(spawn_location)
		
	
func spawn_off_screen(count:int = 1):
	for n in range(count):
		path_follow.progress_ratio = rng.randf_range(0, 1)
		spawn_at(spawn_point.global_position)
	
func get_random_asteroid_preset() -> AsteroidPreset:
	var roll = rng.randf_range(0, total_spawn_weight)
	for key in spawn_weights:
		roll -= spawn_weights[key]
		if roll <= 0:
			return key
			
	return null
	
	
func spawn_laser_at(location:Vector2, target:Node2D, width:float, follow:bool):
	var laser = laser_class.instantiate().init(width, target.global_position, target if follow else null)
	add_child(laser)
	laser.global_position = location


func _on_spawn_delay_timeout():
	var time = GameManager.get_time_since_game_start() / max_time
	if repeat_spawns:
		spawn_all_grid_cells(asteroid_spawn_chance_curve.sample(time))
		spawn_delay_timer.start(rng.randf_range(spawn_delay_min, spawn_delay_max))


func _on_beacon_spawn_delay_timeout():	
	GameManager.request_random_spawn_scan_beacon()
	
	if repeat_spawns:
		var time = GameManager.get_time_since_game_start() / max_time
		var next_delay = beacon_spawn_frequency_curve.sample(time) * rng.randf_range(beacon_spawn_delay_min, beacon_spawn_delay_max)
		beacon_spawn_delay_timer.start(next_delay)
