extends StaticBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var solid_collision = $CollisionShape2D # The physical wall that blocks movement
@onready var detection_area = $DetectionArea     # The trigger zone you scaled

var is_opening = false
var player_is_near = false

func _ready() -> void:
	# Always start as a solid, closed wall
	animated_sprite.play("closed")

func _process(_delta: float) -> void:
	if is_opening:
		return

	# Trigger the destruction ONLY if they have 3 keys AND stand in your custom range!
	if Global.keys_collected >= 3 and player_is_near:
		is_opening = true
		animated_sprite.play("open_full")

# --- SIGNALS ---

# 1. Connect the DetectionArea's 'body_entered' signal here!
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.has_method("take_damage"):
		player_is_near = true

# 2. Connect the DetectionArea's 'body_exited' signal here!
func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.has_method("take_damage"):
		player_is_near = false

# 3. Connect the AnimatedSprite2D's 'animation_finished' signal here!
func _on_animated_sprite_2d_animation_finished() -> void:
	# Only clear the physical barrier AFTER the 12 frames of destruction are completely done
	if animated_sprite.animation == "open_full":
		solid_collision.set_deferred("disabled", true)
		
		# Reset the keys so the player is ready for the next level
		Global.keys_collected = 0
		print("The wall has crumbled! You can pass.")
