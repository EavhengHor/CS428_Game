extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_button_pressed() -> void:
	print("Start Pressed")
	get_tree().change_scene_to_file("res://All_Level_Scene/Level_1/level_1.tscn")


func _on_continue_button_pressed() -> void:
	print("Continue Pressed")


func _on_exit_button_pressed() -> void:
	print("Exit Pressed")
	get_tree().quit()


func _on_mute_button_pressed() -> void:
	print("Mute Pressed")
	# This finds the main pipeline for ALL game audio
	var master_bus = AudioServer.get_bus_index("Master")
	
	# This shuts off that main pipeline entirely based on your button state
	AudioServer.set_bus_mute(master_bus, $Mute_Background/Mute_Button.button_pressed)
