@tool
extends Node2D
class_name LevelBounds

@onready var top := $Top
@onready var bottom := $Bottom
@onready var left := $Left
@onready var right := $Right
@onready var top_shape := $Top/CollisionShape2D
@onready var bottom_shape := $Bottom/CollisionShape2D
@onready var left_shape := $Left/CollisionShape2D
@onready var right_shape := $Right/CollisionShape2D
@onready var top_sprite := $Top/SpriteTop
@onready var bottom_sprite := $Bottom/SpriteBottom
@onready var left_sprite := $Left/SpriteLeft
@onready var right_sprite := $Right/SpriteRight
@onready var animation_player := $AnimationPlayer

@export var bounds:Vector2 = Vector2(1280, 720)
@export var border_width:float = 20.0

func _ready():
	set_process(Engine.is_editor_hint())
	if not Engine.is_editor_hint():
		setup_border()
		animation_player.play("pulse")
		

func _process(_delta):
	if Engine.is_editor_hint():
		setup_border()


func setup_border():
	var half_border_width = border_width * 0.5
	var half_bounds = bounds * 0.5
	var horizontal_size = Vector2(bounds.x, border_width)
	top.position = Vector2(0.0, -half_bounds.y + half_border_width)		
	top_shape.shape.size = horizontal_size
	top_sprite.texture.size = horizontal_size
	
	bottom.position = Vector2(0.0, half_bounds.y - half_border_width)
	bottom_shape.shape.size = horizontal_size
	bottom_sprite.texture.size = horizontal_size
	
	var vertical_size = Vector2(border_width, bounds.y)
	left.position = Vector2(-half_bounds.x + half_border_width, 0.0)
	left_shape.shape.size = vertical_size
	left_sprite.texture.size = vertical_size
	
	right.position = Vector2(half_bounds.x - half_border_width, 0.0)
	right_shape.shape.size = vertical_size
	right_sprite.texture.size = vertical_size


func _on_body_entered(body):
	if body is PlayerShip:
		body.damage(10000000.0)
	elif body is Asteroid:
		body.damage(10000000.0, body.global_position)
	else:
		body.queue_free.call_deferred()
