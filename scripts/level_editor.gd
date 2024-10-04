extends Node2D
class_name LevelEditor

const LEVEL_EDITOR_VERSION = 4

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
@onready var entity_view: Node2D = $Foreground/EntityViewer
@onready var entity_views: Array[Node2D] = [
	$Foreground/EntityViewer, $Forererground/EntityViewer2, $Forerererground/EntityViewer3, 
	$Backerground/EntityViewer4, $Background/EntityViewer5
]
@onready var controls: CanvasLayer = $Controls
@onready var properties: Control = $CanvasLayer/Panel
@onready var coordinates: Label = $CanvasLayer/Coordinates
@onready var lvlstatus: Label = $CanvasLayer/Coordinates.get_node("Level Status")

@onready var tilepanel: Panel = $CanvasLayer/TilePanel
@onready var tilepanel_ided: LineEdit = $CanvasLayer/TilePanel/IDEdInput
@onready var tilepanel_ref: LineEdit = $CanvasLayer/TilePanel/RefInput
@onready var tilepanel_sprite: LineEdit = $CanvasLayer/TilePanel/SpriteInput

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
	WARP,		# Warp tile
	SWITCH,		# Switch
	SPRITE,		# Sprite
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
	preload("res://res/obj/dummy.tscn"),
	preload("res://res/obj/dummy.tscn"),
	preload("res://res/obj/custom_sprite.tscn"),
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

var current_cursor: int = -1
var should_flip: bool = false
var should_flipv: bool = false

var save_load_opened: bool = false

const TILE_SIZE = 32
const ENTITY_OFFSET = Vector2i(16, 32)

var play_mus: String = PLAY_MUSIC
var play_loop_start: float = AKRILLIC_LOOP_START
var play_loop_end: float = AKRILLIC_LOOP_END

var last_path: String
var last_level_path: String

var current_layer: int = EditedLevel.TileLayer.FOREGROUND

var bg_path: String = "res://gfx/bg/bg01.png"

func _enter_tree() -> void:
	SoundManager.play_bgm(PLAY_MUSIC)

func save_file(path: String):
	save_load_opened = false
	$CanvasLayer/Panel/SaveButton.release_focus()
	$CanvasLayer/Panel/LoadButton.release_focus()
	if path.is_empty():
		path = last_level_path
	if path.get_extension() == "":
		path = path + ".res"
	var lvl: EditedLevel = EditedLevel.new()
	# Set source ids and atlas coordinates.
	# Done on save since well... Causes problems when setting this on drawing.
	for i in range(0, 5):
		var layer = entity_set[i]
		for coords in layer:
			if entities[layer[coords]["id"]] == null:
				var tile: Dictionary = layer[coords]
				tile["source_id"] = tilemaps[i].get_cell_source_id(coords)
				tile["alt_id"] = tilemaps[i].get_cell_alternative_tile(coords)
				tile["atlas_coords"] = tilemaps[i].get_cell_atlas_coords(coords)
	
	lvl.tiles = entity_set.duplicate(true)
	lvl.version = LEVEL_EDITOR_VERSION
	last_path = path.get_base_dir() + "/"
	last_level_path = path
	if not editorui.mus.text.is_empty():
		if FileAccess.file_exists("res://" + editorui.mus.text):
			lvl.music = "res://" + editorui.mus.text
		else:
			# Get our stupid path
			var normal_path = path.get_base_dir() + "/"
			lvl.music = normal_path + editorui.mus.text
		lvl.relative_music = editorui.mus.text
	if not editorui.bgi.text.is_empty():
		lvl.background = editorui.bgi.text
	lvl.bg_scale = parallax.scroll_scale
	lvl.bg_scroll = parallax.autoscroll
	if not editorui.tle.text.is_empty():
		lvl.fuckedtiles = editorui.tle.text
	ResourceSaver.save(lvl, path, ResourceSaver.FLAG_COMPRESS)
	lvlstatus.call_deferred("set_text", "Level saved!")
	has_saved = true
	save_load_opened = false
	editorui.sav_butan.disabled = false
	
