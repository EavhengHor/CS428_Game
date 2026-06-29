extends Control

@onready var coin_label = $CoinLabel
@onready var buy_jump_button = $BuyJumpButton
@onready var buy_hadoken_button = $BuyHadokenButton
@onready var exit_label = $Exit # <-- NEW: Grabbed the new label!

var jump_price = 20
var hadoken_price = 50

func _ready() -> void:
	# Setting it in code guarantees it always displays the correct instruction
	exit_label.text = "Press G to exit Shop not ESC"
	update_shop_ui()

# This function updates the text and disables buttons if the player is broke!
func update_shop_ui():
	coin_label.text = "Your Coins: " + str(Global.total_coins)
	
	# --- Handle Double Jump Button ---
	if Global.unlocked_double_jump:
		buy_jump_button.text = "✔ Purchased"
		buy_jump_button.disabled = true
	elif Global.total_coins < jump_price:
		# Using \n pushes the price to the next line!
		buy_jump_button.text = "Double Jump\n - " + str(jump_price) + " Coins"
		buy_jump_button.disabled = true 
	else:
		buy_jump_button.text = "Double Jump\n - " + str(jump_price) + " Coins"
		buy_jump_button.disabled = false
		
	# --- Handle Hadoken Button ---
	if Global.unlocked_hadoken:
		buy_hadoken_button.text = "✔ Purchased"
		buy_hadoken_button.disabled = true
	elif Global.total_coins < hadoken_price:
		buy_hadoken_button.text = "Hadoken Spell\n - " + str(hadoken_price) + " Coins"
		buy_hadoken_button.disabled = true 
	else:
		buy_hadoken_button.text = "Hadoken Spell\n - " + str(hadoken_price) + " Coins"
		buy_hadoken_button.disabled = false

# --- SIGNALS ---

func _on_buy_jump_button_pressed() -> void:
	if Global.total_coins >= jump_price and not Global.unlocked_double_jump:
		Global.total_coins -= jump_price
		Global.unlocked_double_jump = true
		print("Bought Double Jump!")
		update_shop_ui()

func _on_buy_hadoken_button_pressed() -> void:
	if Global.total_coins >= hadoken_price and not Global.unlocked_hadoken:
		Global.total_coins -= hadoken_price
		Global.unlocked_hadoken = true
		print("Bought Hadoken!")
		update_shop_ui()
