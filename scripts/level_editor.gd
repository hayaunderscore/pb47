extends Node2D
class_name LevelEditor

const LEVEL_EDITOR_VERSION = 3

@onready var edit_cam: PhantomCamera2D = $EditCam/PhantomCamera2D
@onready var edit_target: Node2D = $EditCam/EditTarget
@onready var cursor: Sprite2D = $EditCam/Cursor
@onready var cursor_icon: Sprite2D = $EditCam/Cursor/Item
@onready var cursor_area: Area2D = $EditCam/Cursor/Area2D
@onready var tilemaps: Array[TileMapLayer] = [
	$Foreground, $Forererground, $Forerererground, $Backerground, $Background
]
@onready var tilemap: TileMapLayer = $Foreground
@onready var entities_node: Node2D = $EntitiesPlaced
@onready var entity_view: Node2D = $EntityViewer
@onready var controls: CanvasLayer = $Controls
@onready var properties: Control = $CanvasLayer/Panel
@onready var properties_musicinput: LineEdit = $CanvasLayer/Panel/MusicInput
@onready var properties_musicstatus: Label = $CanvasLayer/Panel/MusicStatus
@onready var properties_bginput: LineEdit = $CanvasLayer/Panel/BgInput
@onready var properties_tiles: LineEdit = $CanvasLayer/Panel/TileSetInput
@onready var coordinates: Label = $CanvasLayer/Coordinates

var ent_v: PackedScene = preload("res://res/obj/misc/entity_view.tscn")

var edit_active: bool = false
const MOVE_SPEED = 10

const EDIT_LOOP_END = 37.859
const EDIT_LOOP_START = 1.535

const AKRILLIC_LOOP_END = 227.776
const AKRILLIC_LOOP_START = 2.227

const EDIT_MUSIC = "res://mus/edit.ogg"
const PLAY_MUSIC = "res://mus/akrillic.ogg"

# Music should generally follow here.
var edit_time: float = 0.0
var play_time: float = 0.0

var has_saved: bool = false

# Tile type enums
enum CursorType {
	TILE,		# Base tiles
	SLOPE221,	# Long slope tile 1
	SLOPE222,	# Long slope tile 2
	SLOPE45,	# Short slope tile
	PASSTHROUGH,# Pass through tiles
	START,		# Bliggy start position
	RIE,		# Rie (checkpoint)
	TIMER,		# Start flag (Timer)
	BLOOP,		# Bloop
	NECO,		# Neco
	MINIDOMU,	# Mini Domu
	SPIKE,		# Spike
	LEVELBOUND,	# Level bound
	KILLPLANE,	# Kill plane
	CURSOR_MAX,
}

# Scene entries for entity tiles
var entities: Array[PackedScene] = [
	null, null, null, null, null, # These are all tiles, no need for anything here
	null, # A player start is not generally an entity....
	preload("res://res/obj/misc/rie.tscn"),
	preload("res://res/obj/misc/speedrunstart.tscn"),
	preload("res://res/obj/Enemy/bloop.tscn"),
	preload("res://res/obj/Enemy/neco.tscn"),
	preload("res://res/obj/Enemy/minidomu.tscn"),
	preload("res://res/obj/Enemy/spikes.tscn"),
	preload("res://res/obj/misc/levelbound.tscn"),
	preload("res://res/obj/misc/kill_plane.tscn"),
]

var v1tov2: Dictionary = {
	0: CursorType.TILE,
	1: CursorType.SLOPE221,
	2: CursorType.SLOPE222,
	3: CursorType.SLOPE45,
	4: CursorType.BLOOP,
	5: CursorType.NECO,
	6: CursorType.MINIDOMU,
	7: CursorType.SPIKE,
	8: CursorType.RIE,
	9: CursorType.TIMER,
	10: CursorType.START
}

var entity_set: Array[Dictionary] = [
	{}, {}, {}, {}, {}
]

var current_cursor: CursorType = CursorType.TILE
var should_flip: bool = false

