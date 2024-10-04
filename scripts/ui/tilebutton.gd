extends Button
class_name TileButton

signal tile_pressed(button, id, selected)

var id: int = 0
var had_mouse: bool = false

func _ready() -> void:
	mouse_entered.connect(_mouse_entered)
	mouse_exited.connect(_mouse_exited)

func _mouse_entered():
	had_mouse = true

func _mouse_exited():
	had_mouse = false

func _toggled(toggled_on: bool) -> void:
	tile_pressed.emit(self, self.id, toggled_on)