func set_level_music(mus_path: String):
	if mus_path.begins_with("res://"):
		# Handle built in tracks here...
		@warning_ignore("confusable_local_declaration")
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

func add_cell(layer: int, coords: Vector2, page: int = 1, atlas_coords: Vector2 = Vector2(0, 0), flip: bool = false, flip_v: bool = false, altid: int = 0):
	tilemaps[layer].set_cell(coords, page, atlas_coords, altid)
	if flip or flip_v:
		var alt_id = tilemaps[layer].get_cell_alternative_tile(coords)
		var flags = 0
		if flip: flags |= TileSetAtlasSource.TRANSFORM_FLIP_H
		if flip_v: flags |= TileSetAtlasSource.TRANSFORM_FLIP_V
		tilemaps[layer].set_cell(coords, page, atlas_coords, alt_id | flags)

func add_entity_dummy(id: int, coords: Vector2, layer: int, flip: bool = false, flip_v: bool = false):
	var ent: Area2D = ent_v.instantiate()
	var spr: Sprite2D = ent.get_node("Sprite2D")
	spr.frame = id
	spr.flip_h = flip
	spr.flip_v = flip_v
	ent.global_position = coords * TILE_SIZE
	if layer < 0:
		match layer:
			-2: layer = 3
			-1: layer = 4
	ent.set_collision_layer_value(8 + layer, true)
	entity_views[layer].add_child(ent)

func clear_and_change(line: LineEdit, text: String):
	line.clear()
	if text != line.placeholder_text:
		line.insert_text_at_caret(text)

var current_lvl_version: int

func load_file(path: String):
	save_load_opened = false
	$CanvasLayer/Panel/SaveButton.release_focus()
	$CanvasLayer/Panel/LoadButton.release_focus()
	var lvl: EditedLevel = ResourceLoader.load(path)
	if lvl == null: return
	if lvl.version <= 2: # Dictionary
		print("Version 2 map detected. Cannot load.")
		return
	else: # Array[Dictionary]
		entity_set = lvl.tiles.duplicate(true)
	for tm in tilemaps:
		tm.clear()
	for view in entity_views:
		for child in view.get_children():
			child.queue_free()
	has_saved = true
	last_level_path = path
	editorui.sav_butan.disabled = false
	last_path = path.get_base_dir() + "/"
	
	if lvl.music != play_mus:
		set_level_music(last_path + lvl.relative_music)
		clear_and_change(editorui.mus, lvl.relative_music)
	
	clear_and_change(editorui.bgi, lvl.background)
	clear_and_change(editorui.tle, lvl.fuckedtiles)
	editorui.autoscroll = lvl.bg_scroll
	editorui.parallax = lvl.bg_scale
	bg_change()
	change_tiles()
	
	level_fully_loaded = false
	level_tiles_loaded = false
	current_lvl_version = lvl.version
	
	# Convert....
	if lvl.version < LEVEL_EDITOR_VERSION:
		match lvl.version:
			1:
				for layer in entity_set:
					for key in layer:
						layer[key]["id"] = v1tov2[layer[key]["id"]]
	
	# Remove invalid cells.
	# This happens. Somehow....
	# I'm not entirely sure why this happens, but I'm suspecting the add_cell() function
	# The invalid tile only has tileset info, all of which are negative 1.....
	# For now, here's a solution that simply removes said offending tiles.
	var erasure: Array[Dictionary]
	for layer in entity_set:
		for key in layer:
			if layer[key].has("id"): 
				continue
			print("Found an invalid tile!")
			layer[key]["layer_temp"] = layer
			erasure.append(layer[key])
	for elem in erasure:
		for layer in entity_set:
			if layer.find_key(elem):
				layer.erase(layer.find_key(elem))
	
	erasure.clear()
	
	level_thread.start(level_load_threaded)
	semaphore.post()
	level_thread.wait_to_finish()

