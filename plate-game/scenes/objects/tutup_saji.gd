extends StaticBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	check_plate_arrangement()

func check_plate_arrangement():
	var output = "Inside : ["
	
	var all_valid = true
	var plates = $Area3D.get_overlapping_bodies()
	
	
	for plate in plates:
		if plate is RigidBody3D:
			output += plate.name
			output += " "
	output += " ]"
	
	#print(output)
	
	return all_valid
