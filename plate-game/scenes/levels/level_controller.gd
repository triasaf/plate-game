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

# Tracking variables
var drag_count: int = 0
var start_time: float = 0.0
var submit_time: float = 0.0

var submit_count: int = 0
var max_submit_count: int = 3

# Mouse velocity tracking for drag sound
var last_mouse_screen_pos: Vector2 = Vector2.ZERO
var mouse_velocity: float = 0.0
var was_above_threshold: bool = false
const VELOCITY_THRESHOLD: float = 150  # Pixels per second to trigger sound

# State variables
var is_waiting_for_continue: bool = false
var is_game_over: bool = false
var is_level_complete: bool = false

# Configurable level-specific nodes
@export var cameras: Array[Camera3D] = []
@export var current_cam_index: int = 0

@export var tutup_saji: CSGCombiner3D

@export var feedback_label: Label3D

@export var guide_ui: Control

@export var level: int

# for cinematics
@export var tutup_solid: CSGCombiner3D

# Current active camera
var camera: Camera3D

func tutup_solid_closed():
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.ON_COVER_PLACED)
	

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
	
	# Initialize tutup_saji and tutup_solid visibility
	if tutup_saji:
		tutup_saji.visible = true
	else:
		push_error("No tutup_saji assigned.")
	if tutup_solid:
		tutup_solid.visible = false
	else:
		push_error("No tutup_solid assigned.")
	
	# Initialize tracking
	drag_count = 0
	start_time = Time.get_ticks_msec() / 1000.0
	
	# Initialize last mouse position
	last_mouse_screen_pos = get_viewport().get_mouse_position()
	

func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("hide"):
		var controls_text:RichTextLabel = guide_ui.find_child("Controls")
		
		if controls_text:
			controls_text.visible = !controls_text.visible
	
	# Always allow reload
	if event.is_action_pressed("reload"):
		get_tree().reload_current_scene()
		return
	
	# Handle level complete (load next level)
	if is_level_complete and event.is_action_pressed("submit") and level == 1:
		get_tree().change_scene_to_file("res://scenes/levels/Level2.tscn")
		return
	
	if is_level_complete and event.is_action_pressed("submit") and level == 2:
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
		return
	
	# Handle continue after failed submit
	if is_waiting_for_continue and event.is_action_pressed("submit"):
		is_waiting_for_continue = false
		tutup_saji.visible = true
		tutup_solid.visible = false
		tutup_solid.global_position = tutup_saji.global_position + Vector3(0, 6, 0)
		if feedback_label:
			feedback_label.text = ""
		return
	
	# Block inputs during game over or waiting for continue
	if is_game_over or is_waiting_for_continue:
		return
	
	# Normal gameplay inputs
	if event.is_action_pressed("submit"):
		check_draggable_objects()
	_handle_drag_input(event)
	_handle_camera_input(event)

func _process(delta: float) -> void:
	_update_drag(delta)
	_update_mouse_velocity(delta)

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
			# play sfx on plate placed
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.ON_PLATE_PLACED)
			AudioManager.stop_drag_audio()  # Stop drag sound
			
			dragging_collider.set_collision_layer_value(1, true)
			dragging_collider = null
		is_dragging = false
		vertical_offset = 0.0
	else:
		# Try to grab new object
		var intersect = get_mouse_intersect(get_viewport().get_mouse_position())
		if intersect and intersect.collider is RigidBody3D and intersect.collider.is_in_group("Draggable"):
			# play sfx on plate pickup
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.ON_PLATE_PICKUP)
			
			dragging_collider = intersect.collider
			dragging_collider.set_collision_layer_value(1, false)
			dragging_collider.rotation = Vector3.ZERO  # Reset all rotation
			is_dragging = true
			mouse_position = dragging_collider.global_position  # Initialize position
			drag_count += 1  # Increment drag count

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

