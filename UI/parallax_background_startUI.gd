extends ParallaxBackground

var time_passed: float = 0.0
var start_x: float = 0.0

# You can tweak these!
var sway_distance: float = 100.0  # Moves 50px left and right
var sway_duration: float = 15.0   # Takes exactly 5 seconds for a full loop

func _ready() -> void:
	# Remember the exact starting position when the game boots up
	start_x = scroll_base_offset.x

func _process(delta: float) -> void:
	time_passed += delta
	
	# TAU is Godot's math magic for a full circle. 
	# Dividing it by 5.0 gives us the exact speed for a 5-second loop!
	var exact_speed = TAU / sway_duration
	
	var new_x = start_x + (sin(time_passed * exact_speed) * sway_distance)
	
	scroll_base_offset.x = new_x
