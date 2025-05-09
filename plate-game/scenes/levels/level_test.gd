extends Node3D

# State variables
var dragging_collider: RigidBody3D = null
var mouse_position := Vector3.ZERO
var is_dragging := false
var vertical_offset := 0.0

# Movement settings
var drag_velocity := Vector3.ZERO
const DRAG_SMOOTH = 20.0
const BASE_LIFT_HEIGHT = 0
const VERTICAL_STEP = 0.1

@export var camera: Camera3D  

@export var cameras : Array[Camera3D]
var current_cam_index := 0

@export var csgTutupSaji: CSGCombiner3D

func _ready() -> void:
	print(camera)
	# buat ambil semua rigid bodies dengan kondisi tertentu
	var rigid_bodies = find_children("Plate*", "RigidBody3D", true, false)
	for body in rigid_bodies:
		print(body.name)
	
	

func _input(event: InputEvent) -> void:
	_handle_drag_input(event)
	_handle_camera_input(event)
	
func _process(delta: float) -> void:
	_update_drag(delta)
#	LIAT INI LIAT INI
	#var area_plates = csgTutupSaji.get_child()
	
func _handle_drag_input(event: InputEvent):
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
			vertical_offset = max(0, vertical_offset - VERTICAL_STEP)

func toggle_drag():
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
		if intersect and intersect.collider is RigidBody3D:
			dragging_collider = intersect.collider
			dragging_collider.set_collision_layer_value(1, false)
			dragging_collider.rotation = Vector3.ZERO  # Reset all rotation
			is_dragging = true
			mouse_position = dragging_collider.global_position  # Initialize position

func update_mouse_position(screen_pos: Vector2):
	var intersect = get_mouse_intersect(screen_pos)
	if intersect:
		mouse_position = intersect.position

func get_mouse_intersect(screen_pos: Vector2) -> Dictionary:
	var params = PhysicsRayQueryParameters3D.new()
	params.from = camera.project_ray_origin(screen_pos)
	params.to = camera.project_ray_normal(screen_pos) * 1000.0
	return get_world_3d().direct_space_state.intersect_ray(params)

func _update_drag(delta: float):
	if is_dragging and dragging_collider:
		var target_pos = mouse_position + Vector3(0, BASE_LIFT_HEIGHT + vertical_offset, 0)
		
		#drag_velocity = drag_velocity.lerp(
			#target_pos - dragging_collider.global_position,
			#DRAG_SMOOTH * delta
		#)
		#dragging_collider.global_position += drag_velocity
		
		# Check overlap test
		
		#if dragging_collider.is_colliding_while_dragged():
			#print("Collision detected while dragging!")
			## Visual feedback (e.g., change material)
			#$Highlight.material_override.albedo_color = Color(1, 0, 0, 0.5)
		
		dragging_collider.global_position = lerp(
			dragging_collider.global_position,
			target_pos,
			DRAG_SMOOTH * delta
		)

func _handle_camera_input(event: InputEvent):
	if event.is_action_pressed("switch_camera"):
		switch_camera((current_cam_index + 1) % cameras.size())

func switch_camera(index: int):
	for cam in cameras:
		cam.current = false
	
	# change active camera
	cameras[index].current = true
	current_cam_index = index
	camera = cameras[index]
