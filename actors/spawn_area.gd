@tool
extends Area2D
class_name SpawnArea

@export var area_extents:Vector2 = Vector2 (2800, 2800) : set = _set_extents
@export var vertices:Array[Vector2] = []
@export var spawn_radius:float = 100.0
@export var spawn_locations:Array[Vector2] = []
@export var min_deviation:float = -50.0
@export var max_deviation:float = 50.0

@export_category("debugging")
@export var draw_grid_points:bool = false

var num_triangles = 2
var rng:RandomNumberGenerator = RandomNumberGenerator.new()

func _set_extents(value):
	area_extents = value
	$CollisionShape2D.shape.size = area_extents
	vertices.clear()
	var half_extents = area_extents * 0.5
	vertices.push_back(Vector2(-half_extents.x, -half_extents.y))
	vertices.push_back(Vector2(half_extents.x, -half_extents.y))
	vertices.push_back(Vector2(-half_extents.x, half_extents.y))
	
	vertices.push_back(Vector2(-half_extents.x, half_extents.y))
	vertices.push_back(Vector2(half_extents.x, -half_extents.y))
	vertices.push_back(Vector2(half_extents.x, half_extents.y))
	
	spawn_locations.clear()
	var offset := spawn_radius*2.0
	var num_spawns_x = area_extents.x / offset
	var num_spawns_y = area_extents.y / offset
	for i in range(num_spawns_x):
		for j in range(num_spawns_y):
			spawn_locations.push_back(-half_extents + Vector2(offset*i, offset*j))

func _ready():
	rng.randomize()
	GameManager.spawn_area = self

func _draw():
	if draw_grid_points:
		for i in range(spawn_locations.size()):
			draw_circle(spawn_locations[i],10, Color.MEDIUM_VIOLET_RED)

func get_random_point() -> Vector2:
	var tri_index = rng.randi_range(0, num_triangles-1)
	return get_random_triangle_point(tri_index)

func get_random_triangle_point(tri_index:int) -> Vector2:
	if tri_index >= num_triangles:
		return Vector2.ZERO
		
	var offset = 3 * tri_index
	var a:Vector2 = vertices[0+offset]
	var b:Vector2 = vertices[1+offset]
	var c:Vector2 = vertices[2+offset]
	return a + sqrt(rng.randf()) * (-a + b + rng.randf() * (c - b)) + global_position
	
func get_random_point_along_border(margin:float = 0) -> Vector2:
	var half_extents = Vector2((area_extents.x * 0.5) + (margin*2), (area_extents.y * 0.5) + (margin*2))
	var side_index = rng.randi() % 4
	var ratio = rng.randf_range(-1, 1)
	if side_index == 0 or side_index == 1: # top or bottom
		var magnitude = ratio * half_extents.x
		return Vector2(magnitude, -half_extents.y if side_index == 0 else half_extents.y) + global_position
	elif side_index == 2 or side_index == 3: # left or right
		var magnitude = ratio * half_extents.y
		return Vector2(-half_extents.x if side_index == 2 else half_extents.x, magnitude) + global_position
	else:
		assert(false)
		
	return Vector2.ZERO + global_position
	
func get_free_spawn_points():
	var free_points = []
	
	$ShapeCast2D.shape.radius = spawn_radius
	for point in spawn_locations:
		$ShapeCast2D.global_position = point
		$ShapeCast2D.force_shapecast_update()
		if not $ShapeCast2D.is_colliding():
			free_points.push_back(point)
	
	print("found %d valid spawn points" % free_points.size())
	return free_points
