extends Area2D

var direction = 1 

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	animated_sprite.play("skill1")
	
	# 1. WARNING PHASE (Frames 0 to 4)
	# Shrink the hitbox to 50% width and 20% height so it only covers the floor embers!
	collision_shape.scale = Vector2(0.5, 0.2)
	
	# Optional: If your hitbox floats in the air when it shrinks, you can push it down
	# collision_shape.position.y += 20 

func _process(_delta):
	# 2. ERUPTION PHASE (Frames 5 to 11)
	# Once the animation hits frame 5, snap the hitbox back to 100% full size!
	if animated_sprite.frame >= 5:
		collision_shape.scale = Vector2(1.0, 1.0)
		
		# If you pushed it down in the warning phase, reset the position here:
		# collision_shape.position.y -= 20 

func _on_body_entered(body):
	# 3. Burn the player!
	if body.has_method("take_damage"):
		body.take_damage(1)
		
		# Note: We still do NOT use queue_free() here. 
		# The fire should keep burning even if the player dashes through it!

# 4. END OF SPELL
# Connect this to your AnimatedSprite2D's 'animation_finished()' signal
func _on_animated_sprite_2d_animation_finished():
	# The fire completely deletes itself ONLY when the animation ends naturally
	queue_free()
