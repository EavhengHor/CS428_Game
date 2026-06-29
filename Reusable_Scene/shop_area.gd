extends Area2D

# This allows you to drag your shop_menu.tscn into the Inspector!
@export var shop_menu_scene: PackedScene 

var player_in_range = false
var shop_is_open = false

@onready var prompt_label = $PromptLabel
@onready var shop_layer = $ShopLayer

func _ready() -> void:
	prompt_label.hide() # Hide the prompt when the game starts

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player": 
		player_in_range = true
		prompt_label.show()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false
		prompt_label.hide()
		close_shop() # Auto-close the shop if the player walks away!

func _process(delta: float) -> void:
	# If they are close by and press the 'G' key...
	if player_in_range and Input.is_action_just_pressed("interact"):
		if shop_is_open:
			close_shop()
		else:
			open_shop()

func open_shop():
	# Make sure we actually assigned the scene and it isn't already open
	if shop_menu_scene != null and not shop_is_open:
		var shop_ui = shop_menu_scene.instantiate()
		shop_ui.name = "ActiveShopUI"
		
		# Add the UI to the CanvasLayer so it locks to the screen
		shop_layer.add_child(shop_ui)
		
		shop_is_open = true
		prompt_label.text = "Press G to Close"
	elif shop_menu_scene == null:
		print("ERROR: You forgot to assign the Shop Menu Scene in the Inspector!")

func close_shop():
	if shop_is_open:
		# Find the open shop and destroy it
		var shop_ui = shop_layer.get_node_or_null("ActiveShopUI")
		if shop_ui != null:
			shop_ui.queue_free()
			
		shop_is_open = false
		prompt_label.text = "Press G to Shop"
