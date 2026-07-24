extends CharacterBody2D 

var speed = 60.0 
var direction = 1 
var is_dead = false
var is_attacking = false
var is_hurt = false 
var is_summoning = false 
var is_dashing = false   

var max_health = 20
var health = 20 

# --- PHASE TRACKERS ---
var phase_75_done = false
var phase_50_done = false
var phase_25_done = false

# --- PROFESSIONAL AI VARIABLES ---
var spell_cooldown = 0.0 
var attack_range = 400.0 
var safe_distance = 75.0 
var chase_distance = 200.0 
var panic_distance = 45.0 
var dash_cooldown = 0.0  

# --- EXPORT SLOTS ---
@export var boss_skill_scene: PackedScene 
@export var boss_skill_2_scene: PackedScene 
@export var skeleton_scene: PackedScene 
@export var ghost_scene: PackedScene    

@onready var animated_sprite = $AnimatedSprite2D
@onready var detection_area = $DetectionArea 
@onready var combat_box = $CombatBox 
@onready var combat_shape = $CombatBox/CollisionShape2D 
@onready var ledge_check = $LedgeCheck 

func _physics_process(delta: float) -> void:
	if is_summoning:
		velocity = Vector2.ZERO
		return 

	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_dead or is_hurt:
		velocity.x = 0
		move_and_slide()
		return
		
	if is_dashing:
		velocity.x = speed * 3.5 * direction 
		move_and_slide()
		return

	if is_attacking:
		velocity.x = 0
		move_and_slide()
		return
		
	check_phases()
		
	spell_cooldown -= delta
	dash_cooldown -= delta 
		
	var target_player = null
	for body in detection_area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			target_player = body
			break 
			
	if target_player != null:
		var distance_to_player = global_position.distance_to(target_player.global_position)
		
		# --- THE PANIC BRAIN (GET OFF ME!) ---
		if distance_to_player < panic_distance and spell_cooldown <= 0.0:
			start_spell_attack(target_player, true)
			return
		
		# --- 1. THE ATTACK BRAIN ---
		if distance_to_player <= attack_range and spell_cooldown <= 0.0:
			start_spell_attack(target_player) 
			return
			
		# --- 2. THE WALKING BRAIN ---
		if distance_to_player < safe_distance:
			direction = 1 if global_position.x > target_player.global_position.x else -1
			
			if dash_cooldown <= 0.0 and randi() % 30 == 0: 
				start_dash(target_player, true) 
				return
				
		elif distance_to_player > chase_distance:
			direction = 1 if target_player.global_position.x > global_position.x else -1
			
		else:
			direction = 1 if target_player.global_position.x > global_position.x else -1
			animated_sprite.flip_h = (direction < 0)
			velocity.x = 0
			animated_sprite.play("idle")
			move_and_slide()
			return
	else:
		velocity.x = 0
		animated_sprite.play("idle")
		move_and_slide()
		return
		
	if animated_sprite.animation != "walk":
		animated_sprite.play("walk")
		
	if direction > 0:
		animated_sprite.flip_h = false 
		ledge_check.position.x = 20 
	else:
		animated_sprite.flip_h = true  
		ledge_check.position.x = -20 

	ledge_check.force_raycast_update()

	if is_on_floor() and not ledge_check.is_colliding():
		velocity.x = 0 
	else:
		velocity.x = speed * direction

	move_and_slide()

# --- PHASE LOGIC ---
func check_phases():
	if health <= max_health * 0.75 and not phase_75_done:
		phase_75_done = true
		start_summon(4, skeleton_scene)
		
	elif health <= max_health * 0.50 and not phase_50_done:
		phase_50_done = true
		speed = 90.0 
		attack_range = 450.0 
		
	elif health <= max_health * 0.25 and not phase_25_done:
		phase_25_done = true
		start_summon(2, ghost_scene)

# --- 1-BY-1 SEQUENTIAL SUMMON LOGIC ---
func start_summon(amount: int, mob_scene: PackedScene):
	is_summoning = true
	combat_shape.set_deferred("disabled", true) 
	velocity = Vector2.ZERO
	animated_sprite.play("idle")
	
	var floor_y = global_position.y 
	
	var tween_up = create_tween()
	tween_up.tween_property(self, "position", position + Vector2(0, -100), 1.0)
	await get_tree().create_timer(1.0).timeout 
	
	for i in range(amount):
		if mob_scene != null:
			var mob = mob_scene.instantiate()
			mob.name = "BossSummon_" + str(randi()) 
			get_parent().add_child(mob)
			
			var random_x_offset = 0.0
			if i % 2 == 0:
				random_x_offset = randf_range(-200, -80) 
			else:
				random_x_offset = randf_range(80, 200)   
				
			mob.global_position = Vector2(global_position.x + random_x_offset, floor_y) 
			
			var float_spell_timer = 2.0 
			
			while is_instance_valid(mob):
				float_spell_timer -= 0.2
				if float_spell_timer <= 0.0:
					float_spell_timer = randf_range(3.0, 5.0) 
					cast_floating_spell(floor_y)
					
				await get_tree().create_timer(0.2).timeout
				
			if i < amount - 1:
				await get_tree().create_timer(1.0).timeout
		else:
			print("WARNING: Missing summon scene in Inspector!")
			break
	
	var tween_down = create_tween()
	tween_down.tween_property(self, "position", position + Vector2(0, 100), 0.5)
	await get_tree().create_timer(0.5).timeout

	combat_shape.set_deferred("disabled", false) 
	is_summoning = false 

