extends CharacterBody2D 

var speed = 40.0
var direction = 1 
var is_dead = false
var is_attacking = false
var ai_timer = 0.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var bite_area = $BiteArea
@onready var bite_shape = $BiteArea/CollisionShape2D

# Grab the Detection Area so the pig can look around!
@onready var detection_area = $DetectionArea 

const COIN_SCENE = preload("res://All_Level_Scene/Reusable_Scene/coin.tscn")

func _ready() -> void:
	animated_sprite.play("move")
	pick_new_direction()
	bite_shape.disabled = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# If the pig is dead or in the middle of a bite, stop walking!
	if is_dead or is_attacking:
		velocity.x = 0
		move_and_slide()
		return
		
	# --- NEW SUPER SMART AI ---
	# Check the vision circle every single frame!
	for body in detection_area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			start_attack(body)
			return # Stop running the walk code and bite!
	# --------------------------
		
	if animated_sprite.animation != "move":
		animated_sprite.play("move")
		
	ai_timer -= delta
	if ai_timer <= 0 or is_on_wall():
		pick_new_direction()
		
	velocity.x = speed * direction
	
	if direction > 0:
		animated_sprite.flip_h = true 
		bite_area.scale.x = 1 
	else:
		animated_sprite.flip_h = false
		bite_area.scale.x = -1 

	move_and_slide()

func pick_new_direction():
	direction = [-1, 1].pick_random()
	ai_timer = randf_range(1.5, 3.5)

# --- COMBAT LOGIC ---

# Dedicated attack function WITH DODGE DELAY
func start_attack(target: Node2D):
	is_attacking = true
	animated_sprite.play("attack")
	
	# Turn the hitbox ON so we can track if the player is inside it
	bite_shape.set_deferred("disabled", false)
	
	# Instantly snap to face the player
	if target.global_position.x > global_position.x:
		animated_sprite.flip_h = true
		direction = 1
		bite_area.scale.x = 1
	else:
		animated_sprite.flip_h = false
		direction = -1
		bite_area.scale.x = -1

	# --- NEW DODGE DELAY MECHANIC ---
	# Wait for exactly 0.5 seconds (the attack wind-up)
	await get_tree().create_timer(0.5).timeout
	
	# Safety check: If the player killed the pig during the wind-up, cancel the bite!
	if is_dead:
		return
		
	# The 0.5 seconds are up! Who is CURRENTLY standing in the bite zone?
	var bodies_in_mouth = bite_area.get_overlapping_bodies()
	
	for body in bodies_in_mouth:
		if body.has_method("take_damage"):
			body.take_damage() # CHOMP!
			break # Only bite the player once per swing
	# --------------------------------

# We remove the code from this signal so it doesn't instantly hurt the player anymore!
func _on_bite_area_body_entered(body: Node2D) -> void:
	pass

# The Player's sword hits the Pig's CombatBox
func _on_combat_box_area_entered(area: Area2D) -> void:
	if is_dead: return
	if area.name == "SwordArea":
		die()

func die():
	if is_dead: return 
	is_dead = true
	animated_sprite.play("die")
	bite_shape.set_deferred("disabled", true)

# --- CLEANUP & COIN DROP ---
func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "die":
		var new_coin = COIN_SCENE.instantiate()
		get_parent().call_deferred("add_child", new_coin)
		new_coin.global_position = global_position
		queue_free() 
		
	elif animated_sprite.animation == "attack":
		is_attacking = false
		bite_shape.set_deferred("disabled", true)

func _on_combat_box_body_entered(body: Node2D) -> void:
	pass
