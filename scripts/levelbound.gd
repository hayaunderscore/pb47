extends Node2D
class_name LevelBound

@export_range(0, 1) var type: int = 0

func _ready() -> void:
	var pcam = Map.player.phantomCamera
	# Set limit target to null to set limits automatically
	pcam.set_limit_target("")
	match type:
		0:
			pcam.limit_top = global_position.y
			pcam.limit_left = global_position.x
		1:
			pcam.limit_right = global_position.x
			pcam.limit_bottom = global_position.y
	queue_free()
