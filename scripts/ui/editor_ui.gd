extends CanvasLayer
class_name EditorUI

@onready var eraser: Button = $TilePanel/MarginContainer2/Right/Eraser
@onready var eraser_Sound: AudioStreamPlayer = $TilePanel/MarginContainer2/Right/Eraser/Sound
@onready var eraser_outline: Panel = $EraserOutline
@onready var eraser_outline2: PanelContainer = $EraserOutline/EraserOutline2
@onready var scrollcont: SmoothScrollContainer = $TilePanel/MarginContainer/SmoothScrollContainer

@onready var tilePanel: PanelContainer = $TilePanel
@onready var tilesContainer: HBoxContainer = $TilePanel/MarginContainer/SmoothScrollContainer/HBoxContainer

@onready var undoButan: Button = $TilePanel/MarginContainer2/Right/Undo
@onready var undoTimer: Timer = $TilePanel/MarginContainer2/Right/Undo/Timer

@onready var nukeButton: Button = $NukeButton
@onready var topElements: Array[Control] = [
	tilePanel,
	eraser_outline,
	$HideTopBarButton,
	$PrevLayer,
	$NextLayer,
	$InvisiPanel,
	$LayerNumber,
	$PropertiesContainer
]

@onready var moveForPropertyAndSL: Array[Control] = [
	$PrevLayer,
	$NextLayer,
	$LayerNumber
]
var abovePrevPos: PackedVector2Array

var button_ids: Array
var buttons: Array[TileButton]

var button_gfx := preload("res://gfx/hud/editorIcons.png")
var current_tile_id: int = -1
var should_ignore_panel: bool = false
@onready var ignore_rect: Rect2 = $InvisiPanel.get_global_rect()

signal changed_tile_id(id)
signal changed_layer(inc)
signal undo_pressed
signal music_apply(path)
signal bg_apply(path)
signal tileset_apply(path)
signal autoscroll_changed(vec)
signal scrollscale_changed(vec)
signal save(path)
signal load_file(path)
signal sl_cancelled
signal nuke

var visual_layer: int = 0

func generate_atlas_from_id(id: int):
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = button_gfx
	atlas.region.position.y = 32 * floor(id / 13)
	atlas.region.position.x = 32 * (id % 13)
	atlas.region.size = Vector2(32, 32)
	return atlas

func _ready() -> void:
	buttons.clear()
	button_ids.clear()
	var butangroup: ButtonGroup = ButtonGroup.new()
	butangroup.allow_unpress = true
	for i in range(0, LevelEditor.CursorType.CURSOR_MAX):
		var butan: TileButton = TileButton.new()
		butan.custom_minimum_size = Vector2(40, 40)
		butan.icon = generate_atlas_from_id(i)
		butan.button_group = butangroup
		butan.toggle_mode = true
		butan.id = i
		butan.focus_mode = Control.FOCUS_NONE
		butan.tile_pressed.connect(tile_button_pressed)
		butan.mouse_entered.connect(mouse_entered_tile)
		buttons.append(butan)
		button_ids.append(i)
		tilesContainer.add_child(butan)
	$PropertiesContainer.scale.y = 0
	$SaveContainer.scale.y = 0
	$PropertiesContainer/VBoxContainer/MarginContainer.modulate.a = 0
	$SaveContainer/VBoxContainer/MarginContainer.modulate.a = 0
	for control in moveForPropertyAndSL:
		abovePrevPos.append(control.global_position)
	$HideTopBarButton.toggled.connect(hide_prop_panel)

func hide_prop_panel(_toggled_on: bool):
	if $TilePanel/MarginContainer2/Left/Properties.button_pressed:
		$TilePanel/MarginContainer2/Left/Properties.button_pressed = false

func hide_save_panel(_toggled_on: bool):
	if $TilePanel/MarginContainer2/Left/Properties.button_pressed:
		$TilePanel/MarginContainer2/Left/SaveLoad.button_pressed = false

func mouse_entered_tile():
	SoundManager.play_sfx("res://sfx/editor/hover_tiles.wav", 0.0, 6)

func tile_button_pressed(butan: TileButton, id: int, toggled: bool):
	if toggled: SoundManager.play_sfx("res://sfx/editor/select.wav", 0.0, 4)
	elif not toggled and butan.had_mouse: SoundManager.play_sfx("res://sfx/editor/back.wav", 0.0, 4)
	print("Tile %d toggle status: " % id, toggled)
	if toggled: current_tile_id = id
	else: current_tile_id = -1
	changed_tile_id.emit(current_tile_id)

