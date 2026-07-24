extends Area2D

func _on_body_entered(body: Node2D) -> void:
	# This now works for "Player", "Player2", "Player_Blue", etc!
	if "Player" in body.name:
		print("Player hit the killzone!")
		
		if body.has_method("take_damage"):
			body.take_damage(body.current_lives)
