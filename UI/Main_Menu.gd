extends Control

# Grab the Continue Button so we can turn it on/off
@onready var continue_button = $VBoxContainer/Continue_Button

func _ready() -> void:
	# Check if a save file exists in the user's system
	if FileAccess.file_exists(Global.SAVE_PATH):
		continue_button.disabled = false
		continue_button.text = "Continue Game" 
	else:
		continue_button.disabled = true
		continue_button.text = "No Save Found"

func _process(delta: float) -> void:
	pass

func _on_start_button_pressed() -> void:
	print("Start Pressed")
	
	# Start fresh: reset coins and tell the game NOT to load coordinates
	Global.total_coins = 0 
	Global.is_loading_from_save = false
	
	# Wipe the dead enemy memory clean!
	Global.killed_enemies.clear()
	
	# Load the Cutscene
	get_tree().change_scene_to_file("res://Cut_Scene/Beginning/boss_take_child.tscn")
	
func _on_continue_button_pressed() -> void:
	# 1. Tell the game we are trying to load from a save!
	Global.is_loading_from_save = true
	
	# 2. Trigger the load function.
	if Global.load_game():
		print("Load successful! Handing control over to Global.gd...")
	else:
		print("Failed to load: No save file exists yet.")
		Global.is_loading_from_save = false

# --- NEW: The Credits Button Logic ---
func _on_credit_button_pressed() -> void:
	print("Credits Pressed")
	get_tree().change_scene_to_file("res://UI/credit.tscn")
		
func _on_exit_button_pressed() -> void:
	print("Exit Pressed")
	# Safely close the game window
	get_tree().quit()

func _on_mute_button_pressed() -> void:
	# Find the Master audio bus and toggle its mute state
	var master_bus = AudioServer.get_bus_index("Master")
	var is_muted = AudioServer.is_bus_mute(master_bus)
	
	AudioServer.set_bus_mute(master_bus, not is_muted)
	print("Mute toggled: ", not is_muted)
