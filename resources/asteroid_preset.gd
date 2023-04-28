extends Resource
class_name AsteroidPreset

@export var collision_shape:Shape2D
@export var collision_shape_offset:Vector2
@export var texture:Texture2D
@export var child_presets:Array[AsteroidPreset]
@export var mass:float = 1.0
@export var max_integrity:float = 100.0
@export var num_resources:int = 10
@export var num_resources_on_explode = 4
@export var radiation_blocked:float = 5.0
@export var min_spawn_velocity:float = -50
@export var max_spawn_velocity:float = 50
@export var min_spawn_spin:float = -1
@export var max_spawn_spin:float = 1
