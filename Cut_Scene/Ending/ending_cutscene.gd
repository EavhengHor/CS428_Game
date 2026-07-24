extends Node2D

@onready var video_player = $VideoStreamPlayer

func _ready() -> void:
	video_player.play()
	await video_player.finished
	
	print("Video finished! Returning to main menu...")
	# Updated to match your exact file path!
	get_tree().change_scene_to_file("res://UI/start_ui.tscn")
