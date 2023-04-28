extends Node2D

@onready var explosion_vfx := $ExplosionVFX

func _ready():
	explosion_vfx.emitting = true
	await get_tree().create_timer(6).timeout
	queue_free()
