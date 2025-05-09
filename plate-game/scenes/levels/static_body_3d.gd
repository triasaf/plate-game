extends StaticBody3D

@export var target_height := 0  # Height above RigidBody3Ds where it stops
@export var fall_speed := 5     # Units per second
@export var start_delay := 1.0    # Seconds before starting to fall

var should_fall := false

func _ready():
	# Make invisible and non-collidable at start
	visible = false
	collision_layer = 0
	
	# Start the delay timer
	await get_tree().create_timer(start_delay).timeout
	
	# Make visible and start falling
	visible = true
	collision_layer = 1
	should_fall = true

func _physics_process(delta):
	if should_fall and global_position.y > target_height:
		global_position.y -= fall_speed * delta
	elif global_position.y <= target_height:
		should_fall = false
		
