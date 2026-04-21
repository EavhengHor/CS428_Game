extends Area2D

var speed = 100.0 # Slightly slower than the player's Hadoken so it can be dodged!
var direction = 1 
var lifetime_seconds = 3.0 

@onready var animated_sprite = $AnimatedSprite2D

func _ready() -> void:
	animated_sprite.play("default") 
	
	if direction < 0:
		animated_sprite.flip_h = true
		
	await get_tree().create_timer(lifetime_seconds).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	global_position.x += speed * direction * delta

# Connect this to "body_entered"
func _on_body_entered(body: Node2D) -> void:
	# If it hits a wall, destroy it. (We ignore other enemies so they don't shoot each other!)
	if not body.is_in_group("Enemies") and body.name != "Enemy_Ghost":
		# Did it hit the Player?
		if body.has_method("take_damage"):
			body.take_damage(1) # Deals 1 damage to the player
			
		queue_free()
