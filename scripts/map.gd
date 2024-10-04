extends Node

# If I would support multiplayer this should probably be reworked....
var player: Bliggy
var player_scene: PackedScene = preload("res://res/obj/Bliggy.tscn")
var fade: PackedScene = preload("res://res/obj/VFX/fade.tscn")
var fadein: PackedScene = preload("res://res/obj/VFX/fadein.tscn")
var loading_screen: PackedScene = preload("res://res/obj/VFX/loading_screen.tscn")
var hudstuff: PackedScene = preload("res://res/obj/VFX/hud.tscn")
var hud_instance: HeadsUpDisplay
var loading_instance: CanvasLayer
var loading: bool = false
var is_new_game: bool = false
var target_scene: String
var target_scene_instance: Node2D
var coordinates: Vector2
var stupidOffset: Vector2 = Vector2(0, 32)

func new_game(target: String, tile_coords: Vector2):
	# New game means we're starting from scratch, so kill off everything.
	if is_instance_valid(player):
		player.queue_free()
	if is_instance_valid(target_scene_instance):
		target_scene_instance.queue_free()
	player = player_scene.instantiate()
	ResourceLoader.load_threaded_request(target)
	# Coords are generally by tile basis.
	coordinates = tile_coords * 32
	player.global_position = coordinates + stupidOffset
	target_scene = target
	loading_instance = loading_screen.instantiate()
	get_tree().current_scene.add_child(loading_instance)
	loading = true
	
func create_fade(speed_scale: float = 4, fade_in: bool = false):
	var fade_instance: CanvasLayer = fadein.instantiate() if fade_in else fade.instantiate()
	var anim: AnimationPlayer = fade_instance.get_node("AnimationPlayer")
	anim.speed_scale = speed_scale
	get_tree().current_scene.add_child(fade_instance)
	return 0.768 / speed_scale
	
func move_player(tile_coords: Vector2, target: String = ""):
	if not is_instance_valid(player):
		return
	if target.is_empty():
		player.global_position = tile_coords * 32
		return
	target_scene = target
	await get_tree().create_timer(create_fade(4, true), true, true, true).timeout
	target_scene_instance.remove_child(player)
	get_tree().current_scene.remove_child(target_scene_instance)
	target_scene_instance.queue_free()
	target_scene_instance = load(target).instantiate()
	create_fade(4, false)
	player.global_position = tile_coords * 32 + stupidOffset
	target_scene_instance.add_child(player)
	find_phantom_cam()
	find_hud()
	get_tree().current_scene.add_child(target_scene_instance)
	
func find_phantom_cam():
	if not is_instance_valid(target_scene_instance): return
	var pcam: PhantomCamera2D = target_scene_instance.get_node_or_null("PhantomCamera2D")
	if pcam == null: return
	pcam.follow_target = player
	# Do NOT ease into player position
	pcam.global_position = player.global_position
	player.phantomCamera = pcam

# Rename this to something like create_hud() idk
func find_hud():
	if not is_instance_valid(target_scene_instance): return
	if is_instance_valid(hud_instance): return
	hud_instance = hudstuff.instantiate()
	get_tree().current_scene.add_child(hud_instance)
	player.hud = hud_instance

func load_level_final(_progress):
	loading_instance.get_node("Label").text = "loading.... Done!"
	create_fade(4, false)
	target_scene_instance = ResourceLoader.load_threaded_get(target_scene).instantiate()
	target_scene_instance.add_child(player)
	if is_instance_valid(hud_instance):
		hud_instance.queue_free()
	find_phantom_cam()
	find_hud()
	get_tree().current_scene.add_child(target_scene_instance)
	get_tree().current_scene.remove_child(loading_instance)
	loading_instance.queue_free()
	loading = false
	
func load_level_screen(_delta):
	var progress = []
	ResourceLoader.load_threaded_get_status(target_scene, progress)
	if ResourceLoader.load_threaded_get_status(target_scene) == ResourceLoader.THREAD_LOAD_LOADED:
		load_level_final(progress)
	else:
		loading_instance.get_node("Label").text = "loading.... %03d%%" % (progress[0]*100)
		
func add_object(node: Node):
	target_scene_instance.add_child(node)
	
func _process(delta: float) -> void:
	if loading:
		load_level_screen(delta)
	pass
