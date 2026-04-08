extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("add_coin"):
		body.add_coin()
		queue_free()
		print("Coin Taken")