# Handle threaded level load
var semaphore: Semaphore
var level_thread: Thread
var level_mutex: Mutex
var level_fully_loaded: bool = true
var level_tiles_loaded: bool = true
var tile_dict: Dictionary
var cset: Array[Dictionary] = [
	{}, {}, {}, {}, {}
]
var applied: Array[bool] = [
	false, false, false, false, false
]

func level_load_threaded():
	semaphore.wait()
	level_mutex.lock()
	# Iterate through the entity set
	for i in range(0, 5):
		var layer: Dictionary = entity_set[i]
		tile_dict[i] = {}
		for key in layer:
			# Entity, show entity view
			var tile: Dictionary = layer[key] as Dictionary
			var flip_v_compat: bool = false
			if tile.has("flip_v"): flip_v_compat = tile["flip_v"]
			# print("id: ", tile["id"])
			# print("flip: ", tile["flip"])
			# Somehow got an invalid id!
			if not tile.has("id"):
				tile = {"id": -1, "flip": false, "flip_v": false}
			if tile != null and tile["id"] != -1 and entities[tile["id"]] != null:
				call_deferred("add_entity_dummy", tile["id"], key, i, tile["flip"], flip_v_compat)
			elif tile != null and not tile.has("source_id"):
				match tile["id"]:
					CursorType.TILE:
						BetterTerrain.call_deferred("set_cell", tilemaps[i], key, 1)
						tile_dict[i][key] = 1
						# BetterTerrain.call_deferred("update_terrain_cell", tilemaps[i], key, true)
					CursorType.SLOPE221:
						call_deferred("add_cell", i, key, 1, Vector2i(0, 4), tile["flip"], flip_v_compat)
					CursorType.SLOPE222:
						call_deferred("add_cell", i, key, 1, Vector2i(1, 4), tile["flip"], flip_v_compat)
					CursorType.SLOPE45:
						call_deferred("add_cell", i, key, 1, Vector2i(2, 4), tile["flip"], flip_v_compat)
					CursorType.PASSTHROUGH:
						BetterTerrain.call_deferred("set_cell", tilemaps[i], key, 3)
						tile_dict[i][key] = 3
						# BetterTerrain.call_deferred("update_terrain_cell", tilemaps[i], key, true)
					CursorType.START:
						call_deferred("add_entity_dummy", tile["id"], key, i)
						Map.player.call_deferred("set_global_position", key * TILE_SIZE + ENTITY_OFFSET)
			elif tile != null:
				match tile["id"]:
					CursorType.START:
						call_deferred("add_entity_dummy", tile["id"], key, i, tile["flip"], flip_v_compat)
						Map.player.call_deferred("set_global_position", key * TILE_SIZE + ENTITY_OFFSET)
					_:
						call_deferred("add_cell", i, key, tile["source_id"], tile["atlas_coords"], tile["flip"], flip_v_compat, tile["alt_id"])
		if current_lvl_version <= 3:
			cset[i] = BetterTerrain.create_terrain_changeset(tilemaps[i], tile_dict[i])
			applied[i] = false
		else:
			level_tiles_loaded = true
		lvlstatus.call_deferred("set_text", "Loaded layer %d..." % i)
	level_fully_loaded = true
	lvlstatus.call_deferred("set_text", "Level loaded!")
	level_mutex.unlock()

var temporary_opacities: Array[float] = [
	1, 1, 1, 1, 1
]

@onready var editorui : EditorUI = $EditorUI

