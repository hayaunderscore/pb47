extends Panel
class_name RCTPanel

var dragDist: float
var dir: Vector2
var newpos: Vector2
var dragging: bool = false
var mouse_in: bool = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and mouse_in:
			dragDist = position.distance_to(get_viewport().get_mouse_position())
			dir = (get_viewport().get_mouse_position() - position).normalized()
			dragging = true
			newpos = get_viewport().get_mouse_position() - dragDist * dir
		else:
			dragging = false
	elif event is InputEventMouseMotion:
		if dragging:
			newpos = get_viewport().get_mouse_position() - dragDist * dir

func _process(delta: float) -> void:
	if dragging:
		global_position += (newpos - position)
		global_position.x = max(0, min(global_position.x, 640 - size.x / 2))
		global_position.y = max(0, min(global_position.y, 360 - 4))

func _mouse_entered():
	mouse_in = true

func _mouse_exited():
	mouse_in = false

func _on_button_pressed() -> void:
	SoundManager.play_sfx("res://sfx/new/ui/rctclick.wav")
	visible = false
