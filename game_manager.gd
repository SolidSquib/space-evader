extends Node

enum GameState { Menu, Game }
var state = GameState.Game

const laser_class = preload("res://actors/laser.tscn")
const EXPLOSION_CLASS = preload("res://actors/explosion.tscn")
const SCAN_BEACON_CLASS = preload("res://actors/scan_beacon.tscn")

const DAMAGE_RATIO:float = 0.1
const KEEP_NUM_SCORES:int = 10

const game_scene = preload("res://levels/Space.tscn")
const menu_scene = preload("res://levels/main_menu.tscn")

var leaderboard:ConfigFile = ConfigFile.new()
var hiscores = []
var hiscore_holders = []
var sound_man:AudioStreamPlayer = null

var asteroid_spawner:AsteroidSpawner
var player_ship:PlayerShip : set = _set_player_ship
var spawn_area:SpawnArea
var current_score:int = 0.0 : set = _set_current_score
var block_shortcuts:bool = false
var block_restart:bool = false
var current_game_start_time

signal score_changed(score)
signal show_hiscores(prompt_new_score)
signal new_beacon(beacon)

func get_spawn_area():
	return get_tree().get_first_node_in_group("spawn_area")

func _enter_tree():
	var err = leaderboard.load("user://scores.cfg")
	if err != OK:
		for i in range(KEEP_NUM_SCORES):
			hiscore_holders.push_back("???")
			hiscores.push_back(0)
	else:
		hiscore_holders = leaderboard.get_value("hiscores", "names")
		hiscores = leaderboard.get_value("hiscores", "scores")
		
	sound_man = AudioStreamPlayer.new()
	get_tree().root.add_child.call_deferred(sound_man)

func _set_player_ship(ship):
	if is_instance_valid(player_ship):
		player_ship.disconnect("collected_resource", _on_player_collected_resource)
		player_ship.disconnect("destroyed", _on_player_destroyed)
		
	player_ship = ship
	
	if is_instance_valid(player_ship):
		player_ship.connect("collected_resource", _on_player_collected_resource)
		player_ship.connect("destroyed", _on_player_destroyed)

func _set_current_score(value):
	current_score = value
	score_changed.emit(current_score)

func _process(_delta):
	if block_shortcuts:
		return 
		
	match(state):
		GameState.Game:
			if Input.is_action_just_pressed("quit"):
				load_scene(menu_scene)
			if Input.is_action_just_pressed("restart") and not block_restart:
				restart_quick()
		GameState.Menu:
			if Input.is_action_just_pressed("quit"):
				quit()

func _on_player_collected_resource(resource):
	current_score += resource.value

func _on_player_destroyed():
	player_ship.visible = false
	var explosion = EXPLOSION_CLASS.instantiate()
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = player_ship.global_position
	
	asteroid_spawner.repeat_spawns = false
	
	await get_tree().physics_frame
	
	player_ship.queue_free()
	player_ship = null
	
	block_shortcuts = true
	await get_tree().create_timer(3).timeout
	show_hiscores.emit(get_score_rank(current_score) >= 0)
	block_shortcuts = false
	
func restart_quick():
	current_score = 0
	asteroid_spawner = null
	player_ship = null
	get_tree().reload_current_scene()
	
func spawn_resource(resource_class:PackedScene, location:Vector2):
	var resource = resource_class.instantiate()
	get_tree().current_scene.add_child.call_deferred(resource)
	resource.global_position = location
	
	
func request_random_spawn_scan_beacon(optional_target:Node2D = null):
	var beacon = SCAN_BEACON_CLASS.instantiate().init(optional_target if optional_target != null else player_ship, 3.0)
	get_tree().current_scene.add_child.call_deferred(beacon)
	beacon.global_position = spawn_area.get_random_point_along_border(250.0)
	new_beacon.emit(beacon)
	
	
func get_score_rank(score:int) -> int:
	var rank = -1
	for i in range(hiscores.size()):
		var score_index = KEEP_NUM_SCORES - i - 1
		var ranked_score = hiscores[score_index]
		if score > ranked_score:
			rank = score_index
	
	if rank > -1:
		return rank
	elif hiscores.size() < KEEP_NUM_SCORES:
		return hiscores.size() + 1
	return rank

func submit_current_score(name:String):
	submit_score(name, current_score)

func submit_score(name:String, score:int):
	var rank = get_score_rank(score)
	
	if rank > -1:
		hiscores.insert(rank, score)
		hiscore_holders.insert(rank, name)
		
		hiscores.pop_back()
		hiscore_holders.pop_back()
		
		leaderboard.set_value("hiscores", "names", hiscore_holders)
		leaderboard.set_value("hiscores", "scores", hiscores)
		leaderboard.save("user://scores.cfg")

func start_game():
	state = GameState.Game
	current_game_start_time = Time.get_ticks_msec()
	
func start_menu():
	state = GameState.Menu
	
func load_scene(scene:PackedScene):
	get_tree().change_scene_to_packed(scene)
	
func quit():
	get_tree().quit()

func play_sound_2d(sound:AudioStream):
	var fire_and_forget
	sound_man.stream = sound
	sound_man.play()
	
func get_time_since_game_start() -> float:
	return (float(Time.get_ticks_msec()) - current_game_start_time) / 1000.0
