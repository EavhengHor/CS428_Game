extends Area2D

var speed = 100.0 # Adjust this to make it faster/harder to jump over!
var direction = 1 # 1 means right, -1 means left

func _physics_process(delta):
	# This pushes the skill perfectly horizontal so the player can jump it
	position.x += speed * direction * delta

func _on_body_entered(body):
	# If it hits the player, deal damage and disappear
	if body.has_method("take_damage"):
		body.take_damage(1)
		queue_free()
