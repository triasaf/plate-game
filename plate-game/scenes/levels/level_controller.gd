extends Node3D

class_name LevelController

# State variables
var dragging_collider: RigidBody3D = null
var mouse_position := Vector3.ZERO
var is_dragging := false
var vertical_offset := 0.0

# Movement settings
var drag_velocity := Vector3.ZERO
const DRAG_SMOOTH: float = 20.0
const BASE_LIFT_HEIGHT: float = 0.0
const VERTICAL_STEP: float = 0.1

# Configurable level-specific nodes
@export var cameras: Array[Camera3D] = []
@export var current_cam_index: int = 0

@export var tutup_saji: CSGCombiner3D

@export var feedback_label: Label3D

# Current active camera
var camera: Camera3D

func _ready() -> void:
	# Initialize cameras
	if cameras.is_empty():
		push_warning("No cameras assigned. Searching for cameras in group 'LevelCameras'.")
		cameras = _find_nodes_in_group("LevelCameras", "Camera")
	
	if cameras.is_empty():
		push_error("No cameras found. Please assign cameras or use 'LevelCameras' group.")
	else:
		switch_camera(current_cam_index)
	
	# Log draggable objects for debugging
	var rigid_bodies = _find_nodes_in_group("Draggable", "")
	for body in rigid_bodies:
		print("Found draggable: ", body.name)
		
	# Initialize feedback label
	if feedback_label:
		feedback_label.text = ""
	else:
		push_warning("No feedback_label assigned. UI feedback will not be shown.")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reload"):
		get_tree().reload_current_scene()
	if event.is_action_pressed("submit"):
		check_draggable_objects()
	_handle_drag_input(event)
	_handle_camera_input(event)

func _process(delta: float) -> void:
	_update_drag(delta)

func _handle_drag_input(event: InputEvent) -> void:
	# Mouse movement updates position
	if event is InputEventMouseMotion:
		update_mouse_position(event.position)
	
	# Left click toggles drag
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			toggle_drag()
	
	# Vertical movement
	if is_dragging:
		if event.is_action_pressed("move_up"):
			vertical_offset += VERTICAL_STEP
		if event.is_action_pressed("move_down"):
			vertical_offset = max(0.0, vertical_offset - VERTICAL_STEP)

func toggle_drag() -> void:
	if is_dragging:
		# Release object
		if dragging_collider:
			dragging_collider.set_collision_layer_value(1, true)
			dragging_collider = null
		is_dragging = false
		vertical_offset = 0.0
	else:
		# Try to grab new object
		var intersect = get_mouse_intersect(get_viewport().get_mouse_position())
		if intersect and intersect.collider is RigidBody3D and intersect.collider.is_in_group("Draggable"):
			dragging_collider = intersect.collider
			dragging_collider.set_collision_layer_value(1, false)
			dragging_collider.rotation = Vector3.ZERO  # Reset all rotation
			is_dragging = true
			mouse_position = dragging_collider.global_position  # Initialize position

func update_mouse_position(screen_pos: Vector2) -> void:
	var intersect = get_mouse_intersect(screen_pos)
	if intersect:
		mouse_position = intersect.position

func get_mouse_intersect(screen_pos: Vector2) -> Dictionary:
	if not camera:
		return {}
	var params = PhysicsRayQueryParameters3D.new()
	params.from = camera.project_ray_origin(screen_pos)
	params.to = camera.project_ray_normal(screen_pos) * 1000.0
	return get_world_3d().direct_space_state.intersect_ray(params)

func _update_drag(delta: float) -> void:
	if is_dragging and dragging_collider:
		var target_pos = mouse_position + Vector3(0, BASE_LIFT_HEIGHT + vertical_offset, 0)
		dragging_collider.global_position = lerp(
			dragging_collider.global_position,
			target_pos,
			DRAG_SMOOTH * delta
		)

func _handle_camera_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_camera"):
		switch_camera((current_cam_index + 1) % cameras.size())

func switch_camera(index: int) -> void:
	for cam in cameras:
		cam.current = false
	
	if cameras.is_empty():
		return
	
	# Ensure index is valid
	current_cam_index = index % cameras.size()
	cameras[current_cam_index].current = true
	camera = cameras[current_cam_index]

func check_draggable_objects() -> void:
	if not tutup_saji:
		push_error("No CSGCombiner3D (tutup_saji) assigned.")
		return
	
	# Find the Area3D child of tutup_saji
	var area: Area3D = null
	area = tutup_saji.find_child("Area3D")
	
	if not area:
		push_error("No Area3D child found in tutup_saji.")
		return
	
	# Get all draggable objects
	var draggable_bodies = _find_nodes_in_group("Draggable", "")
	if draggable_bodies.is_empty():
		print("No draggable objects found.")
		return
	
	# Get overlapping bodies from Area3D
	var overlapping_bodies = area.get_overlapping_bodies()
	
	# Check each draggable object
	var all_valid = true
	for body in draggable_bodies:
		if not body in overlapping_bodies:
			print("Object ", body.name, " is not inside the Area3D.")
			all_valid = false
			continue
		
		# Check rotation (X and Z should be within ±45 degrees)
		var rotation = body.rotation_degrees
		if abs(rotation.x) > 45.0 or abs(rotation.z) > 45.0:
			print("Object ", body.name, " is not upright (X: ", rotation.x, ", Z: ", rotation.z, ").")
			all_valid = false
			continue
	
	if all_valid:
		print("All draggable objects are inside the Area3D and upright!")
		if feedback_label:
			switch_camera(3)
			feedback_label.text = "Level Complete!"
	else:
		print("Some draggable objects are not inside the Area3D or not upright.")
		if feedback_label:
			switch_camera(3)
			
			feedback_label.text = "Try Again! Press R to Reload"

func _find_nodes_in_group(group: String, node_prefix: String) -> Array:
	var nodes: Array = []
	for node in get_tree().get_nodes_in_group(group):
		if node.name.begins_with(node_prefix):
			nodes.append(node)
	return nodes
