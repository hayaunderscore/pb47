extends CharacterBody2D

var hitbox: HitboxComponent
var target: Node2D
var activated: bool = false
@export var damage_dealt: int = 1

func _ready() -> void:
	hitbox = get_node("HitboxComponent")
	hitbox.hitbox_collision.connect(taunt)
	# Erm.... no?
	hitbox.automatically_deplete_health = false

func _process(delta: float) -> void:
	if is_instance_valid(target):
		var dist = target.global_position.x - global_position.x
		$AnimatedSprite2D.scale.x = sign(dist)
	move_and_slide()
	
func taunt(victim: Node2D):
	# Victim is a projectile, don't bother!
	if victim is Projectile2D: return
	$AnimatedSprite2D.play("RieIdle")
	if activated: return
	# The taunt system basically makes it so that any collision
	# would harm who collided.
	# The collider doesn't collide with the enemy at all- its
	# the enemy themselves calling their damage function.
	if victim.get_parent() is not Bliggy: return
	var blig: Bliggy = victim.get_parent() as Bliggy
	blig.checkpoint = global_position
	SoundManager.play_sfx("res://sfx/checkpoint.wav", 0.0, -4)
	activated = true

func _on_semi_peek_area_entered(area: Area2D) -> void:
	$AnimatedSprite2D.play("RiePeek")
	target = area

func _on_semi_peek_area_exited(area: Area2D) -> void:
	$AnimatedSprite2D.play("BuriedIdle")
	target = null

func _on_full_peek_area_entered(area: Area2D) -> void:
	$AnimatedSprite2D.play("RieIdle")

func _on_full_peek_area_exited(area: Area2D) -> void:
	$AnimatedSprite2D.play("RiePeek")
