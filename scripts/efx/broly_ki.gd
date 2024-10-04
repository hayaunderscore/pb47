extends Circle2D
class_name BrolyKi

var time: float = 0

func _ready() -> void:
	@warning_ignore("integer_division")
	radius = 1600/2

func _process(_delta: float) -> void:
	radius = move_toward(radius, 0.0, 0.64*40)
	if radius <= 0:
		queue_free()