var save_load_opened: bool = false

const TILE_SIZE = 32
const ENTITY_OFFSET = Vector2i(16, 32)

var play_mus: String = PLAY_MUSIC
var play_loop_start: float = AKRILLIC_LOOP_START
var play_loop_end: float = AKRILLIC_LOOP_END

var last_path: String

var current_layer: int = EditedLevel.TileLayer.FOREGROUND

var bg_path: String = "res://gfx/bg/bg01.png"

func _enter_tree() -> void:
	SoundManager.play_bgm(PLAY_MUSIC)

func _ready() -> void:
	edit_target.global_position = $PhantomCamera2D.global_position

func save_file(path: String):
	save_load_opened = false
	$CanvasLayer/Panel/SaveButton.release_focus()
	$CanvasLayer/Panel/LoadButton.release_focus()
	if path.get_extension() == "":
		path = path + ".res"
	var lvl: EditedLevel = EditedLevel.new()
	lvl.tiles = entity_set.duplicate(true)
	lvl.version = LEVEL_EDITOR_VERSION
	last_path = path.get_base_dir() + "/"
	if not properties_musicinput.text.is_empty():
		if FileAccess.file_exists("res://" + properties_musicinput.text):
			lvl.music = "res://" + properties_musicinput.text
		else:
			# Get our stupid path
			var normal_path = path.get_base_dir() + "/"
			lvl.music = normal_path + properties_musicinput.text
		lvl.relative_music = properties_musicinput.text
	if not properties_bginput.text.is_empty():
		lvl.background = properties_bginput.text
	lvl.bg_scale = parallax.scroll_scale
	lvl.bg_scroll = parallax.autoscroll
	if not properties_tiles.text.is_empty():
		lvl.fuckedtiles = properties_tiles.text
	ResourceSaver.save(lvl, path, ResourceSaver.FLAG_COMPRESS)
	has_saved = true
	save_load_opened = false
	
func set_level_music(mus_path: String):
	if mus_path.begins_with("res://"):
		# Handle built in tracks here...
		var mus: AudioStream = load(mus_path)
		if mus == null: return null
		SoundManager.preload_resource(mus)
		play_loop_end = mus.get_length()
		if mus is AudioStreamOggVorbis:
			play_loop_start = mus.loop_offset
		elif mus is AudioStreamWAV:
			play_loop_start = mus.loop_begin
			if mus.loop_end > 0: play_loop_end = mus.loop_end
		play_time = 0.0
		play_mus = mus_path
		return mus
	# Outside track, only supports OGG
	if mus_path.get_extension() != "ogg": return null
	var mus: AudioStreamOggVorbis = Globals.load_ogg_runtime(mus_path)
	if mus == null: return null
	mus.take_over_path(mus_path) # The returned resource doesn't actually apply the path
	SoundManager.preload_resource(mus)
	play_loop_end = mus.get_length()
	play_loop_start = mus.loop_offset
	play_time = 0.0
	play_mus = mus_path
	return mus

func add_cell(layer: int, coords: Vector2, page: int = 1, atlas_coords: Vector2 = Vector2(0, 0), flip: bool = false):
	tilemaps[layer].set_cell(coords, page, atlas_coords)
	if flip:
		var alt_id = tilemaps[layer].get_cell_alternative_tile(coords)
		tilemaps[layer].set_cell(coords, page, atlas_coords, alt_id | TileSetAtlasSource.TRANSFORM_FLIP_H)

func add_entity_dummy(id: int, coords: Vector2, layer: int):
	var ent: Area2D = ent_v.instantiate()
	var spr: Sprite2D = ent.get_node("Sprite2D")
	spr.frame = id
	ent.global_position = coords * TILE_SIZE
	ent.set_collision_layer_value(8 + layer, true)
	entity_view.add_child(ent)

func clear_and_change(line: LineEdit, text: String):
	line.clear()
	line.insert_text_at_caret(text)