func _ready() -> void:
	edit_target.global_position = $PhantomCamera2D.global_position
	semaphore = Semaphore.new()
	level_mutex = Mutex.new()
	level_thread = Thread.new()
	for i in range(1, 5):
		tilemaps[i].modulate.a = 0.1
		entity_views[i].modulate.a = 0.1
	editorui.toggle_panels(true)
	editorui.changed_tile_id.connect(change_tile_id)
	editorui.changed_layer.connect(change_layer)
	editorui.undo_pressed.connect(undo_last_action)
	editorui.music_apply.connect(music_apply)
	editorui.bg_apply.connect(bg_change)
	editorui.tileset_apply.connect(change_tiles)
	editorui.autoscroll_changed.connect(func(vec):
		parallax.autoscroll = vec
	)
	editorui.scrollscale_changed.connect(func(vec):
		parallax.scroll_scale = vec
	)
	editorui.nuke.connect(clear_all)
	editorui.save.connect(save_file)
	editorui.load_file.connect(load_file)
	editorui.sl_cancelled.connect(cancell)
	editorui.sav_butan.disabled = true

func undo_last_action():
	undo.undo()

func change_tile_id(id: int):
	current_cursor = id

func change_layer(inc: int):
	if inc != 0: 
		tilemaps[current_layer].modulate.a = 0.1
		entity_views[current_layer].modulate.a = 0.1
		SoundManager.play_sfx("res://sfx/new/ui/rctwindow.wav")
	current_layer = max(-2, min(2, current_layer + inc))
	if inc != 0:
		$CanvasLayer/LayerNumber.text = "[right]Layer %d[/right]" % current_layer
		tilemaps[current_layer].modulate.a = 1
		entity_views[current_layer].modulate.a = 1

func _exit_tree() -> void:
	if level_thread.is_alive():
		level_thread.wait_to_finish()

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

@warning_ignore("integer_division")
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
	for view in entity_views:
		for child in view.get_children():
			child.queue_free()

@onready var parallax: Parallax2D = $Parallax2D
@onready var parallax_sprite: Sprite2D = $Parallax2D/Sprite2D
@onready var grid_parallax: Parallax2D = $GridParallax

func bg_change(opath: String = ""):
	SoundManager.play_sfx("res://sfx/new/ui/rctclick.wav")
	var path: String = editorui.bgi.text if opath.is_empty() else opath
	if path.is_empty(): path = editorui.bgi.placeholder_text
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

var last_coords: Vector2i

func add_tile(coords: Vector2i):
	match current_cursor:
		CursorType.TILE:
			BetterTerrain.set_cell(tilemaps[current_layer], coords, 1)
			BetterTerrain.update_terrain_cell(tilemaps[current_layer], coords)
		CursorType.SLOPE221:
			add_cell(current_layer, coords, 1, Vector2i(0, 4), should_flip, should_flipv)
		CursorType.SLOPE222:
			add_cell(current_layer, coords, 1, Vector2i(1, 4), should_flip, should_flipv)
		CursorType.SLOPE45:
			add_cell(current_layer, coords, 1, Vector2i(2, 4), should_flip, should_flipv)
		CursorType.PASSTHROUGH:
			BetterTerrain.set_cell(tilemaps[current_layer], coords, 3)
			BetterTerrain.update_terrain_cell(tilemaps[current_layer], coords)
		-1: # Dummy, nothing
			return
		_:
			# Catch all for entity types
			if cursor_area.has_overlapping_areas():
				return
			add_entity_dummy(cursor_icon.frame, coords, current_layer, should_flip, should_flipv)
	# Despite being named "entity_set" this actually accounts for all possible tiles.
	if current_cursor != -1:
		entity_set[current_layer][coords] = {
			"id": current_cursor,
			"flip": should_flip,
			"flip_v": should_flipv,
		}

func remove_tile(coords: Vector2i):
	# No match here, just remove anything occupying the cell
	BetterTerrain.set_cell(tilemaps[current_layer], coords, -1)
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		BetterTerrain.update_terrain_cell(tilemaps[current_layer], coords, true)
	# Kill yourself
	tilemaps[current_layer].set_cell(coords)
	if entity_set[current_layer].has(coords):
		SoundManager.play_sfx("res://sfx/editor/eraser_input.ogg", 0.0, -8)
	entity_set[current_layer].erase(coords)
	# now
	if cursor_area.has_overlapping_areas():
		for area in cursor_area.get_overlapping_areas():
			area.queue_free()

