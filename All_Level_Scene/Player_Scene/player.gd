extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -350.0
var coins_collected = 0
var max_lives = 5
var current_lives = 3
var spawn_position = Vector2.ZERO

# State variables
var is_attacking = false
var is_taking_damage = false

@onready var coin_label = $CanvasLayer/CoinUI
@onready var animated_sprite = $AnimatedSprite2D
@onready var heads_container = $CanvasLayer/LivesUI/HeadsContainer
@onready var sword_area = $SwordArea
@onready var sword_shape = $SwordArea/CollisionShape2D

func add_life():
	# Make sure we don't go over the maximum lives limit!
	if current_lives < max_lives:
		current_lives += 1
		print("Checkpoint heal! Lives: ", current_lives)
		update_lives_ui()

func activate_checkpoint(new_position: Vector2):
	spawn_position = new_position
	print("Checkpoint saved at: ", spawn_position)

func _ready() -> void:
	# Run the UI update the moment the player spawns in the level
	update_lives_ui()
	spawn_position = global_position
	
	# Make sure the sword is safely turned off when the level starts!
	sword_shape.disabled = true

func take_damage():
	# If we are already taking damage, don't take it again instantly
	if is_taking_damage:
		return
		
	# --- THE BUG FIX ---
	# Cancel the attack state immediately so we don't get stuck!
	is_attacking = false 
	# Turn off the sword hitbox so we don't accidentally hurt the pig while flying backward
	sword_shape.set_deferred("disabled", true) 
	# -------------------
		
	is_taking_damage = true
	animated_sprite.play("die") # Play the hurt/die animation
	
	# --- KNOCKBACK MAGIC ---
	velocity.y = JUMP_VELOCITY * 0.3 # Pop up into the air
	
	# Bounce backward depending on which way the player is looking
	if animated_sprite.flip_h == true: # Looking left
		velocity.x = SPEED # Bounce right
	else:
		velocity.x = -SPEED # Bounce left
	# -----------------------
	
	current_lives -= 1
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
	coins_collected += 1
	coin_label.text = "Coins: " + str(coins_collected)
	print("Got a coin! Total: ", coins_collected)

func handle_attack():
	if Input.is_action_just_pressed("ui_attack") and not is_attacking:
		print("Attack!")
		is_attacking = true
		animated_sprite.play("attack")
		
		# --- NEW SWING DELAY ---
		# Wait 0.2 seconds for the animation to actually swing the sword forward
		await get_tree().create_timer(0.2).timeout
		
		# Safety check: Make sure the player didn't get hurt during that 0.2 seconds!
		if is_attacking and not is_taking_damage:
			# Turn the hitbox ON!
			sword_shape.set_deferred("disabled", false)

func _physics_process(delta: float) -> void:
	# Always add gravity, even if hurt
	if not is_on_floor():
		velocity += get_gravity() * delta

	# --- DAMAGE LOCKOUT ---
	# If the player is taking damage, slow them down and skip the rest of the code!
	if is_taking_damage:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 2.0)
		move_and_slide()
		return

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	
	handle_attack()
		
	# flip the sprite and the sword hitbox
	if direction > 0:
		animated_sprite.flip_h = false
		sword_area.scale.x = 1 # Sword points Right
	elif direction < 0:
		animated_sprite.flip_h = true
		sword_area.scale.x = -1 # Sword points Left
		
	# ONLY play movement animations if we are NOT currently attacking
	if not is_attacking:
		if is_on_floor():
			if direction == 0:
				animated_sprite.play("idle")	
			else:
				animated_sprite.play("run")	
		else:
			animated_sprite.play("jump")	
		
	# Handle physics movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	# --- NEW ATTACK MOVEMENT LOCKOUT ---
	if is_attacking and is_on_floor():
		# Plant the player's feet! Slide to a quick stop.
		velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		# Normal movement (This allows you to steer while attacking in the air!)
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		
	move_and_slide()

# --- SIGNAL FUNCTION TO UNLOCK STATES ---
func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false
		
		# Turn the hitbox OFF when the swing is done!
		sword_shape.set_deferred("disabled", true)
		
	elif animated_sprite.animation == "die":
		if current_lives > 0:
			is_taking_damage = false
		else:
			print("Game Over! Respawning at checkpoint...")
			# Refill lives to max!
			current_lives = 1
			update_lives_ui()

			# Unlock movement
			is_taking_damage = false 

			# TELEPORT to the last saved checkpoint!
			global_position = spawn_position