func _input(event: InputEvent) -> void:
	if hidden:
		eraser.button_pressed = false
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			eraser.button_pressed = true
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_released():
			eraser.button_pressed = false
	ignore_rect = $InvisiPanel.get_global_rect()
	var ignore_rect2 = $PropertiesContainer.get_global_rect()
	var ignore_rect3 = $NukeButton.get_global_rect()
	var ignore_rect4 = $SaveContainer.get_global_rect()
	if event is InputEventMouse:
		if ignore_rect.has_point(event.position) or ignore_rect2.has_point(event.position) or ignore_rect3.has_point(event.position) or ignore_rect4.has_point(event.position):
			should_ignore_panel = true
		else:
			should_ignore_panel = false

func _process(delta: float) -> void:
	eraser_outline2.position.y = max(8, tilePanel.position.y + 58)
	if undoButan.button_pressed:
		if undoTimer.is_stopped():
			undo_pressed.emit()
			undoTimer.start()
	if $NukeButton.button_pressed:
		$NukeButton.text = "%d" % [(nuke_timer.time_left * 2) + 1]

func _on_eraser_toggled(toggled_on: bool) -> void:
	if toggled_on: 
		eraser_Sound.play()
		eraser_outline.visible = true
	else: 
		eraser_Sound.stop()
		eraser_outline.visible = false

var lastpositions: Array[Vector2]
var hidden: bool = false

var editor_cursor := preload("res://gfx/hud/cursors/cursor.png")
var panel_tween: Tween
		
func toggle_panels(instant: bool):
	hidden = !hidden
	var speed: float = 0.4 if not instant else 0
	if panel_tween:
		panel_tween.custom_step(999)
	panel_tween = get_tree().create_tween()
	match hidden:
		true:
			Input.set_custom_mouse_cursor(null)
			lastpositions.clear()
			for control in topElements:
				lastpositions.append(control.global_position)
				var pos: Vector2 = control.global_position + Vector2(0, -128)
				panel_tween.parallel().tween_property(control, "global_position", pos, speed).set_trans(Tween.TRANS_QUAD)
			lastpositions.append(nukeButton.global_position)
			var pos: Vector2 = nukeButton.global_position + Vector2(80, 0)
			panel_tween.parallel().tween_property(nukeButton, "global_position", pos, speed).set_trans(Tween.TRANS_QUAD)
			$TilePanel/MarginContainer2/Left/Properties.disabled = false
			$TilePanel/MarginContainer2/Left/SaveLoad.disabled = false
			if prop_tween and prop_tween.is_running(): 
				prop_tween.custom_step(999) 
				prop_tween.stop()
			if save_tween and save_tween.is_running(): 
				save_tween.custom_step(999) 
				save_tween.stop()
			if $TilePanel/MarginContainer2/Left/Properties.button_pressed:
				$TilePanel/MarginContainer2/Left/Properties.button_pressed = false
			if $TilePanel/MarginContainer2/Left/SaveLoad.button_pressed:
				$TilePanel/MarginContainer2/Left/SaveLoad.button_pressed = false
		false:
			Input.set_custom_mouse_cursor(editor_cursor)
			var i: int = 0
			while (i < topElements.size()):
				panel_tween.parallel().tween_property(topElements[i], "global_position", lastpositions[i], speed).set_trans(Tween.TRANS_QUAD)
				i += 1
			panel_tween.parallel().tween_property(nukeButton, "global_position", lastpositions[i], speed).set_trans(Tween.TRANS_QUAD)
			$TilePanel/MarginContainer2/Left/Properties.disabled = false

func _on_prev_layer_pressed() -> void:
	changed_layer.emit(-1)
	visual_layer -= 1
	if visual_layer < -2:
		visual_layer = -2
	$LayerNumber.text = str(visual_layer)

func _on_next_layer_pressed() -> void:
	changed_layer.emit(1)
	visual_layer += 1
	if visual_layer > 2:
		visual_layer = 2
	$LayerNumber.text = str(visual_layer)

var prop_tween: Tween
var save_tween: Tween