func load_file(path: String):
	save_load_opened = false
	$CanvasLayer/Panel/SaveButton.release_focus()
	$CanvasLayer/Panel/LoadButton.release_focus()
	var lvl: EditedLevel = ResourceLoader.load(path)
	if lvl == null: return
	if lvl.version <= 2:
		print("Version 2 map detected, cannot load....")
		return
	entity_set = lvl.tiles.duplicate(true)
	for tm in tilemaps:
		tm.clear()
	for child in entity_view.get_children():
		child.queue_free()
	has_saved = true
	last_path = path.get_base_dir() + "/"
	
	if lvl.music != play_mus:
		set_level_music(last_path + lvl.relative_music)
		clear_and_change(properties_musicinput, lvl.relative_music)
	
	properties_bginput.text = lvl.background
	properties_tiles.text = lvl.fuckedtiles
	$CanvasLayer/Panel/AutoScroll/xcoord.value = lvl.bg_scroll.x
	$CanvasLayer/Panel/AutoScroll/ycoord.value = lvl.bg_scroll.y
	$CanvasLayer/Panel/ScrollScale/xscroll.value = lvl.bg_scale.x
	$CanvasLayer/Panel/ScrollScale/yscroll.value = lvl.bg_scale.y
	bg_change()
	change_tiles()
	
	# Convert....
	if lvl.version < LEVEL_EDITOR_VERSION:
		match lvl.version:
			1:
				for layer in entity_set:
					for key in layer:
						layer[key]["id"] = v1tov2[layer[key]["id"]]
	
	# Iterate through the entity set
	for i in range(0, entity_set.size()):
		var layer: Dictionary = entity_set[i]
		for key in layer:
			# Entity, show entity view
			var tile: Dictionary = layer[key] as Dictionary
			print("id: %d", tile["id"])
			print("flip: %d", tile["flip"])
			if tile != null and tile["id"] != -1 and entities[tile["id"]] != null:
				add_entity_dummy(tile["id"], key, i)
			elif tile != null:
				match tile["id"]:
					CursorType.TILE:
						BetterTerrain.set_cell(tilemaps[i], key, 1)
						BetterTerrain.update_terrain_cell(tilemaps[i], key, true)
					CursorType.SLOPE221:
						add_cell(i, key, 1, Vector2i(0, 4), tile["flip"])
					CursorType.SLOPE222:
						add_cell(i, key, 1, Vector2i(1, 4), tile["flip"])
					CursorType.SLOPE45:
						add_cell(i, key, 1, Vector2i(2, 4), tile["flip"])
					CursorType.PASSTHROUGH:
						BetterTerrain.set_cell(tilemaps[current_layer], key, 3)
						BetterTerrain.update_terrain_cell(tilemaps[current_layer], key, true)
					CursorType.START:
						add_entity_dummy(tile["id"], key, i)
						Map.player.global_position = key * TILE_SIZE + ENTITY_OFFSET

func cancell():
	save_load_opened = false
	$CanvasLayer/Panel/SaveButton.release_focus()
	$CanvasLayer/Panel/LoadButton.release_focus()

func save_level():
	save_load_opened = true
	var dialog := NativeFileDialog.new()
	dialog.add_filter("*.res", "PB47 Levels (*.res)")
	dialog.connect("file_selected", save_file)
	dialog.connect("canceled", cancell)
	dialog.file_mode = NativeFileDialog.FILE_MODE_SAVE_FILE
	dialog.access = NativeFileDialog.ACCESS_USERDATA
	add_child(dialog)
	dialog.show()

func load_level():
	save_load_opened = true
	var dialog := NativeFileDialog.new()
	dialog.add_filter("*.res", "PB47 Levels (*.res)")
	dialog.connect("file_selected", load_file)
	dialog.connect("canceled", cancell)
	dialog.file_mode = NativeFileDialog.FILE_MODE_OPEN_FILE
	dialog.access = NativeFileDialog.ACCESS_USERDATA
	add_child(dialog)
	dialog.show()

