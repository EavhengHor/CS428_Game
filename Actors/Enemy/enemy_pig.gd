extends CharacterBody2D 

var speed = 40.0
var direction = 1 
var is_dead = false
var is_attacking = false
var ai_timer = 0.0

var unique_id = "" # We will fill this in when the level starts

@onready var animated_sprite = $AnimatedSprite2D
@onready var bite_area = $BiteArea
@onready var bite_shape = $BiteArea/CollisionShape2D

# Grab the Detection Area so the pig can look around!
@onready var detection_area = $DetectionArea 

# --- NEW: Grab the RayCast for the ledge check! ---
@onready var ledge_check = $LedgeCheck 

const COIN_SCENE = preload("res://Reusable_Scene/coin.tscn")

func _ready() -> void:
	# --- 1. THE MEMORY CHECK ---
	unique_id = get_tree().current_scene.name + "_" + name
	
	if unique_id in Global.killed_enemies:
		queue_free() # Delete myself instantly!
		return # Stop reading the rest of this function!
	
	# --- 2. THE NORMAL SETUP ---
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
		
	# --- SUPER SMART AI ---
	for body in detection_area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			start_attack(body)
			return # Stop running the walk code and bite!
		
	if animated_sprite.animation != "move":
		animated_sprite.play("move")
		
	ai_timer -= delta
	if ai_timer <= 0 or is_on_wall():
		pick_new_direction()
		
	# --- 1. Set up the Laser and Sprites FIRST ---
	if direction > 0:
		animated_sprite.flip_h = true 
		bite_area.scale.x = 1 
		ledge_check.position.x = 15 
	else:
		animated_sprite.flip_h = false
		bite_area.scale.x = -1 
		ledge_check.position.x = -15 

	# --- MAGIC FIX #1: Force the laser to update its eyes INSTANTLY! ---
	ledge_check.force_raycast_update()

	# --- MAGIC FIX #2: Check for the cliff BEFORE setting our movement speed ---
	if is_on_floor() and not ledge_check.is_colliding():
		direction *= -1 # Turn around!
		ai_timer = randf_range(1.5, 3.5) # Reset wander timer

	# --- 3. NOW calculate speed and move safely! ---
	velocity.x = speed * direction
	move_and_slide()
	
func pick_new_direction():
	direction = [-1, 1].pick_random()
	ai_timer = randf_range(1.5, 3.5)

# --- COMBAT LOGIC ---

func start_attack(target: Node2D):
	is_attacking = true
	animated_sprite.play("attack")
	
	bite_shape.set_deferred("disabled", false)
	
	if target.global_position.x > global_position.x:
		animated_sprite.flip_h = true
		direction = 1
		bite_area.scale.x = 1
	else:
		animated_sprite.flip_h = false
		direction = -1
		bite_area.scale.x = -1

	await get_tree().create_timer(0.5).timeout
	
	if is_dead:
		return
		
	var bodies_in_mouth = bite_area.get_overlapping_bodies()
	for body in bodies_in_mouth:
		if body.has_method("take_damage"):
			body.take_damage() 
			break 

func _on_bite_area_body_entered(body: Node2D) -> void:
	pass

func _on_combat_box_area_entered(area: Area2D) -> void:
	if is_dead: return
	if area.name == "SwordArea":
		take_hit() 

func take_hit():
	if is_dead: return
	die()

func die():
	if is_dead: return 
	is_dead = true
	animated_sprite.play("die")
	bite_shape.set_deferred("disabled", true)

# --- CLEANUP & COIN DROP ---
func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "die":
		
		if not unique_id in Global.killed_enemies:
			Global.killed_enemies.append(unique_id)
		
		var drop_amount = randi_range(4, 5)
		
		for i in range(drop_amount):
			var new_coin = COIN_SCENE.instantiate()
			var random_offset = Vector2(randf_range(-25.0, 25.0), randf_range(-20.0, 0.0))
			
			get_parent().call_deferred("add_child", new_coin)
			new_coin.set_deferred("global_position", global_position + random_offset)
			
		queue_free() 
		
	elif animated_sprite.animation == "attack":
		is_attacking = false
		bite_shape.set_deferred("disabled", true)

func _on_combat_box_body_entered(body: Node2D) -> void:
	pass
