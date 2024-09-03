@tool
extends CharacterBody2D

var hitbox: HitboxComponent
@onready var health_comp: HealthComponent = $HealthComponent

@export var move_what: Node2D
@export var move_amount: Vector2
@export_range(0.1, 5.0, 0.1) var move_duration: float

func _ready() -> void:
	if Engine.is_editor_hint(): return
	hitbox = get_node("HitboxComponent")
	# Erm.... no?
	health_comp.death.connect(death)
	
func _process(delta: float) -> void:
	if not Engine.is_editor_hint(): return
	if not is_instance_valid(move_what): return
	$Line2D.points[1] = to_local(move_what.global_position)

func death(who: Node2D):
	if Engine.is_editor_hint(): return
	Globals.hitstop(self)
	Globals.spawn_explosion(self, 1)
	hitbox.queue_free()
	await $HitstopComponent/Timer.timeout
	SoundManager.play_sfx("res://sfx/new/doorOpen.ogg", 0.0, -5)
	var last_pos = move_what.global_position
	get_tree().create_tween().tween_property(move_what, "global_position", last_pos+move_amount, 0.8)
	$Sprite2D.frame = 1
