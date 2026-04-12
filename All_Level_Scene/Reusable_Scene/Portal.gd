extends Area2D

@export var next_scene: PackedScene
@onready var next_level_text = $NextLevelAnimation

var player_in_range := false

func _ready() -> void:
	next_level_text.hide()
	# This will print right when the game starts
	print("DEBUG: Portal loaded. Next scene loaded: ", next_scene)

func _on_body_entered(body: Node2D) -> void:
	print("DEBUG: Something touched the portal: ", body.name)
	if body.name == "Player": 
		player_in_range = true
		next_level_text.show()
		print("DEBUG: Player is in range! player_in_range = true")

func _on_body_exited(body: Node2D) -> void:
	print("DEBUG: Something left the portal: ", body.name)
	if body.name == "Player":
		player_in_range = false
		next_level_text.hide()
		print("DEBUG: Player left! player_in_range = false")

# I changed _input to _unhandled_input (explained below)
func _unhandled_input(event: InputEvent) -> void:
	# This checks if the engine even detects the 'F' key at all
# Change "interact" to "enter_portal"
	if player_in_range and event.is_action_pressed("enter_portal"):
		print("DEBUG: The 'interact' key was pressed! Checking if player is in range...")
		print("DEBUG: Current player_in_range status: ", player_in_range)
		
		if player_in_range:
			print("DEBUG: Conditions met! Trying to teleport...")
			if next_scene != null:
				print("DEBUG: Teleporting to next scene NOW!")
				get_tree().change_scene_to_packed(next_scene)
			else:
				print("WARNING: You forgot to put a level in the Inspector slot for this portal!")
