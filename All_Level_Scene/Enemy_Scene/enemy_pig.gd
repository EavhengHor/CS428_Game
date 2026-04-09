extends Area2D

var speed = 40.0
var direction = 1 # 1 means moving right, -1 means moving left
var is_dead = false
var ai_timer = 0.0

@onready var animated_sprite = $AnimatedSprite2D

func _ready() -> void:
	animated_sprite.play("idle")
	pick_new_direction()

func _process(delta: float) -> void:
	# If the pig is dead, stop moving entirely!
	if is_dead:
		return
		
	# 1. AI TIMER LOGIC
	ai_timer -= delta
	if ai_timer <= 0:
		pick_new_direction()
		
	# 2. MOVEMENT LOGIC
	position.x += speed * direction * delta
	
	# 3. LOOK LEFT OR RIGHT
	if direction > 0:
		animated_sprite.flip_h = true # Adjust this to false if he walks backward!
	else:
		animated_sprite.flip_h = false

func pick_new_direction():
	# Randomly pick either left (-1) or right (1)
	direction = [-1, 1].pick_random()
	# Randomly decide to walk that way for 1.5 to 3.5 seconds
	ai_timer = randf_range(1.5, 3.5)


# --- COMBAT LOGIC ---

# 1. This handles getting hit by the player's body
func _on_body_entered(body: Node2D) -> void:
	if is_dead:
		return 
		
	# If the player simply walks into the pig, the player takes damage
	if body.has_method("take_damage"):
		body.take_damage()

# 2. This handles getting hit by the Sword's Hitbox!
func _on_area_entered(area: Area2D) -> void:
	if is_dead:
		return
		
	# Check if the Area2D that touched the pig is our specific SwordArea
	if area.name == "SwordArea":
		die()

func die():
	is_dead = true
	animated_sprite.play("die")

# 3. This cleans up the pig after it dies
func _on_animated_sprite_2d_animation_finished() -> void:
	# Check if the animation that just finished was the death animation
	if animated_sprite.animation == "die":
		queue_free() # This deletes the pig from the game completely!