var confirmtween: Tween
var confirm_held: bool = false
func confirm_clear():
	if not is_instance_valid(confirmtween):
		confirmtween = get_tree().create_tween()
	confirmtween.stop()
	confirm_held = true
	
func handle_clear_confirm():
	$CanvasLayer/Panel/ClearAll/Panel2.size.x += 0.5
	$CanvasLayer/Panel/ClearAll.text = "HOLD!"
	if $CanvasLayer/Panel/ClearAll/Panel2.size.x > 42.0:
		clear_all()
		$CanvasLayer/Panel/ClearAll/Panel2.size.x = 0
		$CanvasLayer/Panel/ClearAll.release_focus()

func confirm_nope():
	$CanvasLayer/Panel/ClearAll.text = "Clear All"
	$CanvasLayer/Panel/ClearAll/Panel2.size.x = 0
	confirm_held = false

func clear_all():
	var center = Node2D.new()
	var view_to_world = cursor.get_canvas_transform().affine_inverse()
	center.global_position = view_to_world * Vector2(640/2, 360/2)
	add_child(center)
	Globals.spawn_explosion(center, 16)
	SoundManager.play_sfx("res://sfx/blows.wav", 0.0, -3)
	center.queue_free()
	for layer in entity_set:
		layer.clear()
	for tm in tilemaps:
		tm.clear()
	for child in entity_view.get_children():
		child.queue_free()

@onready var parallax: Parallax2D = $Parallax2D
@onready var parallax_sprite: Sprite2D = $Parallax2D/Sprite2D

func bg_change():
	SoundManager.play_sfx("res://sfx/new/ui/rctclick.wav")
	var path: String = properties_bginput.text
	if path.is_empty(): path = properties_bginput.placeholder_text
	if FileAccess.file_exists("res://" + path):
		parallax_sprite.texture = load("res://" + path)
		parallax.repeat_size.x = parallax_sprite.texture.get_width()
		parallax.repeat_size.y = parallax_sprite.texture.get_height()
		bg_path = path
		return
	if last_path.is_empty(): return
	if not FileAccess.file_exists(last_path + path): return
	var full_path: String = last_path + path
	var spr: Image = Image.load_from_file(full_path)
	if spr == null: return
	parallax_sprite.texture = ImageTexture.create_from_image(spr)
	parallax.repeat_size.x = spr.get_width()
	parallax.repeat_size.y = spr.get_height()
	bg_path = path
	
