extends Area2D

var speed = 70.0 # Made it slightly faster so it's a real threat!
var direction = 1
var target: Node2D = null # The boss will hand the player's data to this variable

func _ready():
	# 1. The 4-Second Fuse: 
	# The moment this spawns, wait 4 seconds and then delete itself.
	await get_tree().create_timer(4.0).timeout
	queue_free()

func _physics_process(delta):
	# 2. The Homing Missile Logic:
	# Check if the target exists and is still alive
	if is_instance_valid(target):
		# Calculate the exact angle to the player and fly towards it!
		var direction_to_player = global_position.direction_to(target.global_position)
		position += direction_to_player * speed * delta
		
		# Make the skull turn around to face the player as it chases them
		if direction_to_player.x < 0:
			$AnimatedSprite2D.flip_h = true
		else:
			$AnimatedSprite2D.flip_h = false
	else:
		# Fallback: If the player is missing, just fly straight horizontally
		position.x += speed * direction * delta

func _on_body_entered(body):
	# If it hits the player, deal damage and disappear
	if body.has_method("take_damage"):
		body.take_damage(1)
		queue_free()
