extends Node2D

const NUM_LANDMARKS = 21
const HAND_CONNECTIONS = [
	# Wrist to fingers
	[0, 1], [1, 2], [2, 3], [3, 4],  # Thumb
	[0, 5], [5, 6], [6, 7], [7, 8],  # Index Finger
	[0, 9], [9, 10], [10, 11], [11, 12],  # Middle Finger
	[0, 13], [13, 14], [14, 15], [15, 16],  # Ring Finger
	[0, 17], [17, 18], [18, 19], [19, 20],  # Pinky

	# Palm connections
	[5, 9], [9, 13], [13, 17], [5, 17]
]
const HAND_LANDMARK = preload("res://scenes/hand_landmark.tscn")

@export var smooth_factor = 0.5
var landmarks = []
var line_node
var screen_size
var prev_coords = []# List of Vec2D for previous coords of each landmarks

func _ready() -> void:
	screen_size = DisplayServer.screen_get_size()
	
	# Create hand made of hand_landmark
	for i in range(NUM_LANDMARKS):
		var point = HAND_LANDMARK.instantiate()
		add_child(point)
		point.visible = false  # Hide initially
		landmarks.append(point)
		
	# Create line to connect landmarks
	line_node = Line2D.new()
	line_node.default_color = Color(0, 0, 0) # Black
	line_node.width = 2
	line_node.visible = false  # Hide initially
	add_child(line_node)
	
	# Initialize 21 landmarks previous coordinates
	# Even though the original position is 0,0, we use null so that there is no
	# initial drag when the game first starts
	for i in range(NUM_LANDMARKS):
		prev_coords.append(null)

func _on_udp_server_landmarks_received(data: Variant) -> void:
	# Check if any hand data is available
	if "hands" in data and data["hands"].size() > 0:
		var hand_data = data["hands"][0]

		# Convert hand position relative to the player's local space
		var hand_center_x = -1 * (hand_data[0].x - 0.5) * screen_size.x
		var hand_center_y = -1 * (0.5 - hand_data[0].y) * screen_size.y
		var hand_center = Vector2(hand_center_x, hand_center_y)

		# Set the hand's position relative to player
		position = hand_center  # No need to adjust with parent's position since it's already a child

		# Make everything visible when a hand is detected
		line_node.visible = true
		for i in range(NUM_LANDMARKS):
			landmarks[i].visible = true
			var x = -1 * (hand_data[i].x - 0.5) * screen_size.x
			var y = -1 * (0.5 - hand_data[i].y) * screen_size.y
			var new_position = Vector2(x, y) - hand_center
			
			# Apply smoothing
			var smoothed_position = smooth_coords(prev_coords[i], new_position, smooth_factor)
			landmarks[i].position = smoothed_position
			
			# Update previous coordinates
			prev_coords[i] = smoothed_position

		# Update hand connections
		line_node.clear_points()
		for connection in HAND_CONNECTIONS:
			line_node.add_point(landmarks[connection[0]].position)
			line_node.add_point(landmarks[connection[1]].position)

	else:
		# No hand detected, start the timer
		line_node.visible = false
		for i in range(NUM_LANDMARKS):
			landmarks[i].visible = false

func smooth_coords(prev, current, factor):
	if prev == null:
		return current
	# Calculate a new Vec2D 
	var x = factor * current.x + (1 - factor) * prev.x
	var y = factor * current.y + (1 - factor) * prev.y
	return Vector2(x, y)
