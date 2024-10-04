extends Node2D

var main_title_ready: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Butans/Play.pressed.connect(play)
	$Butans/Editor.pressed.connect(editor)
	$Butans/Settings.pressed.connect(settings)
	$Butans/Exit.pressed.connect(exit)

func play():
	var center = Node2D.new()
	center.global_position = $Butans/Play.global_position + $Butans/Play.size / 2
	add_child(center)
	Globals.spawn_explosion(center, 6)
	SoundManager.play_sfx("res://sfx/blows.wav")
	center.queue_free()
	$Butans/Play.hide()

func editor():
	SoundManager.play_sfx("res://sfx/pb5_select.wav")
	await get_tree().create_timer(Map.create_fade(2, true)).timeout
	get_tree().change_scene_to_file("res://main.tscn")

func settings():
	pass

func exit():
	var center = Node2D.new()
	var view_to_world = get_canvas_transform().affine_inverse()
	center.global_position = view_to_world * Vector2(640/2, 360/2)
	add_child(center)
	Globals.spawn_explosion(center, 16, 0.25)
	SoundManager.play_sfx("res://sfx/blows.wav")
	center.queue_free()
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()

var time: float
var alr_pressed: bool = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not alr_pressed and not main_title_ready:
		alr_pressed = true
		if $AnimationPlayer.current_animation_position >= 3.5:
			main_title_ready = true
			SoundManager.play_sfx("res://sfx/pb5_select.wav")
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property($WaveringTitle, "position", Vector2(256, 112), 0.5).set_trans(Tween.TRANS_QUAD)
			tween.tween_property($Butans, "position:x", 400, 0.75).set_trans(Tween.TRANS_QUAD)
		else:
			SoundManager.play_sfx("res://sfx/elecnoise.wav")
			$AnimationPlayer.seek(3.5, true)
	if event is InputEventKey and event.is_released():
		alr_pressed = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta
	if not main_title_ready:
		$WaveringTitle.position.y = 112 + (sin(time) * 24)
