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
		
		# Save position
		body.activate_checkpoint(global_position)
		
		# --- NEW: Give the player +1 life! ---
		if body.has_method("add_life"):
			body.add_life()
