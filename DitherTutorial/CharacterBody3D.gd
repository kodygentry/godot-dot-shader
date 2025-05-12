extends CharacterBody3D

@export var speed: float = 5.0
@export var gravity: float = -24.8
@export var jump_speed: float = 10.0  # Adjust as needed

func _physics_process(delta: float) -> void:
	var input_vector: Vector3 = Vector3.ZERO
	
	# Combine arrow keys and WASD for isometric movement.
	# Up: move up-left (northwest) => (-1, 0, -1)
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("w"):
		input_vector += Vector3(-1, 0, -1)
	# Left: move down-left (southwest) => (-1, 0, 1)
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("a"):
		input_vector += Vector3(-1, 0, 1)
	# Down: move down-right (southeast) => (1, 0, 1) 
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("s"):
		input_vector += Vector3(1, 0, 1)
	# Right: move up-right (northeast) => (1, 0, -1)
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("d"):
		input_vector += Vector3(1, 0, -1)
		
	# Normalize to avoid faster diagonal movement.
	if input_vector != Vector3.ZERO:
		input_vector = input_vector.normalized()
		
	# Set horizontal velocity.
	velocity.x = input_vector.x * speed
	velocity.z = input_vector.z * speed
	
	# Jump: if on the floor and space (ui_accept) is pressed, set upward velocity.
	if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
		velocity.y = jump_speed
		
	# Apply gravity if not on floor.
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Optionally reset vertical velocity when grounded.
		# velocity.y = 0
		pass
		
	move_and_slide()
