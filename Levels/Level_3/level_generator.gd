extends Node2D

# --- MAP DIMENSIONS ---
@export var map_width = 400 
@export var map_height = 150

# --- PROCEDURAL SETTINGS ---
# Lower frequency = massive continents and deep sprawling caves
@export var noise_frequency = 0.02 #0.02
# Lower threshold = more connected land
@export var land_threshold = 0.0

@onready var tile_map = $TileMap

# In Godot 4, Terrain Sets and Terrains are indexed starting at 0
var terrain_set_id = 0 
var terrain_id = 0     

func _ready():
	# Scramble the random number generator so it's unique every time you hit Play
	randomize() 
	generate_procedural_map()

func generate_procedural_map():
	# 1. Configure the mathematical noise brush
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	# Fractals add rough, jagged, realistic details to the edges of your massive shapes
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4 #4
	noise.frequency = noise_frequency
	
	tile_map.clear()
	var land_cells = [] 
	
	# 2. Scan the massive grid to draw the organic shapes
	for x in range(map_width):
		for y in range(map_height):
			
			var noise_val = noise.get_noise_2d(x, y)
			
			# If the noise is high enough, place land
			if noise_val > land_threshold:
				land_cells.append(Vector2i(x, y))
				
	# 3. SOLID LEVEL BORDERS (WALLS & BEDROCK)
	# This seals the entire map in a giant box so the player can't fall off!
	for x in range(map_width):
		for y in range(map_height):
			# If we are at the bottom 5 rows, the far left column, or the far right column...
			if y >= map_height - 5 or x == 0 or x == map_width - 1:
				var border_pos = Vector2i(x, y)
				# Add it to the map if it isn't already there
				if not land_cells.has(border_pos):
					land_cells.append(border_pos)
				
	# 4. Tell Godot to draw the terrain and auto-connect everything
	tile_map.set_cells_terrain_connect(0, land_cells, terrain_set_id, terrain_id)
	
	print("EPIC Map Generation Complete! Placed ", land_cells.size(), " tiles.")
