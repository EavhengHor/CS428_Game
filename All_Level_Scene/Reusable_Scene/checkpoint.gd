extends Area2D

@onready var animated_sprite = $AnimatedSprite2D

var is_activated = false

func _ready() -> void:
	animated_sprite.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if is_activated:
		return 
		
	if body.has_method("activate_checkpoint"):
		is_activated = true 
		animated_sprite.play("saved")
		
		# --- Give the player +1 life! ---
		if body.has_method("add_life"):
			body.add_life()
			
		# Actually save the player's position in the game world
		body.activate_checkpoint(global_position)
		
		# --- THE FIX: Pass the 2 required arguments! ---
		# 1. Get the text path of the level we are currently standing in
		var current_level_path = get_tree().current_scene.scene_file_path
		# 2. Save the game using the path and the player's position
		Global.save_game(current_level_path, body.global_position)
