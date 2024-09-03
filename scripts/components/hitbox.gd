extends Area2D
class_name HitboxComponent

@export var health_component: HealthComponent
@export var automatically_deplete_health: bool = true
@export var damage_taken: int = 1
signal hitbox_collision(node: Node2D)

func _ready() -> void:
	area_entered.connect(collide_with_node)
	body_entered.connect(collide_with_node)
	
func collide_with_node(node: Node2D):
	if automatically_deplete_health and health_component:
		health_component.damage(damage_taken, node)
	hitbox_collision.emit(node)

# Projectiles call this.
func damage(dmg: int, proj: Projectile2D):
	if health_component:
		health_component.damage(dmg, proj)
	hitbox_collision.emit(proj)
