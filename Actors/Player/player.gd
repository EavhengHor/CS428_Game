extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -350.0
var max_lives = 5
var current_lives = 3
var spawn_position = Vector2.ZERO

# State variables
var is_attacking = false
var is_taking_damage = false

# --- NEW: ABILITY & UI TRACKING VARIABLES ---
var has_double_jumped = false
var previous_coins = -1
var previous_hadoken_state = false
@export var hadoken_scene: PackedScene 

@onready var coin_label = $CanvasLayer/CoinUI
@onready var hadouken_ui = $CanvasLayer/HadoukenUI
@onready var animated_sprite = $AnimatedSprite2D
@onready var heads_container = $CanvasLayer/LivesUI/HeadsContainer
@onready var sword_area = $SwordArea
@onready var sword_shape = $SwordArea/CollisionShape2D

func add_life():
	if current_lives < max_lives:
		current_lives += 1
		print("Checkpoint heal! Lives: ", current_lives)
		update_lives_ui()

func activate_checkpoint(new_position: Vector2):
	spawn_position = new_position
	print("Checkpoint saved at: ", spawn_position)

func _ready() -> void:
	if Global.is_loading_from_save:
		global_position = Global.saved_position
		Global.is_loading_from_save = false
		print("Player loaded at saved position: ", global_position)
	
	update_lives_ui()
	spawn_position = global_position
	sword_shape.disabled = true

func take_damage(amount: int = 1):
	if is_taking_damage:
		return
		
	is_attacking = false 
	sword_shape.set_deferred("disabled", true) 
		
	is_taking_damage = true
	animated_sprite.play("die") 
	
	velocity.y = JUMP_VELOCITY * 0.2
	
	if animated_sprite.flip_h == true: 
		velocity.x = SPEED 
	else:
		velocity.x = -SPEED 
	
	current_lives -= amount
	if current_lives < 0:
		current_lives = 0
		
	print("Ouch! Lives left: ", current_lives)
	update_lives_ui()
	
func update_lives_ui():
	var heads = heads_container.get_children()
	for i in range(heads.size()):
		if i < current_lives:
			heads[i].show() 
		else:
			heads[i].hide() 

func add_coin():
	Global.total_coins += 1
	print("Got a coin! Total: ", Global.total_coins)

func handle_attack():
	if Input.is_action_just_pressed("ui_attack") and not is_attacking:
		print("Attack!")
		is_attacking = true
		
		var attack_animations = ["attack", "attack1"]
		var chosen_attack = attack_animations.pick_random()
		animated_sprite.play(chosen_attack)
		
		await get_tree().create_timer(0.2).timeout
		
		if is_attacking and not is_taking_damage:
			sword_shape.set_deferred("disabled", false)

func handle_hadoken():
	if Input.is_action_just_pressed("ui_shoot") and not is_attacking and Global.unlocked_hadoken:
		if Global.total_coins >= 3:
			print("Hadoken!")
			Global.total_coins -= 3
			
			is_attacking = true
			animated_sprite.play("attack")
			
			await get_tree().create_timer(0.2).timeout
			
			if is_attacking and not is_taking_damage:
				if hadoken_scene != null:
					var fireball = hadoken_scene.instantiate()
					var facing_direction = 1
					if animated_sprite.flip_h == true:
						facing_direction = -1
						
					if fireball.get("direction") != null:
						fireball.direction = facing_direction
						
					get_parent().add_child(fireball)
					fireball.global_position = global_position + Vector2(20 * facing_direction, -15)
				else:
					print("WARNING: No Hadoken scene assigned in the Player Inspector!")
		else:
			print("Not enough coins! You need 3 coins to cast this spell.")

# --- THE FIX: SMART UI SYNCING ---
func _process(delta: float) -> void:
	# Only redraw the text if the coins actually changed!
	if Global.total_coins != previous_coins:
		previous_coins = Global.total_coins
		coin_label.text = "Coins: " + str(Global.total_coins)

	# Only redraw the UI if the unlock state actually changed!
	if Global.unlocked_hadoken != previous_hadoken_state:
		previous_hadoken_state = Global.unlocked_hadoken
		hadouken_ui.visible = Global.unlocked_hadoken

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_taking_damage:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 2.0)
		move_and_slide()
		return

	if is_on_floor():
		has_double_jumped = false 

	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif Global.unlocked_double_jump and not has_double_jumped:
			velocity.y = JUMP_VELOCITY * 0.9 
			has_double_jumped = true

	var direction := Input.get_axis("ui_left", "ui_right")
	
	handle_attack()
	handle_hadoken() 
		
	if direction > 0:
		animated_sprite.flip_h = false
		sword_area.scale.x = 1 
	elif direction < 0:
		animated_sprite.flip_h = true
		sword_area.scale.x = -1 
		
	if not is_attacking:
		if is_on_floor():
			if direction == 0:
				animated_sprite.play("idle")	
			else:
				animated_sprite.play("run")	
		else:
			if velocity.y > 0:
				animated_sprite.play("fall") 
			else:
				animated_sprite.play("jump") 
		
	if is_attacking and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		
	move_and_slide()

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "attack" or animated_sprite.animation == "attack1":
		is_attacking = false
		sword_shape.set_deferred("disabled", true)
		
	elif animated_sprite.animation == "die":
		if current_lives > 0:
			is_taking_damage = false
		else:
			print("Game Over! Respawning at checkpoint...")
			current_lives = 3
			update_lives_ui()
			is_taking_damage = false 
			global_position = spawn_position