var undo: UndoRedo = UndoRedo.new()
	
func edit_mode():
	if not level_fully_loaded: return
	if not level_tiles_loaded:
		for i in range(0, 5):
			@warning_ignore("shadowed_variable")
			var csett = cset[i]
			if not BetterTerrain.is_terrain_changeset_ready(csett):
				lvlstatus.call_deferred("set_text", "Applying tile layer %d..." % i)
				continue
			BetterTerrain.call_deferred("apply_terrain_changeset", csett)
			applied[i] = true
		var all_equal = applied.all(func(e): return e == applied.front())
		print(applied)
		if all_equal: 
			lvlstatus.call_deferred("set_text", "Level loaded!")
			level_tiles_loaded = true
	if confirm_held:
		handle_clear_confirm()
	if Input.is_action_just_pressed("editor_save"):
		save_level()
	elif Input.is_action_just_pressed("editor_load"):
		load_level()
	if save_load_opened or properties.visible or tilepanel.visible: return
	edit_target.translate(Input.get_vector("editor_left", "editor_right", "editor_up", "editor_down") * MOVE_SPEED)
	cursor.visible = true
	if Input.is_action_just_pressed("editor_flip"):
		should_flip = !should_flip
		cursor_icon.flip_h = should_flip
	if Input.is_action_just_pressed("editor_flipv"):
		should_flipv = !should_flipv
		cursor_icon.flip_v = should_flipv
	if current_cursor != -1:
		cursor_icon.frame = current_cursor
		cursor_icon.visible = true
		if editorui.eraser.button_pressed:
			cursor.modulate = Color.CORNFLOWER_BLUE
			cursor_icon.visible = false
		else:
			cursor.modulate = Color.WHITE
			cursor_icon.visible = true
	else:
		if editorui.eraser.button_pressed:
			cursor.modulate = Color.CORNFLOWER_BLUE
		else:
			cursor.modulate = Color.WHITE
		cursor_icon.visible = false
	if Input.is_action_just_pressed("cursor_up"):
		if current_cursor != -1:
			editorui.buttons[current_cursor].set_pressed_no_signal(false)
		current_cursor -= 1
		if current_cursor >= CursorType.CURSOR_MAX:
			current_cursor = 0
		elif current_cursor < 0:
			current_cursor = CursorType.CURSOR_MAX - 1
		editorui.buttons[current_cursor].set_pressed_no_signal(true)
	if Input.is_action_just_pressed("cursor_down"):
		if current_cursor != -1:
			editorui.buttons[current_cursor].set_pressed_no_signal(false)
		current_cursor += 1
		if current_cursor >= CursorType.CURSOR_MAX:
			current_cursor = 0
		elif current_cursor < 0:
			current_cursor = CursorType.CURSOR_MAX - 1
		editorui.buttons[current_cursor].set_pressed_no_signal(true)
	# Move cursor to mouse coordinates
	var view_to_world = cursor.get_canvas_transform().affine_inverse()
	cursor.global_position = view_to_world * (get_viewport().get_mouse_position()) + Vector2(-16, -16)
	var unsnapped_pos = cursor.global_position
	cursor.global_position = cursor.global_position.snapped(Vector2(32, 32))
	coordinates.text = "(%d, %d) [%d, %d]" % [round(cursor.global_position.x / TILE_SIZE), round(cursor.global_position.y / TILE_SIZE), round(unsnapped_pos.x + 16), round(unsnapped_pos.y + 16)]
	var coords = tilemap.local_to_map(cursor.global_position)
	last_coords = coords
	if Input.is_action_just_pressed("editor_tilepanel") and entity_set[current_layer].has(coords):
		tilepanel.visible = true
		tilepanel.global_position = get_viewport().get_mouse_position()
		tilepanel_ided.text = entity_set[current_layer][last_coords].get("ided", "")
		tilepanel_ref.text = entity_set[current_layer][last_coords].get("ref", "")
		tilepanel_sprite.text = entity_set[current_layer][last_coords].get("sprite", "")
	if Input.is_action_just_pressed("editor_copy"):
		saved_entity = entity_set[current_layer][last_coords]
	if Input.is_action_just_pressed("editor_paste"):
		if not cursor_area.has_overlapping_areas():
			add_entity_dummy(saved_entity["id"], coords, current_layer, should_flip, should_flipv)
			entity_set[current_layer][last_coords] = saved_entity
	# Set cursor collision mask
	# Worst way to do this probably
	cursor_area.set_collision_mask_value(8, current_layer == 0)
	cursor_area.set_collision_mask_value(9, current_layer == 1)
	cursor_area.set_collision_mask_value(10, current_layer == 2)
	cursor_area.set_collision_mask_value(11, current_layer == -2)
	cursor_area.set_collision_mask_value(12, current_layer == -1)
	# Add or remove tiles
	if  not editorui.should_ignore_panel and editorui.eraser.button_pressed and (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)):
		# backup
		if cursor_area.has_overlapping_areas():
			for area in cursor_area.get_overlapping_areas():
				area.queue_free()
		if entity_set[current_layer].has(coords):
			undo.create_action("Remove Tile")
			undo.add_do_method(remove_tile.bind(coords))
			undo.add_undo_method(add_tile.bind(coords))
			undo.commit_action()
	elif Input.is_action_pressed("editor_add") and not editorui.should_ignore_panel:
		if not entity_set[current_layer].has(coords):
			undo.create_action("Add Tile")
			undo.add_do_method(add_tile.bind(coords))
			undo.add_undo_method(remove_tile.bind(coords))
			undo.commit_action()
	var inc: int = int(Input.is_action_just_pressed("editor_rightlayer")) - int(Input.is_action_just_pressed("editor_leftlayer"))
	if inc != 0: 
		tilemaps[current_layer].modulate.a = 0.1
		entity_views[current_layer].modulate.a = 0.1
		SoundManager.play_sfx("res://sfx/new/ui/rctwindow.wav")
	current_layer = max(-2, min(2, current_layer + inc))
	if inc != 0:
		$CanvasLayer/LayerNumber.text = "[right]Layer %d[/right]" % current_layer
		tilemaps[current_layer].modulate.a = 1
		entity_views[current_layer].modulate.a = 1
	if Input.is_action_pressed("editor_resetpos"):
		for layer in entity_set:
			for key in layer:
				if layer[key] != null and layer[key]["id"] == CursorType.START:
					Map.player.global_position = key * TILE_SIZE + ENTITY_OFFSET

