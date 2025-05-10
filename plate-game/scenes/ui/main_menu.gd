extends Node3D

@onready
var bowl: RigidBody3D = $BowlJago

@onready
var bowl2: RigidBody3D = $BowlJago2

var rotation_speed: float = 8.0
var vertical_speed: float = 2  # Units per second
var max_height: float = 4      # Maximum Y position
var start_height: float = -0.5  # Starting Y position (bottom)

func _ready() -> void:
	bowl.position.y = start_height
	bowl2.position.y = 1
	pass

func _process(delta: float) -> void:
	animate_bowl(bowl, delta)
	animate_bowl(bowl2, delta)

func animate_bowl(bowl: RigidBody3D, delta: float):
	if bowl:
		# Rotate bowl around Y-axis
		bowl.rotate_y(delta * rotation_speed)
		
		# Move bowl upwards
		bowl.position.y += vertical_speed * delta
		
		# Reset to start height if max height exceeded
		if bowl.position.y > max_height:
			bowl.position.y = start_height

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/Level1.tscn")

func _on_quit_button_pressed() -> void:
	# Quit the game
	get_tree().quit()
