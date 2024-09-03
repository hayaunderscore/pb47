extends Node
class_name GlobalHandle

var spinny := preload("res://res/obj/VFX/spinny.tscn")
var explosion := preload("res://res/obj/VFX/explosion.tscn")

var screenShake_noise: FastNoiseLite = FastNoiseLite.new()
var shakeDecay: float = 0.016
var shakeMaxOffset: Vector2 = Vector2(100, 75)
var shakeMaxRoll: float = 0.1

var shakeTrauma: float = 0.0
var shakePower: float = 2.0

var snoise_y: float = 0.0
var maxDist: float = 320.0

func _ready() -> void:
	screenShake_noise.seed = Time.get_ticks_msec()
	
func screen_shake(amount: float, source: Node2D = null):
	if source != null:
		var cams = PhantomCameraManager.get_phantom_camera_2ds()
		for cam in cams:
			var dist = source.global_position.distance_to(cam.follow_target.global_position)
			if dist <= maxDist:
				shakeTrauma = min(shakeTrauma + amount * (maxDist/dist) / 4, 0.4)
	else:
		shakeTrauma = min(shakeTrauma + amount, 5.0)

func _process(delta: float) -> void:
	if not shakeTrauma: return
	shakeTrauma = max(shakeTrauma - shakeDecay * delta*60, 0.0)
	# print(shakeTrauma)
	snoise_y += 1
	var cams = PhantomCameraManager.get_phantom_camera_2ds()
	for cam in cams:
		var amount = pow(shakeTrauma, shakePower)
		var cam2d = cam.pcam_host_owner.camera_2d
		cam2d.rotation = shakeMaxRoll * amount * screenShake_noise.get_noise_2d(randi_range(-256, 256), snoise_y)
		cam2d.offset.x = shakeMaxOffset.x * amount * screenShake_noise.get_noise_2d(randi_range(-256, 256), snoise_y)
		cam2d.offset.y = shakeMaxOffset.y * amount * screenShake_noise.get_noise_2d(randi_range(-256, 256), snoise_y)

func spawn_spinny(sprite: Sprite2D, source: Node2D, node: Node2D, tree: Node = null):
	var spin := spinny.instantiate() as SpinnyBoi
	spin.player = source
	spin.texture = sprite.texture
	spin.global_position = node.global_position
	spin.region_enabled = sprite.region_enabled
	spin.region_rect = sprite.region_rect
	spin.rotation_degrees = node.rotation_degrees
	spin.scale = sprite.scale * node.scale
	spin.offset = sprite.offset
	spin.centered = sprite.centered
	# Does this even work????
	if tree == null:
		Map.add_object(spin)
	else:
		tree.add_child(spin)
	return spin

func spawn_spinny_animated(sprite: AnimatedSprite2D, source: Node2D, node: Node2D, tree: Node = null):
	var spin := spinny.instantiate() as SpinnyBoi
	spin.player = source
	spin.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	spin.global_position = node.global_position
	spin.rotation_degrees = node.rotation_degrees
	spin.scale = sprite.scale * node.scale
	spin.offset = sprite.offset
	spin.centered = sprite.centered
	# Does this even work????
	if tree == null:
		Map.add_object(spin)
	else:
		tree.add_child(spin)
	return spin

func spawn_explosion(source: Node2D, size_multiplier: float = 0.5, speed: float = 1.0):
	var explode := explosion.instantiate() as AnimatedSprite2D
	explode.global_position = source.global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	explode.scale = source.scale * size_multiplier
	explode.speed_scale = speed
	screen_shake(0.2, explode)
	get_tree().current_scene.add_child(explode)
	return explode

func hitstop(node: Node2D, duration: float = -1):
	if node.get_node_or_null("HitstopComponent") != null:
		var comp = node.get_node("HitstopComponent") as SakuraiComponent
		var old_stop: float = 0.0
		if duration > 0: 
			old_stop = comp.timer.wait_time
			comp.timer.wait_time = duration
		comp.hit_stop()
		if duration > 0: comp.timer.wait_time = old_stop
		SoundManager.play_sfx("res://sfx/hitstop.ogg", 0.0, -10)
