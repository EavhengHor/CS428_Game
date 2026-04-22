extends Area2D

func _on_body_entered(body: Node2D) -> void:
	# Check if the object touching the spike is the Player
	if body.has_method("take_damage"):
		body.take_damage()
