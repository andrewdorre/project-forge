
extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 9.0
@export var jump_velocity: float = 5.5
@export var mouse_sensitivity: float = 0.002

@onready var camera_pivot: Node3D = $CameraPivot
@onready var first_person: Camera3D = $CameraPivot/FirstPersonCamera
@onready var third_person: Camera3D = $CameraPivot/CameraArm/ThirdPersonCamera
@onready var visual: MeshInstance3D = $Visual
@export var gamepad_look_speed: float = 3.0

@export var movement_profile: MovementProfile
@export var rpg_profile: MovementProfile
@export var shooter_profile: MovementProfile

var third_person_enabled: bool = false
var gravity: float = 9.8
var sprint_toggled: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	first_person.make_current()
	visual.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * mouse_sensitivity)
			camera_pivot.rotate_x(
				-event.relative.y * mouse_sensitivity
			)
			camera_pivot.rotation.x = clamp(
				camera_pivot.rotation.x,
				deg_to_rad(-85),
				deg_to_rad(85)
			)

	if event.is_action_pressed("toggle_camera"):
		toggle_camera()

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton:
		if event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	if event.is_action_pressed("toggle_movement_profile"):
		switch_movement_profile()


func toggle_camera() -> void:
	third_person_enabled = not third_person_enabled

	if third_person_enabled:
		third_person.make_current()
		visual.visible = true
	else:
		first_person.make_current()
		visual.visible = false



func _physics_process(delta: float) -> void:
	if movement_profile == null:
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = movement_profile.jump_velocity

	# Keyboard and gamepad movement
	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
        "move_backward"
	)

	# Convert local input into world-space direction.
	# Keep analog stick magnitude for variable speed.
	var direction := (
		transform.basis * Vector3(
			input_dir.x,
			0.0,
			input_dir.y
		)
	)

	# RPG MOVEMENT
	if not movement_profile.use_shooter_physics:

		# Toggle sprint
		if Input.is_action_just_pressed("sprint"):
			sprint_toggled = not sprint_toggled

		# Stop sprinting when movement stops
		if input_dir.length_squared() < 0.01:
			sprint_toggled = false

		var speed := movement_profile.movement_speed

		if movement_profile.allow_sprint and sprint_toggled:
			speed = movement_profile.sprint_speed

		# Preserve our original RPG movement behavior
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

	# BOOMER SHOOTER MOVEMENT
	else:
		# Shooter always moves fast; no sprint needed
		sprint_toggled = false

		var target_velocity := (
			direction * movement_profile.movement_speed
		)

		var horizontal_velocity := Vector3(
			velocity.x,
			0.0,
			velocity.z
		)

		if is_on_floor():

			if input_dir.length_squared() < 0.01:
				# Gradually slow down when movement stops
				horizontal_velocity = horizontal_velocity.move_toward(
					Vector3.ZERO,
					movement_profile.ground_friction * delta
				)
			else:
				# Accelerate toward the desired direction
				horizontal_velocity = horizontal_velocity.move_toward(
					target_velocity,
					movement_profile.ground_acceleration * delta
				)

		else:
			# Allow steering while airborne
			horizontal_velocity = horizontal_velocity.move_toward(
				target_velocity,
				movement_profile.air_acceleration * delta
			)

		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.z

	move_and_slide()




func _process(delta: float) -> void:
	var look_input := Input.get_vector(
		"look_left",
		"look_right",
		"look_up",
        "look_down"
	)

	if look_input.length_squared() > 0.0:
		rotate_y(
			-look_input.x * gamepad_look_speed * delta
		)

		camera_pivot.rotate_x(
			-look_input.y * gamepad_look_speed * delta
		)

		camera_pivot.rotation.x = clamp(
			camera_pivot.rotation.x,
			deg_to_rad(-85),
			deg_to_rad(85)
		)


func switch_movement_profile() -> void:
	if movement_profile == rpg_profile:
		movement_profile = shooter_profile
		print("Movement Profile: SHOOTER")
	else:
		movement_profile = rpg_profile
		print("Movement Profile: RPG")

	sprint_toggled = false
