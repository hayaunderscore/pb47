extends Enemy
var facing = 1
var stuntime = 0.0
var taunting = false
var ogcolor: Color

func _ready():
	ogcolor = modulate
	scale.x = facing
	super()

func _process(delta: float) -> void:
	stuntime = max(0, stuntime - delta)
	if stuntime:
		modulate = Color(1000, 1000, 1000, 1000) if (floori(stuntime*30) & 3) else Color.WHITE
	velocity += get_gravity() * delta
	if stuntime == 0 and not taunting and not health_comp.dead:
		$AnimatedSprite2D.play("Run")
		if not $FloorCheck.is_colliding() and is_on_floor():
			facing *= -1
			scale.x *= -1
		if $WallCheck.is_colliding() and is_on_floor():
			facing *= -1
			scale.x *= -1
		velocity.x = 100 * facing
	else:
		velocity.x = move_toward(velocity.x, 0, 30)
	
	move_and_slide()
	
func taunt(victim: Node2D):
	# Victim is a projectile, don't bother!
	if victim is Projectile2D: return
	# We can't taunt anymore, idiot.
	if health_comp.dead: return
	# if taunting: return
	# The taunt system basically makes it so that any collision
	# would harm who collided.
	# The collider doesn't collide with the enemy at all- its
	# the enemy themselves calling their damage function.
	if victim.health_component:
		victim.health_component.damage(damage_dealt, self)
	taunting = true
	$AnimatedSprite2D.play("Nyehehe")
	await get_tree().create_timer(0.5, true, false, true).timeout
	taunting = false

var lastwho: Node2D
func death(who: Node2D):
	lastwho = who
	$AnimationPlayer.play("Death")
	$AnimatedSprite2D.play("Dead")
	$HitboxComponent.queue_free()
	
@warning_ignore("integer_division")
func explode():
	global_position.y -= 55/2
	Globals.spawn_spinny_animated($AnimatedSprite2D, self, self)
	var expl = Globals.spawn_explosion(self, 1)
	expl.get_node("AudioStreamPlayer2D").stream = preload("res://sfx/bloopExplode2.wav")
	expl.get_node("AudioStreamPlayer2D").volume_db = 0
	expl.get_node("AudioStreamPlayer2D").play()
	queue_free()

func damage(old: int, health: int, who: Node2D):
	super(old, health, who)
	if health_comp.health == old:
		return
	if stuntime > 0.0:
		health_comp.health = old
		if who is Projectile2D:
			who.queue_for_death = false
		return
	stuntime = 0.3
	modulate = Color(1000, 1000, 1000, 1000)
	$AnimatedSprite2D.play("Dead")
