extends Node

const SAVE_PATH = "user://savegame.save"

# This variable will never be destroyed when changing scenes!
var total_coins = 0

# --- NEW SAVE SYSTEM VARIABLES ---
var saved_level_path: String = ""
var saved_position: Vector2 = Vector2.ZERO
var is_loading_from_save: bool = false 

func save_game(level_path: String, player_pos: Vector2) -> void:
	# 1. Create a dictionary holding all the data we want to save
	var save_data = {
		"level": level_path,
		"pos_x": player_pos.x,
		"pos_y": player_pos.y,
		"total_coins": total_coins # Saving your exact variable!
	}
	
	# 2. Open a file and write the data to it
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(save_data)
	file.close()
	print("Game Saved! Data: ", save_data)

func load_game() -> bool:
	# 1. Check if a save file even exists
	if not FileAccess.file_exists(SAVE_PATH):
		return false
		
	# 2. Open the file and read the data
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var save_data = file.get_var()
	file.close()

	# 3. Apply the data to our Global variables
	saved_level_path = save_data["level"]
	saved_position = Vector2(save_data["pos_x"], save_data["pos_y"])
	total_coins = save_data["total_coins"] # Loading your exact variable!
	
	is_loading_from_save = true
	return true
