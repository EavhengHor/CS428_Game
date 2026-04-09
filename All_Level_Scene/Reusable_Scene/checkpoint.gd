extends Area2D

# Reference the new AnimatedSprite2D node
@onready var animated_sprite = $AnimatedSprite2D

var is_activated = false

func _ready() -> void:
	# Start with the idle (Hi) animation
	animated_sprite.play("idle")

func _on_body_entered(body: Node2D) -> void:
	# If this checkpoint was already touched, ignore the collision
	if is_activated:
		return 
		
	# Check if the player touched it
	if body.has_method("activate_checkpoint"):
		is_activated = true # Lock the checkpoint so it can't trigger again
		
		# 1. Change the visual state to 'Saved'
		animated_sprite.play("saved")
		
		# 2. Actually save the player's position
		body.activate_checkpoint(global_position)
