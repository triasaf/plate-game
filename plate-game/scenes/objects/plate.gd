extends RigidBody3D

var overlapping_bodies = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AreaDetect.collision_mask = 0b0010  # Example: Only layer 2
	$AreaDetect.body_entered.connect(_on_body_entered)
	$AreaDetect.body_exited.connect(_on_body_exited)


func _on_body_entered(body):
	if body != self and body.is_in_group("stackable"):
		overlapping_bodies.append(body)

func _on_body_exited(body):
	overlapping_bodies.erase(body)

func is_colliding_while_dragged() -> bool:
	
	return overlapping_bodies.size() > 0

func get_colliding_normal() -> Vector3:
	# Optional: Calculate average collision normal
	if overlapping_bodies.is_empty():
		return Vector3.UP
	return (global_position - overlapping_bodies[0].global_position).normalized()
