extends Control

@onready var left: Control = $Left
@onready var right: Control = $Right
@onready var top: Control = $Top
@onready var bottom: Control = $Bottom

var timer: float = 0.0
var increase_timer: bool = false

@onready var editor: LevelEditor = get_parent().get_parent()

func _ready() -> void:
	left.connect("mouse_exited", exited)
	right.connect("mouse_exited", exited)
	top.connect("mouse_exited", exited)
	bottom.connect("mouse_exited", exited)

func entered():
	increase_timer = true

func exited():
	increase_timer = false
	timer = 0

func _on_top_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		timer += get_process_delta_time()
	if timer > 0.5:
		editor.edit_target.translate(Vector2.UP * editor.MOVE_SPEED)

func _on_bottom_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		timer += get_process_delta_time()
	if timer > 0.5:
		editor.edit_target.translate(Vector2.DOWN * editor.MOVE_SPEED)

func _on_left_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		timer += get_process_delta_time()
	if timer > 0.5:
		editor.edit_target.translate(Vector2.LEFT * editor.MOVE_SPEED)

func _on_right_gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		timer += get_process_delta_time()
	if timer > 0.5:
		editor.edit_target.translate(Vector2.RIGHT * editor.MOVE_SPEED)
