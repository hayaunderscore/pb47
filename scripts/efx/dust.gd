extends AnimatedSprite2D

var velocity: Vector2

func _process(delta: float) -> void:
	scale.x = move_toward(scale.x, 0, 4 * delta)
	scale.y = scale.x
	if scale.x <= 0:
		queue_free()
	global_position += velocity
