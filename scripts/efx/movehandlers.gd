extends Control

@export var dir: Vector2
@export var editor: LevelEditor

var timer: float = 0.0
var should_time: bool = false

func _ready() -> void:
	mouse_entered.connect(entered)
	mouse_exited.connect(exited)

func _process(delta: float) -> void:
	if should_time and timer > 0.25 and editor.edit_active:
		editor.edit_target.translate(dir * editor.MOVE_SPEED)
	if should_time:
		timer += delta

func entered():
	should_time = true

func exited():
	should_time = false
	timer = 0
