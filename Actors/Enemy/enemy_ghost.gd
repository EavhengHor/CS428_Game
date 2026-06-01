extends CharacterBody2D 

var speed = 30.0 
var direction = 1 
var is_dead = false
var is_attacking = false
var is_hurt = false 
var ai_timer = 0.0
var unique_id = "" 

var health = 8 

# --- PROFESSIONAL AI VARIABLES ---
var spell_cooldown = 0.0 # Tracks when the ghost is allowed to shoot again
var melee_range = 45.0 # If the player is closer than 45 pixels, use the Scythe!
@export var spell_scene: PackedScene # Drag your EnemyGhostSpell.tscn here!

@onready var animated_sprite = $AnimatedSprite2D
@onready var bite_area = $BiteArea
@onready var bite_shape = $BiteArea/CollisionShape2D
@onready var detection_area = $DetectionArea 

# --- NEW: Grab the RayCast for the ledge check! ---
@onready var ledge_check = $LedgeCheck 

# Fixed a tiny typo here! (Removed the "2" at the end of .tscn)
const COIN_SCENE = preload("res://Reusable_Scene/coin.tscn")

func _ready() -> void:
	unique_id = get_tree().current_scene.name + "_" + name
	if unique_id in Global.killed_enemies:
		queue_free() 
		return 
	
	animated_sprite.play("move")
	pick_new_direction()
	bite_shape.disabled = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 1. Stop moving if dead, hurting, or in the middle of ANY attack
	if is_dead or is_attacking or is_hurt:
		velocity.x = 0
		move_and_slide()
		return
		
	# 2. ALWAYS count down the spell cooldown timer
	spell_cooldown -= delta
		
	# 3. SMART AI: Look for the player
	var target_player = null
	for body in detection_area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			target_player = body
			break 
			
	if target_player != null:
		# Measure exactly how far away the player is
		var distance_to_player = global_position.distance_to(target_player.global_position)
		
		# DECISION TIME: Scythe or Spell?
		if distance_to_player <= melee_range:
			# Player is too close! Swing the scythe!
			start_melee_attack(target_player)
			return
		elif spell_cooldown <= 0.0:
			# Player is far away AND cooldown is ready! Cast a spell!
			start_spell_attack(target_player)
			return
		else:
			# Player is far away, but spell is recharging. Float menacingly towards them!
			direction = 1 if target_player.global_position.x > global_position.x else -1
	else:
		# No player seen. Wander around randomly.
		ai_timer -= delta
		if ai_timer <= 0 or is_on_wall():
			pick_new_direction()
		
	if animated_sprite.animation != "move":
		animated_sprite.play("move")
		
	# --- 4. Set up the Laser and Sprites FIRST ---
	if direction > 0:
		animated_sprite.flip_h = false 
		bite_area.scale.x = 1 
		ledge_check.position.x = 15 # Move laser in front to the right
	else:
		animated_sprite.flip_h = true  
		bite_area.scale.x = -1 
		ledge_check.position.x = -15 # Move laser in front to the left

	# --- 5. MAGIC FIX: Force the laser to update instantly! ---
	ledge_check.force_raycast_update()

	# --- 6. THE SMART LEDGE CHECK ---
	if is_on_floor() and not ledge_check.is_colliding():
		if target_player == null:
			# If just wandering, safely turn around
			direction *= -1
			ai_timer = randf_range(1.5, 3.5)
			velocity.x = speed * direction
		else:
			# BOSS TACTIC: If chasing the player, stop at the edge and cast spells!
			velocity.x = 0
	else:
		# Safe ground: move normally
		velocity.x = speed * direction

	move_and_slide()

func pick_new_direction():
	direction = [-1, 1].pick_random()
	ai_timer = randf_range(1.5, 3.5)

# --- ATTACK 1: CLOSE COMBAT SCYTHE ---
func start_melee_attack(target: Node2D):
	is_attacking = true
	animated_sprite.play("attack")
	bite_shape.set_deferred("disabled", false)
	
	if target.global_position.x > global_position.x:
		animated_sprite.flip_h = false 
		direction = 1
		bite_area.scale.x = 1
	else:
		animated_sprite.flip_h = true  
		direction = -1
		bite_area.scale.x = -1

	await get_tree().create_timer(0.5).timeout
	
	if is_dead or is_hurt:
		return
		
	var bodies_in_mouth = bite_area.get_overlapping_bodies()
	for body in bodies_in_mouth:
		if body.has_method("take_damage"):
			body.take_damage(2) 
			break 

# --- ATTACK 2: LONG RANGE SPELL ---
func start_spell_attack(target: Node2D):
	is_attacking = true
	
	spell_cooldown = randf_range(3.0, 5.0)
	
	if target.global_position.x > global_position.x:
		animated_sprite.flip_h = false 
		direction = 1
		bite_area.scale.x = 1
	else:
		animated_sprite.flip_h = true  
		direction = -1
		bite_area.scale.x = -1
		
	animated_sprite.play("attack") 
	
	await get_tree().create_timer(0.3).timeout
	
	if is_dead or is_hurt:
		return
		
	if spell_scene != null:
		var spell = spell_scene.instantiate()
		
		if spell.get("direction") != null:
			spell.direction = direction
			
		get_parent().add_child(spell)
		spell.global_position = global_position + Vector2(25 * direction, -15)
	else:
		print("WARNING: You forgot to drag the EnemyGhostSpell scene into the Inspector!")

# --- HEALTH & HIT LOGIC ---
func _on_combat_box_area_entered(area: Area2D) -> void:
	if is_dead: return
	if area.name == "SwordArea":
		take_hit() 

func take_hit():
	if is_dead or is_hurt: return 
	
	health -= 1
	is_attacking = false 
	bite_shape.set_deferred("disabled", true)
	
	if health <= 0:
		die()
	else:
		is_hurt = true
		animated_sprite.play("got_hit")

func die():
	if is_dead: return 
	is_dead = true
	animated_sprite.play("die")
	bite_shape.set_deferred("disabled", true)

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "die":
		if not unique_id in Global.killed_enemies:
			Global.killed_enemies.append(unique_id)
		
		var drop_amount = randi_range(6, 8)
		for i in range(drop_amount):
			var new_coin = COIN_SCENE.instantiate()
			var random_offset = Vector2(randf_range(-30.0, 30.0), randf_range(-25.0, 0.0))
			get_parent().call_deferred("add_child", new_coin)
			new_coin.set_deferred("global_position", global_position + random_offset)
			
		queue_free() 
		
	elif animated_sprite.animation == "attack":
		is_attacking = false
		bite_shape.set_deferred("disabled", true)
		
	elif animated_sprite.animation == "got_hit":
		is_hurt = false