func _update_mouse_velocity(delta: float) -> void:
	var current_mouse_pos = get_viewport().get_mouse_position()
	var distance = current_mouse_pos.distance_to(last_mouse_screen_pos)
	mouse_velocity = distance / delta if delta > 0 else 0.0
	last_mouse_screen_pos = current_mouse_pos
	
	# Update drag sound if dragging
	if is_dragging:
		var min_velocity = VELOCITY_THRESHOLD
		var max_velocity = 1000.0
		var min_pitch = 0.5
		var max_pitch = 2.0
		var normalized_velocity = clamp((mouse_velocity - min_velocity) / (max_velocity - min_velocity), 0.0, 1.0)
		var pitch_scale = lerp(min_pitch, max_pitch, normalized_velocity)
		
		# Check if velocity crosses the threshold
		if mouse_velocity >= VELOCITY_THRESHOLD and not was_above_threshold:
			AudioManager.start_or_restart_drag_audio(SoundEffect.SOUND_EFFECT_TYPE.ON_PLATE_DRAG, pitch_scale)
			was_above_threshold = true
		elif mouse_velocity >= VELOCITY_THRESHOLD and was_above_threshold:
			AudioManager.update_drag_audio_pitch(pitch_scale)
		elif mouse_velocity < VELOCITY_THRESHOLD and was_above_threshold:
			AudioManager.stop_drag_audio()
			was_above_threshold = false

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
	var area_inside: Area3D = null
	area_inside = tutup_saji.find_child("Area3D")
	
	var area_outside: Area3D = null
	area_outside = tutup_saji.find_child("AreaOutside")
	
	if not area_inside:
		push_error("No Area3D child found in tutup_saji.")
		return
	
	if not area_outside:
		push_error("No AreaOutisde child found in tutup_saji.")
		return
	
	# Record submit time
	submit_time = Time.get_ticks_msec() / 1000.0
	
	submit_count += 1
	
	# Get all draggable objects
	var draggable_bodies = _find_nodes_in_group("Draggable", "")
	if draggable_bodies.is_empty():
		print("No draggable objects found.")
		return
	
	# Get overlapping bodies from Area3D
	var overlapping_bodies = area_inside.get_overlapping_bodies()
	
	# Get overlapping bodies from AreaOutside meaning objects that are outside
	var overlapping_bodies_outside = area_outside.get_overlapping_bodies()
	
	# Check each draggable object
	var all_valid = true
	for body in draggable_bodies:
		if not body in overlapping_bodies:
			print("Object ", body.name, " is not inside the Area3D.")
			all_valid = false
			continue
		
		if body in overlapping_bodies_outside:
			print("Object ", body.name, " is intersecting the AreaOutside.")
			all_valid = false
			continue
		
		# Check rotation (X and Z should be within ±45 degrees)
		var rotation = body.rotation_degrees
		if abs(rotation.x) > 45.0 or abs(rotation.z) > 45.0:
			print("Object ", body.name, " is not upright (X: ", rotation.x, ", Z: ", rotation.z, ").")
			all_valid = false
			continue
	
	# Create tween for tutup_solid animation
	var tween = create_tween()
	if tutup_saji and tutup_solid:
		tutup_saji.visible = false
		tutup_solid.visible = true
		var target_pos = tutup_saji.global_position
		tween.tween_property(tutup_solid, "global_position", target_pos, 1.0)
		# Periodically check distance during tween
		var sound_played = false
		tween.tween_callback(func():
			if !sound_played and tutup_solid.global_position.distance_to(target_pos) < 1.3:
				AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.ON_COVER_PLACED)
				sound_played = true
		)
			
	
	if all_valid:
		var elapsed_time = submit_time - start_time
		is_level_complete = true
		print("All draggable objects are inside the Area3D and upright! Drags: ", drag_count, ", Time: ", elapsed_time, "s")
		if feedback_label:
			switch_camera(0)
			tween.tween_callback(func():
				feedback_label.text = "Level Complete\nDrag Count: %d\nTime: %.1fs\nPress Enter to Continue" % [drag_count, elapsed_time]
			)
		
	else:
		print("Some draggable objects are not inside the Area3D, intersecting AreaOutside, or not upright.")
		print("Submit count: ", submit_count)
		if feedback_label:
			switch_camera(0)
			if submit_count >= max_submit_count:
				is_game_over = true
				tween.tween_callback(func():
					feedback_label.text = "YOU LOSE !!\nPress R to Retry"
				)
			else:
				is_waiting_for_continue = true
				tween.tween_callback(func():
					feedback_label.text = "Some plates are not fully inside the Area or not upright.\nKeep Trying! \nYou have %s tries left\nPress Enter to Continue" % [max_submit_count - submit_count]
				)

func _find_nodes_in_group(group: String, node_prefix: String) -> Array:
	var nodes: Array = []
	for node in get_tree().get_nodes_in_group(group):
		if node.name.begins_with(node_prefix):
			nodes.append(node)
	return nodes