func play_mode():
	cursor.visible = false
	for view in entity_views:
		view.visible = false
	properties.visible = false
	properties.release_focus()

var lvlbounds: int = 0
var saved_entity: Dictionary
	
func change_mode():
	grid_parallax.modulate.a = 1 if edit_active else 0
	editorui.toggle_panels(false)
	if not edit_active:
		for i in range(0, 5):
			temporary_opacities[i] = tilemaps[i].modulate.a
			tilemaps[i].modulate.a = 1
			entity_views[i].modulate.a = 1
		lvlbounds = 0
		for layer in entity_set:
			for key in layer:
				if layer[key] != null and layer[key].has("id") and entities[layer[key]["id"]] != null:
					var ent: Node2D = entities[layer[key]["id"]].instantiate()
					ent.global_position = key * TILE_SIZE + ENTITY_OFFSET
					if layer[key]["flip"]:
						if "facing" in ent:
							ent.facing = -1
						else:
							ent.scale.x = -1
					if layer[key]["flip_v"]:
						ent.scale.y = -1
						# Small nudge
						ent.global_position.y -= TILE_SIZE
					if layer[key]["id"] == CursorType.LEVELBOUND:
						ent.type = lvlbounds
						lvlbounds += 1
					if "sprite_" in ent:
						ent.sprite_ = layer[key].get("sprite", "")
					if "last_path" in ent:
						ent.last_path = last_path
					entities_node.add_child(ent)
	else:
		# KILL ALL CHILDREN.... OF THE node i mean.
		for child in entities_node.get_children():
			child.queue_free()
		for view in entity_views:
			view.visible = true
		for i in range(0, 5):
			tilemaps[i].modulate.a = temporary_opacities[i]
			entity_views[i].modulate.a = temporary_opacities[i]
		Map.player.phantomCamera.set_limit_target(tilemap.get_path())
		# Just in case....
		for cell in tilemap.get_used_cells():
			if not entity_set[0].has(cell):
				entity_set[0][cell] = {"id": 0, "flip": false, "flip_v": false}