func _on_properties_toggled(toggled_on: bool) -> void:
	prop_tween = get_tree().create_tween()
	$TilePanel/MarginContainer2/Left/Properties.disabled = true
	$TilePanel/MarginContainer2/Left/SaveLoad.disabled = false
	$TilePanel/MarginContainer2/Left/SaveLoad.button_pressed = false
	
	if toggled_on:
		prop_tween.set_parallel(true)
		SoundManager.play_sfx("res://sfx/editor/propsave.wav", 0.0, 6)
		for i in range(0, moveForPropertyAndSL.size()):
			var control: Control = moveForPropertyAndSL[i]
			prop_tween.tween_property(control, "global_position:x", abovePrevPos[i].x + 128, 0.3).set_trans(Tween.TRANS_QUAD)
	else:
		prop_tween.set_parallel(true)
		SoundManager.play_sfx("res://sfx/editor/back.wav", 0.0, 6)
		for i in range(0, moveForPropertyAndSL.size()):
			var control: Control = moveForPropertyAndSL[i]
			prop_tween.tween_property(control, "global_position:x", abovePrevPos[i].x, 0.3).set_trans(Tween.TRANS_QUAD)
	
	if not toggled_on:
		prop_tween.parallel().tween_property($PropertiesContainer/VBoxContainer/MarginContainer, "modulate:a", 0.0, 0.1).set_trans(Tween.TRANS_QUAD)
		prop_tween.set_parallel(true)
	prop_tween.tween_property($PropertiesContainer, "scale:y", 1.0 if toggled_on else 0.0, 0.3).set_trans(Tween.TRANS_QUAD)
	prop_tween.set_parallel(false)
	if toggled_on:
		prop_tween.tween_property($PropertiesContainer/VBoxContainer/MarginContainer, "modulate:a", 1.0, 0.1).set_trans(Tween.TRANS_QUAD)
	await prop_tween.finished
	$TilePanel/MarginContainer2/Left/Properties.disabled = false

func _on_save_load_toggled(toggled_on: bool) -> void:
	save_tween = get_tree().create_tween()
	$TilePanel/MarginContainer2/Left/SaveLoad.disabled = true
	$TilePanel/MarginContainer2/Left/Properties.disabled = false
	$TilePanel/MarginContainer2/Left/Properties.button_pressed = false
	
	if toggled_on:
		save_tween.set_parallel(true)
		SoundManager.play_sfx("res://sfx/editor/propsave.wav", 0.0, 6)
		for i in range(0, moveForPropertyAndSL.size()):
			var control: Control = moveForPropertyAndSL[i]
			save_tween.tween_property(control, "global_position:x", abovePrevPos[i].x + 128, 0.3).set_trans(Tween.TRANS_QUAD)
	else:
		save_tween.set_parallel(true)
		SoundManager.play_sfx("res://sfx/editor/back.wav", 0.0, 6)
		for i in range(0, moveForPropertyAndSL.size()):
			var control: Control = moveForPropertyAndSL[i]
			save_tween.tween_property(control, "global_position:x", abovePrevPos[i].x, 0.3).set_trans(Tween.TRANS_QUAD)
	
	if not toggled_on:
		save_tween.parallel().tween_property($SaveContainer/VBoxContainer/MarginContainer, "modulate:a", 0.0, 0.1).set_trans(Tween.TRANS_QUAD)
		save_tween.set_parallel(true)
	save_tween.tween_property($SaveContainer, "scale:y", 1.0 if toggled_on else 0.0, 0.3).set_trans(Tween.TRANS_QUAD)
	save_tween.set_parallel(false)
	if toggled_on:
		save_tween.tween_property($SaveContainer/VBoxContainer/MarginContainer, "modulate:a", 1.0, 0.1).set_trans(Tween.TRANS_QUAD)
	await save_tween.finished
	$TilePanel/MarginContainer2/Left/SaveLoad.disabled = false

@onready var mus: LineEdit = $PropertiesContainer/VBoxContainer/MarginContainer/VBoxContainer/MusicInput
@onready var mus_status: Label = $PropertiesContainer/VBoxContainer/MarginContainer/VBoxContainer/MusicStatus
@onready var bgi: LineEdit = $PropertiesContainer/VBoxContainer/MarginContainer/VBoxContainer/BGInput
@onready var tle: LineEdit = $PropertiesContainer/VBoxContainer/MarginContainer/VBoxContainer/TileInput

@onready var autoscroll: Vector2:
	get:
		return Vector2(
			$PropertiesContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/SpinBox.value,
			$PropertiesContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/SpinBox2.value
		)
	set(val):
		$PropertiesContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/SpinBox.value = val.x
		$PropertiesContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/SpinBox2.value = val.y

