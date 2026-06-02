extends CharacterBody2D 

var speed = 60.0 
var direction = 1 
var is_dead = false
var is_attacking = false
var is_hurt = false 

var health = 20 # Bosses need lots of health!

# --- PROFESSIONAL AI VARIABLES ---
var spell_cooldown = 0.0 
var attack_range = 400.0 # Increased so he sees you from further away!

@export var boss_skill_scene: PackedScene 

@onready var animated_sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea 
@onready var combat_box = $CombatBox 
@onready var ledge_check = $LedgeCheck 

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 1. Stop moving if dead, hurting, or attacking
	if is_dead or is_attacking or is_hurt:
		velocity.x = 0
		move_and_slide()
		return
		
	# 2. Count down the cooldown
	spell_cooldown -= delta
		
	# 3. SMART AI: Look for the player
	var target_player = null
	for body in detection_area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			target_player = body
			break 
			
	if target_player != null:
		var distance_to_player = global_position.distance_to(target_player.global_position)
		
		# DECISION TIME
		if distance_to_player <= attack_range and spell_cooldown <= 0.0:
			start_spell_attack(target_player)
			return
		else:
			direction = 1 if target_player.global_position.x > global_position.x else -1
	else:
		# No player seen. Stand guard.
		velocity.x = 0
		animated_sprite.play("idle")
		move_and_slide()
		return
		
	if animated_sprite.animation != "walk":
		animated_sprite.play("walk")
		
	# 4. Set up the Ledge Check Laser
	if direction > 0:
		animated_sprite.flip_h = false 
		ledge_check.position.x = 20 
	else:
		animated_sprite.flip_h = true  
		ledge_check.position.x = -20 

	ledge_check.force_raycast_update()

	# 5. THE SMART LEDGE CHECK
	if is_on_floor() and not ledge_check.is_colliding():
		velocity.x = 0 # Boss stops at the edge!
	else:
		velocity.x = speed * direction

	move_and_slide()

# --- THE BOSS ATTACK ---
func start_spell_attack(target: Node2D):
	is_attacking = true
	spell_cooldown = randf_range(2.0, 3.5)
	
	if target.global_position.x > global_position.x:
		animated_sprite.flip_h = false 
		direction = 1
	else:
		animated_sprite.flip_h = true  
		direction = -1
		
	animated_sprite.play("attack1") 
	
	await get_tree().create_timer(0.4).timeout
	
	if is_dead or is_hurt:
		return
		
	if boss_skill_scene != null:
		var skill = boss_skill_scene.instantiate()
		if skill.get("direction") != null:
			skill.direction = direction
			
		get_parent().add_child(skill)
		skill.global_position = global_position + Vector2(35 * direction, -10)
		
		if direction == -1 and skill.has_node("AnimatedSprite2D"):
			skill.get_node("AnimatedSprite2D").flip_h = true
	else:
		print("WARNING: You forgot to drag the Boss_Skill1 scene into the Inspector!")

# --- HEALTH & HIT LOGIC (Matched to Ghost) ---
func _on_combat_box_area_entered(area: Area2D) -> void:
	if is_dead: return
	if area.name == "SwordArea":
		take_hit() 

func take_hit():
	if is_dead or is_hurt: return 
	
	health -= 1
	is_attacking = false 
	
	if health <= 0:
		die()
	else:
		is_hurt = true
		animated_sprite.play("take_damage")

func die():
	if is_dead: return 
	is_dead = true
	animated_sprite.play("die")

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "die":
		queue_free() 
	elif animated_sprite.animation == "attack1":
		is_attacking = false
	elif animated_sprite.animation == "take_damage":
		is_hurt = false
