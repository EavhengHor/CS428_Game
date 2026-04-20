extends Node

var total_coins = 0
var is_loading_from_save = false 
var saved_position = Vector2.ZERO

# --- NEW: The Hit List ---
var killed_enemies = [] 

const SAVE_PATH = "user://save_data.save"

func _ready() -> void:
	pass

func save_game(level_path: String, player_pos: Vector2):
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	var save_data = {
		"total_coins": total_coins,
		"level": level_path,
		"pos_x": player_pos.x,
		"pos_y": player_pos.y,
		"killed_enemies": killed_enemies # --- NEW: Save the list! ---
	}
	
	file.store_var(save_data)
	print("GAME SAVED! Data: ", save_data)

func load_game() -> bool:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var saved_data = file.get_var()
		
		total_coins = saved_data["total_coins"]
		saved_position = Vector2(saved_data["pos_x"], saved_data["pos_y"])
		
		# --- NEW: Load the list safely! ---
		# We check if it exists first, just in case you load an older save file
		if saved_data.has("killed_enemies"):
			killed_enemies = saved_data["killed_enemies"]
		else:
			killed_enemies = []
		
		print("SAVE LOADED! Welcome back. Coins: ", total_coins)
		get_tree().change_scene_to_file(saved_data["level"])
		
		return true 
	else:
		print("No save file found. Starting a brand new game!")
		return false