func edit_mode():
	if confirm_held:
		handle_clear_confirm()
	if Input.is_action_just_pressed("editor_save"):
		save_level()
	elif Input.is_action_just_pressed("editor_load"):
		load_level()
	if Input.is_action_just_pressed("editor_togglepanel") and not properties_musicinput.has_focus() and not properties_bginput.has_focus() and not properties_tiles.has_focus():
		properties.visible = !properties.visible
		SoundManager.play_sfx("res://sfx/new/ui/rctwindow.wav")
	if save_load_opened or properties.visible: return
	edit_target.translate(Input.get_vector("editor_left", "editor_right", "editor_up", "editor_down") * MOVE_SPEED)
	cursor.visible = true
	if Input.is_action_just_pressed("editor_flip"):
		should_flip = !should_flip
		cursor_icon.flip_h = should_flip
	cursor_icon.frame = current_cursor
	if Input.is_action_just_pressed("cursor_up"):
		current_cursor -= 1
	if Input.is_action_just_pressed("cursor_down"):
		current_cursor += 1
	if current_cursor >= CursorType.CURSOR_MAX:
		current_cursor = 0
	elif current_cursor < 0:
		current_cursor = CursorType.CURSOR_MAX - 1
	# Move cursor to mouse coordinates
	var view_to_world = cursor.get_canvas_transform().affine_inverse()
	cursor.global_position = view_to_world * (get_viewport().get_mouse_position()) + Vector2(-16, -16)
	var unsnapped_pos = cursor.global_position
	cursor.global_position = cursor.global_position.snapped(Vector2(32, 32))
	coordinates.text = "(%d, %d) [%d, %d]" % [round(cursor.global_position.x / TILE_SIZE), round(cursor.global_position.y / TILE_SIZE), round(unsnapped_pos.x + 16), round(unsnapped_pos.y + 16)]
	var coords = tilemap.local_to_map(cursor.global_position)
	# Set cursor collision layer
	# Worst way to do this probably
	cursor_area.set_collision_layer_value(8, current_layer == 0)
	cursor_area.set_collision_layer_value(9, current_layer == 1)
	cursor_area.set_collision_layer_value(10, current_layer == 2)
	cursor_area.set_collision_layer_value(11, current_layer == -2)
	cursor_area.set_collision_layer_value(12, current_layer == -1)
	# Add or remove tiles
	if Input.is_action_pressed("editor_add"):
		match current_cursor:
			CursorType.TILE:
				BetterTerrain.set_cell(tilemaps[current_layer], coords, 1)
				BetterTerrain.update_terrain_cell(tilemaps[current_layer], coords, true)
			CursorType.SLOPE221:
				add_cell(current_layer, coords, 1, Vector2i(0, 4), should_flip)
			CursorType.SLOPE222:
				add_cell(current_layer, coords, 1, Vector2i(1, 4), should_flip)
			CursorType.SLOPE45:
				add_cell(current_layer, coords, 1, Vector2i(2, 4), should_flip)
			CursorType.PASSTHROUGH:
				BetterTerrain.set_cell(tilemaps[current_layer], coords, 3)
				BetterTerrain.update_terrain_cell(tilemaps[current_layer], coords, true)
			_:
				# Catch all for entity types
				if cursor_area.has_overlapping_areas():
					return
				add_entity_dummy(cursor_icon.frame, coords, current_layer)
		# Despite being named "entity_set" this actually accounts for all possible tiles.
		entity_set[current_layer][coords] = {
			"id": current_cursor,
			"flip": should_flip,
		}
	elif Input.is_action_pressed("editor_remove"):
		# No match here, just remove anything occupying the cell
		BetterTerrain.set_cell(tilemaps[current_layer], coords, -1)
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			BetterTerrain.update_terrain_cell(tilemaps[current_layer], coords, true)
		# Kill yourself
		tilemaps[current_layer].set_cell(coords)
		entity_set[current_layer].erase(coords)
		# now
		if cursor_area.has_overlapping_areas():
			for area in cursor_area.get_overlapping_areas():
				area.queue_free()
	if Input.is_action_pressed("editor_resetpos"):
		for layer in entity_set:
			for key in layer:
				if layer[key] != null and layer[key]["id"] == CursorType.START:
					Map.player.global_position = key * TILE_SIZE + ENTITY_OFFSET

func play_mode():
	cursor.visible = false
	entity_view.visible = false
	properties.visible = false
	properties.release_focus()

var lvlbounds: int = 0
	
func change_mode():
	if not edit_active:
		lvlbounds = 0
		for layer in entity_set:
			for key in layer:
				if layer[key] != null and entities[layer[key]["id"]] != null:
					var ent: Node2D = entities[layer[key]["id"]].instantiate()
					ent.global_position = key * TILE_SIZE + ENTITY_OFFSET
					if layer[key]["id"] == CursorType.LEVELBOUND:
						ent.type = lvlbounds
						lvlbounds += 1
					entities_node.add_child(ent)
		entity_view.visible = true
	else:
		# KILL ALL CHILDREN.... OF THE node i mean.
		for child in entities_node.get_children():
			child.queue_free()
		entity_view.visible = true
		Map.player.phantomCamera.set_limit_target(tilemap.get_path())
		# Just in case....
		for cell in tilemap.get_used_cells():
			if not entity_set[0].has(cell):
				entity_set[0][cell] = {"id": 0, "flip": false}

