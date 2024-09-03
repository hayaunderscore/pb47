extends Sprite2D
class_name SpinnyBoi

var velocity: Vector2
var rotspeed: int = 0
var player: Node2D

func _enter_tree() -> void:
	velocity.y = randf_range(-10, -15)
	var og_scale = scale
	if player != null:
		velocity.x = sign(global_position.x - player.global_position.x) * randf_range(5, 10)
		scale.x = -sign(global_position.x - player.global_position.x)
	if scale.x != 1 and scale.x != -1:
		velocity.x = randf_range(-10, 10)
	scale = og_scale
	rotspeed = randi_range(2, 10)
		
func _process(delta: float) -> void:
	rotation_degrees += rotspeed
	velocity.y += 50 * delta
	global_position += velocity

func screen_exit() -> void:
	call_deferred("queue_free")