# --- FLOATING ATTACK HELPER ---
func cast_floating_spell(floor_y: float):
	var target_player = null
	for body in detection_area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			target_player = body
			break
			
	if target_player != null and boss_skill_2_scene != null:
		var skill = boss_skill_2_scene.instantiate()
		get_parent().add_child(skill)
		
		skill.global_position = Vector2(target_player.global_position.x, floor_y)

# --- UPGRADED EVASIVE DASH ---
func start_dash(target: Node2D, dash_away: bool = true):
	is_dashing = true
	dash_cooldown = randf_range(3.0, 5.0) 
	
	if target.global_position.x > global_position.x:
		direction = -1 if dash_away else 1
	else:
		direction = 1 if dash_away else -1
		
	animated_sprite.flip_h = (direction < 0)
	animated_sprite.play("dash")
	
	await get_tree().create_timer(0.4).timeout 
	
	is_dashing = false
	velocity.x = 0

# --- THE BOSS ATTACK ---
func start_spell_attack(target: Node2D, force_skill_1: bool = false):
	is_attacking = true
	
	if phase_50_done:
		spell_cooldown = randf_range(1.0, 2.0)
	else:
		spell_cooldown = randf_range(2.0, 3.5)
	
	if target.global_position.x > global_position.x:
		animated_sprite.flip_h = false 
		direction = 1
	else:
		animated_sprite.flip_h = true  
		direction = -1
		
	var attack_choice = randi() % 2 
	
	if force_skill_1:
		attack_choice = 0
		
	var chosen_skill_scene = null
	
	# --- UPDATED DELAY AND COLOR LOGIC ---
	if attack_choice == 0 and boss_skill_scene != null:
		animated_sprite.modulate = Color.GREEN # Toxic green-yellow warning!
		animated_sprite.play("attack1") 
		chosen_skill_scene = boss_skill_scene
		await get_tree().create_timer(1.5).timeout 
		animated_sprite.modulate = Color.WHITE # Return to normal color
		
	elif boss_skill_2_scene != null:
		animated_sprite.play("attack2") 
		chosen_skill_scene = boss_skill_2_scene
		await get_tree().create_timer(0.4).timeout 
		
	else:
		animated_sprite.modulate = Color.GREEN # Toxic green-yellow warning!
		animated_sprite.play("attack1") 
		chosen_skill_scene = boss_skill_scene
		await get_tree().create_timer(1.5).timeout 
		animated_sprite.modulate = Color.WHITE # Return to normal color
	
	if is_dead or is_hurt or is_summoning:
		animated_sprite.modulate = Color.WHITE 
		is_attacking = false
		return
		
	if chosen_skill_scene != null:
		var skill = chosen_skill_scene.instantiate()
		if skill.get("direction") != null:
			skill.direction = direction
			
		get_parent().add_child(skill)
		
		if chosen_skill_scene == boss_skill_2_scene and is_instance_valid(target):
			skill.global_position = Vector2(target.global_position.x, global_position.y)
		else:
			skill.global_position = global_position + Vector2(35 * direction, -10)
			
			if "target" in skill:
				skill.target = target
			
			if direction == -1 and skill.has_node("AnimatedSprite2D"):
				skill.get_node("AnimatedSprite2D").flip_h = true

	is_attacking = false

# --- HEALTH & HIT LOGIC ---
func _on_combat_box_area_entered(area: Area2D) -> void:
	if is_dead or is_summoning: return 
	if area.name == "SwordArea":
		take_hit() 

func take_hit():
	if is_dead or is_hurt or is_summoning: return 
	
	health -= 1
	is_attacking = false 
	is_dashing = false 
	animated_sprite.modulate = Color.WHITE # Reset color if interrupted!
	
	if health <= 0:
		die()
	else:
		is_hurt = true
		animated_sprite.play("take_damage")

func die():
	if is_dead: return 
	is_dead = true
	animated_sprite.modulate = Color.WHITE
	animated_sprite.play("die")

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "die":
		# Instead of deleting the boss node, change to the victory video scene!
		get_tree().change_scene_to_file("res://Cut_Scene/Ending/ending_cutscene.tscn")
	elif animated_sprite.animation == "take_damage":
		is_hurt = false