var edit_spr: Texture2D = preload("res://gfx/hud/edit.png")
var play_spr: Texture2D = preload("res://gfx/hud/play.png")

@warning_ignore("incompatible_ternary")
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_edit") and not Input.is_action_just_pressed("editor_paste") and not editorui.mus.has_focus() and not editorui.bgi.has_focus() and not editorui.tle.has_focus() and not tilepanel.visible:
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
		SoundManager.fade_into_bgm(EDIT_MUSIC if edit_active else play_mus, play_mus if edit_active else EDIT_MUSIC, 0.5, edit_time if edit_active else play_time, -81, -1)
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

func music_apply(opath: String = "") -> void:
	SoundManager.play_sfx("res://sfx/new/ui/rctclick.wav")
	var path: String = editorui.mus.text if opath.is_empty() else opath
	if not has_saved:
		editorui.mus_status.text = "STATUS: PLEASE SAVE FIRST!"
		return
	if last_path.is_empty():
		editorui.mus_status.text = "STATUS: PATH IS SOMEHOW EMPTY!"
		return
	if path.is_empty():
		editorui.mus_status.text = "STATUS: USING DEFAULT"
		play_mus = PLAY_MUSIC
		play_loop_end = AKRILLIC_LOOP_END
		play_loop_start = AKRILLIC_LOOP_START
		play_time = 0.0
		return
	play_mus = "res://" + path
	if set_level_music(play_mus) != null:
		editorui.mus_status.text = "STATUS: OK!"
		return
	play_mus = last_path + path
	if set_level_music(play_mus) != null:
		editorui.mus_status.text = "STATUS: OK!"
		return
	editorui.mus_status.text = "STATUS: FAILED!"

func _on_xcoord_value_changed(value: float) -> void:
	parallax.autoscroll.x = value

func _on_ycoord_value_changed(value: float) -> void:
	parallax.autoscroll.y = value

func _on_xscroll_value_changed(value: float) -> void:
	parallax.scroll_scale.x = value

func _on_yscroll_value_changed(value: float) -> void:
	parallax.scroll_scale.y = value

var tile_path: String

func change_tiles(opath: String = ""):
	SoundManager.play_sfx("res://sfx/new/ui/rctclick.wav")
	var path: String = editorui.tle.text if opath.is_empty() else opath
	if path.is_empty(): path = editorui.tle.placeholder_text
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


func _on_id_ed_input_text_changed(new_text: String) -> void:
	entity_set[current_layer][last_coords]["ided"] = new_text
	print(entity_set[current_layer][last_coords]["ided"])

func _on_ref_input_text_changed(new_text: String) -> void:
	entity_set[current_layer][last_coords]["ref"] = new_text
	print(entity_set[current_layer][last_coords]["ref"])

func _on_sprite_input_text_changed(new_text: String) -> void:
	entity_set[current_layer][last_coords]["sprite"] = new_text
	print(entity_set[current_layer][last_coords]["sprite"])
