extends Control

@onready var hiscores := $HiScoresContainer
@onready var score_box := $HiScoresContainer/ScoreBox


func _ready():
	GameManager.start_menu()
	populate_and_show_hiscores()


func _on_start_button_pressed():
	$PressSound.play()
	get_tree().change_scene_to_packed(GameManager.game_scene)
	


func _on_exit_button_pressed():
	$PressSound.play()	
	await get_tree().create_timer(0.5).timeout	
	GameManager.quit()


func populate_and_show_hiscores():
	for i in range(GameManager.hiscores.size()):
		var name = GameManager.hiscore_holders[i]
		var score = GameManager.hiscores[i]
		var name_label = score_box.get_child(i).get_child(0)
		var score_label = score_box.get_child(i).get_child(1)
		name_label.text = name
		score_label.text = str(score).pad_zeros(10)
	hiscores.visible = true


func _on_button_mouse_entered():
	$HoverSound.play()
