extends Control

func _on_back_button_pressed() -> void:
	print("Heading back to the Start UI!")
	get_tree().change_scene_to_file("res://UI/start_ui.tscn")