var edit_spr: Texture2D = preload("res://gfx/hud/edit.png")
var play_spr: Texture2D = preload("res://gfx/hud/play.png")

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_edit") and not properties_musicinput.has_focus() and not properties_bginput.has_focus() and not properties_tiles.has_focus():
		edit_active = !edit_active
		Map.player.set_physics_process(!edit_active)
		get_tree().create_tween().tween_property(controls, "transform:origin:y", 256 if not edit_active else 0, 0.75).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
		get_tree().create_tween().tween_property(Map.hud_instance, "transform:origin:y", -128 if edit_active else 0, 0.75).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
		edit_cam.priority = 11 if edit_active else 0
		if edit_active:
			get_tree().create_tween().tween_property($CanvasLayer2/Sprite2D, "offset:y", -32, 0.75).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
			$CanvasLayer2/Sprite2D.texture = play_spr
		else:
			get_tree().create_tween().tween_property($CanvasLayer2/Sprite2D, "offset:y", 0, 0.75).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
			$CanvasLayer2/Sprite2D.texture = edit_spr
		SoundManager.stop(play_mus if edit_active else EDIT_MUSIC)
		SoundManager.play_bgm(EDIT_MUSIC if edit_active else play_mus, edit_time if edit_active else play_time)
		change_mode()
	edit_time += delta if edit_active else 0
	play_time += delta if not edit_active else 0
	if edit_time >= EDIT_LOOP_END:
		edit_time = EDIT_LOOP_START
	if play_time >= play_loop_end:
		play_time = play_loop_start
		
	if edit_active:
		edit_mode()
	else:
		play_mode()


func music_apply() -> void:
	SoundManager.play_sfx("res://sfx/new/ui/rctclick.wav")
	if not has_saved:
		properties_musicstatus.text = "STATUS: PLEASE SAVE FIRST!"
		return
	if last_path.is_empty():
		properties_musicstatus.text = "STATUS: PATH IS SOMEHOW EMPTY!"
		return
	if properties_musicstatus.text.is_empty():
		properties_musicstatus.text = "STATUS: USING DEFAULT"
		play_mus = PLAY_MUSIC
		play_loop_end = AKRILLIC_LOOP_END
		play_loop_start = AKRILLIC_LOOP_START
		play_time = 0.0
		return
	var text: String = properties_musicinput.text
	if text.is_empty():
		text = properties_musicinput.placeholder_text
	play_mus = "res://" + text
	if set_level_music(play_mus) != null:
		properties_musicstatus.text = "STATUS: OK!"
		return
	play_mus = last_path + text
	if set_level_music(play_mus) != null:
		properties_musicstatus.text = "STATUS: OK!"
		return
	properties_musicstatus.text = "STATUS: FAILED!"

func _on_xcoord_value_changed(value: float) -> void:
	parallax.autoscroll.x = value

func _on_ycoord_value_changed(value: float) -> void:
	parallax.autoscroll.y = value

func _on_xscroll_value_changed(value: float) -> void:
	parallax.scroll_scale.x = value

func _on_yscroll_value_changed(value: float) -> void:
	parallax.scroll_scale.y = value

var tile_path: String

func change_tiles():
	SoundManager.play_sfx("res://sfx/new/ui/rctclick.wav")
	var path: String = properties_tiles.text
	if path.is_empty(): path = properties_tiles.placeholder_text
	var tileset: TileSet = tilemap.tile_set
	# 3 is the source id for the most commonly used tileset
	# which is also used in the level editor!
	var src: TileSetAtlasSource = tileset.get_source(3)
	if FileAccess.file_exists("res://" + path):
		src.texture = load("res://" + path)
		tile_path = path
		return
	if last_path.is_empty(): return
	if not FileAccess.file_exists(last_path + path): return
	var full_path: String = last_path + path
	var spr: Image = Image.load_from_file(full_path)
	if spr == null: return
	src.texture = ImageTexture.create_from_image(spr)
	tile_path = path
