
extends Resource
class_name MovementProfile

@export_group("Basic Movement")
@export var movement_speed: float = 5.0
@export var sprint_speed: float = 9.0
@export var jump_velocity: float = 5.5

@export_group("Movement Options")
@export var allow_sprint: bool = true
@export var use_shooter_physics: bool = false

@export_group("Shooter Physics")
@export var ground_acceleration: float = 35.0
@export var ground_friction: float = 12.0
@export var air_acceleration: float = 8.0
