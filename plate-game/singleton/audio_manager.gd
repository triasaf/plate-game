extends Node3D

var sound_effect_dict: Dictionary = {}
@export var sound_effects: Array[SoundEffect]

# Store the looping drag audio player
var drag_audio_player: AudioStreamPlayer = null

func _ready() -> void:
	for sound_effect: SoundEffect in sound_effects:
		sound_effect_dict[sound_effect.type] = sound_effect

func create_audio(type: SoundEffect.SOUND_EFFECT_TYPE) -> void:
	if sound_effect_dict.has(type):
		var sound_effect: SoundEffect = sound_effect_dict[type]
		if sound_effect.has_open_limit():
			sound_effect.change_audio_count(1)
			var new_audio: AudioStreamPlayer = AudioStreamPlayer.new()
			add_child(new_audio)
			new_audio.stream = sound_effect.sound_effect
			new_audio.volume_db = sound_effect.volume
			new_audio.pitch_scale = sound_effect.pitch_scale
			new_audio.finished.connect(sound_effect.on_audio_finished)
			new_audio.finished.connect(new_audio.queue_free)
			new_audio.play()
	else:
		push_error("Audio Manager failed to find setting for type ", type)

# Start or restart the looping drag sound
func start_or_restart_drag_audio(type: SoundEffect.SOUND_EFFECT_TYPE, pitch_scale: float) -> void:
	if sound_effect_dict.has(type):
		var sound_effect: SoundEffect = sound_effect_dict[type]
		if sound_effect.has_open_limit():
			# If already playing, stop and restart
			if drag_audio_player:
				var current_sound_effect: SoundEffect = sound_effect_dict.get(type)
				if current_sound_effect:
					current_sound_effect.change_audio_count(-1)
				drag_audio_player.queue_free()
				drag_audio_player = null
			# Create new audio player
			sound_effect.change_audio_count(1)
			drag_audio_player = AudioStreamPlayer.new()
			add_child(drag_audio_player)
			drag_audio_player.stream = sound_effect.sound_effect
			drag_audio_player.volume_db = sound_effect.volume
			drag_audio_player.pitch_scale = pitch_scale
			drag_audio_player.play()
		else:
			push_error("Drag audio limit reached for type ", type)
	else:
		push_error("Failed to start drag audio for type ", type)

# Update the pitch of the drag audio
func update_drag_audio_pitch(pitch_scale: float) -> void:
	if drag_audio_player:
		drag_audio_player.pitch_scale = pitch_scale

# Stop the drag audio
func stop_drag_audio() -> void:
	if drag_audio_player:
		var sound_effect: SoundEffect = sound_effect_dict.get(SoundEffect.SOUND_EFFECT_TYPE.ON_PLATE_DRAG)
		if sound_effect:
			sound_effect.change_audio_count(-1)
		drag_audio_player.queue_free()
		drag_audio_player = null
