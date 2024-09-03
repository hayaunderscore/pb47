extends Node2D
class_name HealthComponent

@export_range(1, 9999) var default_health = 1
@export_range(1, 9999) var max_health = 4
var health: int = default_health
var dead: bool = false

signal health_gained(gain: int)
signal health_deplete(old_health: int, health: int, who: Node2D)
signal death
signal revived

func _ready() -> void:
	health = default_health

func damage(dmg: int, who: Node2D):
	if health <= 0: return
	var old = health
	health -= dmg
	health_deplete.emit(old, health, who)
	if health <= 0:
		dead = true
		death.emit(who)

func heal(heal: int):
	if health >= max_health: return
	if dead:
		dead = false
		revived.emit()
	var old = health
	health += heal
	health_deplete.emit(old, health)