@onready var parallax: Vector2:
	get:
		return Vector2(
			$PropertiesContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/SpinBox.value,
			$PropertiesContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/SpinBox2.value
		)
	set(val):
		$PropertiesContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/SpinBox.value = val.x
		$PropertiesContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/SpinBox2.value = val.y


func get_text_or_placeholder(label: LineEdit):
	return label.text if not label.text.is_empty() else label.placeholder_text

func _on_musshortcut_pressed() -> void:
	music_apply.emit(get_text_or_placeholder(mus))

func _on_bgshortcut_pressed() -> void:
	bg_apply.emit(get_text_or_placeholder(bgi))

func _on_tileshortcut_pressed() -> void:
	tileset_apply.emit(get_text_or_placeholder(tle))

func _on_autoscrollx_value_changed(value: float) -> void:
	autoscroll_changed.emit(Vector2(value, 
		$PropertiesContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/SpinBox2.value
	))

func _on_autoscrolly_value_changed(value: float) -> void:
	autoscroll_changed.emit(Vector2(
		$PropertiesContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/SpinBox.value, 
		value
	))

func _on_scrollscalex_value_changed(value: float) -> void:
	scrollscale_changed.emit(Vector2(value, 
		$PropertiesContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/SpinBox2.value
	))

func _on_scrollscaley_value_changed(value: float) -> void:
	scrollscale_changed.emit(Vector2(
		$PropertiesContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/SpinBox.value, 
		value
	))

func _on_propertiesexit_pressed() -> void:
	$TilePanel/MarginContainer2/Left/Properties.disabled = false
	if $TilePanel/MarginContainer2/Left/Properties.button_pressed:
		$TilePanel/MarginContainer2/Left/Properties.button_pressed = false

func _on_saveexit_pressed() -> void:
	$TilePanel/MarginContainer2/Left/SaveLoad.disabled = false
	if $TilePanel/MarginContainer2/Left/SaveLoad.button_pressed:
		$TilePanel/MarginContainer2/Left/SaveLoad.button_pressed = false

var nuke_timer: Timer = Timer.new()

func _on_nuke_button_button_down() -> void:
	if not is_instance_valid(nuke_timer.get_parent()):
		add_child(nuke_timer)
		nuke_timer.timeout.connect(func(): 
			nuke.emit() 
			var a = InputEventMouseButton.new()
			a.set_button_index(1)
			a.set_pressed(false)
			Input.parse_input_event(a)
		)
	nuke_timer.wait_time = 1.4999
	nuke_timer.one_shot = true
	nuke_timer.start()
	SoundManager.play_sfx("res://sfx/new/ui/rctclick.wav")
	SoundManager.play_sfx("res://sfx/editor/nuketimer.ogg")

func _on_nuke_button_button_up() -> void:
	SoundManager.stop("res://sfx/editor/nuketimer.ogg")
	nuke_timer.stop()
	$NukeButton.text = ""

@onready var sav_butan: Button = $SaveContainer/VBoxContainer/MarginContainer/VBoxContainer/SaveButton

func cancell():
	$SaveContainer/VBoxContainer/MarginContainer/VBoxContainer/SaveAsButton.release_focus()
	$SaveContainer/VBoxContainer/MarginContainer/VBoxContainer/LoadButton.release_focus()
	sl_cancelled.emit()

func _on_save_button_pressed() -> void:
	save.emit("")

func _on_save_as_button_pressed() -> void:
	var dialog := NativeFileDialog.new()
	dialog.add_filter("*.res", "PB47 Levels (*.res)")
	dialog.connect("file_selected", func(path): save.emit(path))
	dialog.connect("canceled", cancell)
	dialog.file_mode = NativeFileDialog.FILE_MODE_SAVE_FILE
	dialog.access = NativeFileDialog.ACCESS_USERDATA
	add_child(dialog)
	dialog.show()

func _on_load_button_pressed() -> void:
	var dialog := NativeFileDialog.new()
	dialog.add_filter("*.res", "PB47 Levels (*.res)")
	dialog.connect("file_selected", func(path): load_file.emit(path))
	dialog.connect("canceled", cancell)
	dialog.file_mode = NativeFileDialog.FILE_MODE_OPEN_FILE
	dialog.access = NativeFileDialog.ACCESS_USERDATA
	add_child(dialog)
	dialog.show()
