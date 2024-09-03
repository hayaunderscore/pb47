extends Node2D
class_name LevelScene

@export var musicPath: AudioStream

func _ready() -> void:
	if not SoundManager.is_playing(musicPath.resource_path):
		SoundManager.play_bgm(musicPath.resource_path)
