extends Node

var music_player: AudioStreamPlayer

func _ready() -> void:
	# Create and configure AudioStreamPlayer
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = &"Music"  # Optional: Use a dedicated audio bus
	music_player.volume_db = -10.0  # Adjust volume (in decibels)
	
	# Load and play background music
	var music = load("res://assets/jedag-jedug-gamelan-free-for-use-328514.mp3")  # Update path to your audio file
	if music:
		music_player.stream = music
		music_player.play()
	else:
		push_error("Failed to load background music at res://assets/jedag-jedug-gamelan-free-for-use-328514.mp3")

func play_music(stream: AudioStream) -> void:
	if music_player and stream:
		music_player.stream = stream
		music_player.play()

func stop_music() -> void:
	if music_player:
		music_player.stop()

func set_volume(db: float) -> void:
	if music_player:
		music_player.volume_db = db
