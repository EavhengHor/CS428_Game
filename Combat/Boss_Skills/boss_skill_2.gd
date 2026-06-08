extends Area2D

var direction = 1 

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	# 1. WARNING PHASE
	# Turn the hitbox OFF so it's completely safe to stand on the embers
	collision_shape.set_deferred("disabled", true)
	
	# Play the warning animation you added!
	animated_sprite.play("whineup")
	
	# Give the player exactly 2 seconds to realize what's happening and dash away
	await get_tree().create_timer(2.0).timeout
	
	# 2. ERUPTION PHASE
	# BOOM! Play the main explosion and turn the lethal hitbox ON
	animated_sprite.play("skill1")
	collision_shape.set_deferred("disabled", false)
	collision_shape.scale = Vector2(1.0, 1.0) 

func _on_body_entered(body):
	# Burn the player!
	if body.has_method("take_damage"):
		body.take_damage(1)

func _on_animated_sprite_2d_animation_finished():
	# Only delete the fire when the main eruption finishes, NOT the windup!
	if animated_sprite.animation == "skill1":
		queue_free()
