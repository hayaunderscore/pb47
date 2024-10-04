extends Button

var lastScale: Vector2
@export var cursor: Sprite2D
@export var cursor_anim: AnimationPlayer

func _ready() -> void:
	lastScale = scale
	pivot_offset = Vector2(20, 20)
	mouse_entered.connect(_mouse_entered)
	mouse_exited.connect(_mouse_exited)
	button_down.connect(_button_down)
	button_up.connect(_button_up)

func set_icon_offset(row: int):
	if icon is not AtlasTexture: return
	var atlas = icon as AtlasTexture
	atlas.region.position.y = 32 * row
	
func _mouse_entered():
	SoundManager.play_sfx("res://sfx/editor/hover.wav", 0.0, 10)
	cursor.visible = true
	cursor_anim.stop()
	cursor_anim.play(&"hover")
	cursor.global_position = global_position + pivot_offset
	if not button_pressed:
		set_icon_offset(1)

func _mouse_exited():
	cursor.visible = false
	cursor_anim.stop()
	if not button_pressed:
		set_icon_offset(0)

func _button_down():
	if not toggle_mode:
		set_icon_offset(2)

func _button_up():
	if not toggle_mode:
		set_icon_offset(1)

func _toggled(toggled_on: bool) -> void:
	if toggled_on:
		set_icon_offset(2)
	else:
		set_icon_offset(0)
