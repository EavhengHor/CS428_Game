extends Node2D

@onready var video_player = $VideoStreamPlayer
# 1. Grab the audio player node
@onready var audio_player = $AudioStreamPlayer 

func _ready():
	# 2. Command both the video and the audio to start playing at the same time
	video_player.play()
	audio_player.play()
	
	# Wait for the .ogv video to reach the very end
	await video_player.finished
	
	# Teleport directly to Level 1
	get_tree().change_scene_to_file("res://Levels/Level_1/level_1.tscn")
