extends CanvasLayer

@onready var resume_button = $PauseUI/PausePanel/MarginContainer/VBoxContainer/ResumeButton
@onready var mute_button = $PauseUI/PausePanel/MarginContainer/VBoxContainer/MuteButton
@onready var save_title_button = $PauseUI/PausePanel/MarginContainer/VBoxContainer/SaveTitleButton

var is_muted : bool = false

func _ready() -> void:
	# Hide the pause screen when the game starts
	hide()
	
	# Connect button signals
	resume_button.pressed.connect(_on_resume_pressed)
	mute_button.pressed.connect(_on_mute_pressed)
	save_title_button.pressed.connect(_on_save_title_pressed)

func _unhandled_input(event: InputEvent) -> void:
	# "ui_cancel" is automatically mapped to the Esc key in Godot
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_mute_pressed() -> void:
	is_muted = not is_muted
	
	# Find the Master audio bus and toggle its mute state
	var master_bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus, is_muted)
	
	# Update button text
	if is_muted:
		mute_button.text = "Unmute Audio"
	else:
		mute_button.text = "Mute Audio"

func _on_save_title_pressed() -> void:
	# Unpause before changing scenes so the new scene isn't frozen!
	get_tree().paused = false 
	
	# Find the player using the group we just created
	var player = get_tree().get_first_node_in_group("Player")
	
	if player:
		# Save the current scene path and the player's exact coordinates
		var current_scene = get_tree().current_scene.scene_file_path
		Global.save_game(current_scene, player.global_position)
	else:
		print("Could not find Player to save position!")
	
	# Change back to the main menu (Ensure this path matches your actual file!)
	get_tree().change_scene_to_file("res://UI/start_ui.tscn")
	
func _on_resume_button_pressed() -> void:
	pass # Replace with function body.


func _on_save_title_button_pressed() -> void:
	pass # Replace with function body.


func _on_mute_button_pressed() -> void:
	pass # Replace with function body.
