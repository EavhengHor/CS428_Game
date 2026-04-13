extends CharacterBody2D 

var speed = 40.0
var direction = 1 
var is_dead = false
var is_attacking = false
var is_hurt = false # NEW: Tracks if the skeleton is stunned by an attack
var ai_timer = 0.0

var health = 3 # NEW: Skeleton's health!

@onready var animated_sprite = $AnimatedSprite2D
@onready var bite_area = $BiteArea
@onready var bite_shape = $BiteArea/CollisionShape2D
@onready var detection_area = $DetectionArea 

const COIN_SCENE = preload("res://All_Level_Scene/Reusable_Scene/coin.tscn")

func _ready() -> void:
	animated_sprite.play("move")
	pick_new_direction()
	bite_shape.disabled = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# NEW: If dead, attacking, OR HURT, stop moving!
	if is_dead or is_attacking or is_hurt:
		velocity.x = 0
		move_and_slide()
		return
		
	for body in detection_area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			start_attack(body)
			return 
		
	if animated_sprite.animation != "move":
		animated_sprite.play("move")
		
	ai_timer -= delta
	if ai_timer <= 0 or is_on_wall():
		pick_new_direction()
		
	velocity.x = speed * direction
	
	if direction > 0:
		animated_sprite.flip_h = false # CHANGED to false
		bite_area.scale.x = 1 
	else:
		animated_sprite.flip_h = true  # CHANGED to true
		bite_area.scale.x = -1 

	move_and_slide()

func pick_new_direction():
	direction = [-1, 1].pick_random()
	ai_timer = randf_range(1.5, 3.5)

# --- COMBAT LOGIC ---

func start_attack(target: Node2D):
	is_attacking = true
	animated_sprite.play("attack")
	bite_shape.set_deferred("disabled", false)
	
	# Instantly snap to face the player
	if target.global_position.x > global_position.x:
		animated_sprite.flip_h = false # CHANGED to false
		direction = 1
		bite_area.scale.x = 1
	else:
		animated_sprite.flip_h = true  # CHANGED to true
		direction = -1
		bite_area.scale.x = -1

	await get_tree().create_timer(1.3).timeout
	
	# NEW: Cancel the bite if the skeleton died OR got staggered during the wind-up!
	if is_dead or is_hurt:
		return
		
	var bodies_in_mouth = bite_area.get_overlapping_bodies()
	
	for body in bodies_in_mouth:
		if body.has_method("take_damage"):
			body.take_damage(2) # NEW: Tell the player to take 2 damage!
			break 

func _on_combat_box_area_entered(area: Area2D) -> void:
	if is_dead: return
	if area.name == "SwordArea":
		take_hit() # We call a new function instead of die()

# NEW: The logic for getting hit
func take_hit():
	if is_dead or is_hurt: return # Don't get hit twice instantly
	
	health -= 1
	is_attacking = false # Cancel their attack if they were swinging
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
		var new_coin = COIN_SCENE.instantiate()
		get_parent().call_deferred("add_child", new_coin)
		new_coin.global_position = global_position
		queue_free() 
		
	elif animated_sprite.animation == "attack":
		is_attacking = false
		bite_shape.set_deferred("disabled", true)
		
	# NEW: Recover from being hit
	elif animated_sprite.animation == "got_hit":
		is_hurt = false
