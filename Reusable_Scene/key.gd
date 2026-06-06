extends Area2D

func _on_body_entered(body: Node2D) -> void:
	# Make sure only the player can collect the key!
	if body.name == "Player" or body.has_method("take_damage"):
		
		# Add 1 to our global counter
		Global.keys_collected += 1
		print("Picked up a key! Total keys: ", Global.keys_collected)
		
		# Delete the key from the level
		queue_free()
