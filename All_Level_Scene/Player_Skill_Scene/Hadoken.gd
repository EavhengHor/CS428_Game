extends Area2D

var speed = 250.0 
var direction = 1 # 1 means it will fly to the Right! (-1 would be left)
var lifetime_seconds = 3.0 # <-- CHANGED: Now it will last exactly 3 seconds!

@onready var animated_sprite = $AnimatedSprite2D

func _ready() -> void:
	# Make sure the animation plays automatically
	animated_sprite.play("default") # Change "default" if your animation has a different name
	
	# Flip the sprite so the fireball faces the correct way
	if direction < 0:
		animated_sprite.flip_h = true
		
	# --- THE DISAPPEAR TIMER ---
	# Wait for 1.5 seconds, then delete itself so it doesn't fly forever
	await get_tree().create_timer(lifetime_seconds).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# Move forward in a perfectly straight line every single frame!
	global_position.x += speed * direction * delta

# --- COLLISION LOGIC ---

# 1. Hitting Walls or Floors (Connect this via the "body_entered" signal)
func _on_body_entered(body: Node2D) -> void:
	# If it hits a wall/floor, destroy the fireball!
	# We ignore the Player so it doesn't instantly explode in your face
	if body.name != "Player" and not body.has_method("take_damage"):
		queue_free()

# 2. Hitting Enemies (Connect this via the "area_entered" signal)
func _on_area_entered(area: Area2D) -> void:
	# Because your enemies use an Area2D called "CombatBox" to take hits:
	if area.name == "CombatBox":
		var enemy = area.get_parent()
		# Tell the enemy it got hit!
		if enemy.has_method("take_hit"):
			enemy.take_hit() 
			queue_free() # Destroy the fireball upon impact
