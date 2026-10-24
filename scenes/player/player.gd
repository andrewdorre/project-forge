
extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 9.0
@export var jump_velocity: float = 5.5
@export var mouse_sensitivity: float = 0.002

@onready var camera_pivot: Node3D = $CameraPivot
@onready var first_person: Camera3D = $CameraPivot/FirstPersonCamera
@onready var third_person: Camera3D = $CameraPivot/CameraArm/ThirdPersonCamera
@onready var visual: MeshInstance3D = $Visual

var third_person_enabled: bool = false
var gravity: float = 9.8


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


func toggle_camera() -> void:
	third_person_enabled = not third_person_enabled

	if third_person_enabled:
		third_person.make_current()
		visual.visible = true
	else:
		first_person.make_current()
		visual.visible = false


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
        "move_backward"
	)

	var direction := (
		transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	).normalized()

	var speed := walk_speed

	if Input.is_action_pressed("sprint"):
		speed = sprint_speed

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	move_and_slide()
