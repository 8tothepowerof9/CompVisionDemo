extends CharacterBody2D

@export var speed = 300.0

func _physics_process(delta: float) -> void:
	var direction = Vector2.ZERO  # Initialize direction

	# Get input direction
	if Input.is_action_pressed("move_right"):
		direction.x += 10
	if Input.is_action_pressed("move_left"):
		direction.x -= 10
	if Input.is_action_pressed("move_down"):
		direction.y += 10
	if Input.is_action_pressed("move_up"):
		direction.y -= 10

	# Normalize direction to prevent faster diagonal movement
	if direction.length() > 0:
		direction = direction.normalized()

	# Apply velocity
	velocity = direction * speed 

	move_and_slide()
