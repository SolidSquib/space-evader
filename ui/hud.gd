extends Control

@onready var healthbar := $HealthBar
@onready var score_label := $Score/ScoreLabel
@onready var hiscores := $HiScoresContainer
@onready var score_box := $HiScoresContainer/ScoreBox
@onready var hiscore_panel := $HiScorePanel
@onready var hiscore_text_edit := $HiScorePanel/MarginContainer/VBoxContainer/HiscoreName
@onready var button_container := $ButtonContainer
@onready var beacon_indicator := $BeaconIndicator
@onready var animation_player := $AnimationPlayer
@onready var weapon_lock := $WeaponLock


var player_node:PlayerShip
var cached_text:String
var cursor_line = 0
var cursor_column = 0
var active_beacons:Array = []

func _ready():
	player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		player_node.connect("damage_taken", _on_damage_taken)
		player_node.connect("destroyed", _on_ship_destroyed)
	healthbar.value = 1.0
	
	GameManager.connect("score_changed", _on_score_changed)
	GameManager.connect("show_hiscores", _on_show_hiscores)
	GameManager.connect("new_beacon", _on_new_beacon)
	
func _on_damage_taken(amount:float, remaining:float) -> void:
	healthbar.value = remaining / player_node.max_health

func _on_ship_destroyed():
	player_node = null
	weapon_lock.visible = false

func _on_score_changed(score):
	score_label.text = str(score).pad_zeros(10)
	
func _on_show_hiscores(prompt_new_score:bool):
	if prompt_new_score:
		hiscore_text_edit.text = ""
		hiscore_text_edit.caret_column = 0
		hiscore_panel.visible = true
		GameManager.block_restart = true
	else:
		populate_and_show_hiscores()

func _on_new_beacon(beacon) -> void:
	if player_node == null:
		return
		
	print ("received beacon created")
	beacon.connect("deactivate", _on_beacon_destroyed)
	beacon.connect("target_detected", _on_beacon_target_detected)
	active_beacons.push_back(beacon)
	beacon_indicator.visible = true
	if not weapon_lock.visible:
		animation_player.play("scan_incoming")
	
func _on_beacon_destroyed(beacon) -> void:
	print ("received beacon destroyed")
	var index = active_beacons.find(beacon)
	if index >= 0 and index < active_beacons.size():
		active_beacons.remove_at(index)
	if active_beacons.size() == 0:
		beacon_indicator.visible = false
		print ("hide warning")
		
func _on_beacon_target_detected(beacon, target) -> void:
	weapon_lock.visible = true
	animation_player.play("weapon_lock")

func _on_submit_hiscore_button_pressed():
	GameManager.submit_current_score(hiscore_text_edit.text)
	hiscore_panel.visible = false
	populate_and_show_hiscores()


func _on_hiscore_name_text_changed(new_text):
	hiscore_text_edit.text = new_text.strip_edges(true, true)
	hiscore_text_edit.caret_column = hiscore_text_edit.text.length()
	
func populate_and_show_hiscores():
	for i in range(GameManager.hiscores.size()):
		var name = GameManager.hiscore_holders[i]
		var score = GameManager.hiscores[i]
		var name_label = score_box.get_child(i).get_child(0)
		var score_label = score_box.get_child(i).get_child(1)
		name_label.text = name
		score_label.text = str(score).pad_zeros(10)
	hiscores.visible = true
	button_container.visible = true
	GameManager.block_restart = false


func _on_restart_button_pressed():
	$PressSound.play()
	GameManager.restart_quick()


func _on_quit_button_pressed():
	GameManager.load_scene(GameManager.menu_scene)


func _on_button_mouse_entered():
	$HoverSound.play()
