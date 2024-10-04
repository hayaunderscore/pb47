extends CharacterBody2D
class_name Enemy

@onready var health_comp: HealthComponent = $HealthComponent
@onready var hitbox: HitboxComponent = $HitboxComponent

@export var damage_dealt: int = 1
@export_range(1, 255) var pain_chance: int = 255

func _ready():
	hitbox.hitbox_collision.connect(taunt)
	# Erm.... no?
	hitbox.automatically_deplete_health = false
	health_comp.death.connect(death)
	health_comp.health_deplete.connect(damage)
	
func taunt(victim: Node2D):
	# Victim is a projectile, don't bother!
	if victim is Projectile2D: return
	# We can't taunt anymore, idiot.
	if health_comp.dead: return
	# The taunt system basically makes it so that any collision
	# would harm who collided.
	# The collider doesn't collide with the enemy at all- its
	# the enemy themselves calling their damage function.
	if victim.health_component:
		victim.health_component.damage(damage_dealt, self)

func death(_who: Node2D):
	queue_free()

func damage(old: int, health: int, _who: Node2D):
	if randi_range(0, 255) > pain_chance and not old-health >= 8:
		health_comp.health = old
		health_comp.dead = false
		return
	# print("augh")
	# Code own logic here
