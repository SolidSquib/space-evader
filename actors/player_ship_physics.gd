extends RigidBody2D
class_name PlayerShip

@onready var damage_immunity_timer := $DamageImmunityTimer
@onready var tractor_push_vfx := $TractorBeamPush
@onready var tractor_pull_vfx := $TractorBeamPull
@onready var tractor_shape_cast := $TractorShapeCast
@onready var scan_collision := $ScanCollision
@onready var mining_laser := $MiningLaser

@export var turn_speed:float = 1.0
@export var thrust:float = 1.0
@export var max_speed:float = 100.0
@export var max_health:float = 100.0
@export var damage_immunity_period:float = 0.2
@export var tractor_beam_force:float = 100.0
@export var radiation:float = 10.0

var current_health:float
var engines_running:bool = false
var radiation_blocked_amount:float = 0.0

signal damage_taken(damage_amount:float, health_remaining:float)
signal destroyed()
signal collected_resource(resource)

func _ready():
	current_health = max_health
	GameManager.player_ship = self

func _physics_process(delta):
	var input_vector = Vector2(Input.get_axis("strafe_left", "strafe_right"), Input.get_axis("move_forward", "move_back"))	
	constant_force = input_vector.rotated(rotation) * thrust
	constant_torque = Input.get_axis("move_left", "move_right") * turn_speed
	
	var tractor_on_push = Input.is_action_pressed("tractor_push")
	var tractor_on_pull = Input.is_action_pressed("tractor_pull") and not tractor_on_push
	#tractor_push_vfx.emitting = tractor_on_push
	tractor_pull_vfx.emitting = tractor_on_pull
	tractor_shape_cast.enabled = tractor_on_pull #tractor_on_push or tractor_on_pull
	mining_laser.is_casting = tractor_on_push
	
	#if tractor_on_push:
		#apply_tractor_force(delta, true)
	if tractor_on_pull:
		apply_tractor_force(delta, false)
		
	engines_running = input_vector != Vector2.ZERO or tractor_on_pull or tractor_on_push
	
	$ThrusterVFX.emitting = input_vector != Vector2.ZERO
	$ThrusterVFX.look_at(-(constant_force)+global_position)
	
	if Input.is_action_just_pressed("kill_self"):
		destroyed.emit()

func _integrate_forces(state:PhysicsDirectBodyState2D):
	if state.get_contact_count() > 0:
		var contact = state.get_contact_collider_object(0)
		if contact is Asteroid:
			var contact_force = state.get_contact_collider_velocity_at_position(0) * contact.mass
			#print(contact_force)
			damage(contact_force.length() * GameManager.DAMAGE_RATIO)
			
func damage(amount:float) -> void:
	if damage_immunity_timer.is_stopped():
		var damage_amount_actual = min(current_health, amount)
		current_health -= damage_amount_actual
		print("health is %f" % current_health)
		damage_immunity_timer.start(damage_immunity_period)
		damage_taken.emit(damage_amount_actual, current_health)
		if current_health <= 0:
			destroyed.emit()
		else:
			$DamageAudio.play()
		
func apply_tractor_force(delta:float, push:bool):
	var force_direction = (Vector2(0.0, -1.0) if push else Vector2(0.0, 1.0)).rotated(rotation)
	for i in range(tractor_shape_cast.get_collision_count()):
		var collider = tractor_shape_cast.get_collider(i)
		if collider is Uranium:
			collider.target_node = self
		if collider is RigidBody2D:
			collider.apply_central_force(tractor_beam_force * force_direction)

func _on_radiation_distance_body_entered(body):
	if body is Asteroid:
		radiation_blocked_amount += body.preset.radiation_blocked

func _on_radiation_distance_body_exited(body):
	if body is Asteroid:
		radiation_blocked_amount -= body.preset.radiation_blocked

func collect_resource(resource):
	collected_resource.emit(resource)
	$Collection.play()
