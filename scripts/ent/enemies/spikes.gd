extends CharacterBody2D

var hitbox: HitboxComponent
@export var damage_dealt: int = 1

func _ready() -> void:
	hitbox = get_node("HitboxComponent")
	hitbox.hitbox_collision.connect(taunt)
	# Erm.... no?
	hitbox.automatically_deplete_health = false

func _process(delta: float) -> void:
	move_and_slide()
	# Constantly check for areas here instead of when we enter it
	if hitbox.has_overlapping_areas():
		for area in hitbox.get_overlapping_areas():
			hitbox.collide_with_node(area)
	
func taunt(victim: Node2D):
	# Victim is a projectile, don't bother!
	if victim is Projectile2D: return
	# The taunt system basically makes it so that any collision
	# would harm who collided.
	# The collider doesn't collide with the enemy at all- its
	# the enemy themselves calling their damage function.
	if victim.health_component:
		victim.health_component.damage(damage_dealt, self)
