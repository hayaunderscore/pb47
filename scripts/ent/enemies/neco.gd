extends Enemy
var facing = 1
var stuntime = 0.0
var ogcolor: Color

var atkSounds: Array[AudioStream] = [preload("res://sfx/new/necoAttack1.wav"), preload("res://sfx/new/necoAttack2.wav")]
var damageSound: AudioStream = preload("res://sfx/new/necoDamage1.wav")

func _ready():
	ogcolor = modulate
	scale.x = facing
	super()

func _process(delta: float) -> void:
	stuntime = max(0, stuntime - delta)
	if stuntime:
		modulate = Color(1000, 1000, 1000, 1000) if (floori(stuntime*30) & 3) else Color.WHITE
	velocity += get_gravity() * delta
	if stuntime == 0:
		$AnimatedSprite2D.play("Run")
		if not $FloorCheck.is_colliding() and is_on_floor():
			facing *= -1
			scale.x *= -1
		if $WallCheck.is_colliding() and is_on_floor():
			facing *= -1
			scale.x *= -1
		if $JumpCheck.is_colliding() and is_on_floor():
			velocity.y = -400
		velocity.x = 200 * facing
	else:
		velocity.x = move_toward(velocity.x, 0, 30)
	
	move_and_slide()
	
@warning_ignore("integer_division")
func death(who: Node2D):
	$AnimatedSprite2D.play("Dead")
	global_position.y -= 55/2
	var body = Globals.spawn_spinny_animated($AnimatedSprite2D, who, self)
	Globals.spawn_explosion(self, 1)
	Globals.hitstop(body)
	body.get_node("AudioStreamPlayer2D").stream = damageSound
	body.get_node("AudioStreamPlayer2D").play()
	queue_free()
	
func taunt(victim: Node2D):
	# Victim is a projectile, don't bother!
	if victim is Projectile2D: return
	# We can't taunt anymore, idiot.
	if health_comp.dead: return
	# The taunt system basically makes it so that any collision
	# would harm who collided.
	# The collider doesn't collide with the enemy at all- its
	# the enemy themselves calling their damage function.
	if victim.get_parent() is Bliggy:
		var parent = victim.get_parent() as Bliggy
		if parent.iframes.is_stopped():
			$AudioStreamPlayer2D.stream = atkSounds.pick_random()
			$AudioStreamPlayer2D.play()
	if victim.health_component:
		victim.health_component.damage(damage_dealt, self)
	

func damage(old: int, health: int, who: Node2D):
	super(old, health, who)
	if health_comp.health == old:
		return
	if stuntime > 0.0:
		health_comp.health = old
		if who is Projectile2D:
			who.queue_for_death = false
		return
	if not health_comp.dead:
		$AudioStreamPlayer2D.stream = damageSound
		$AudioStreamPlayer2D.play()
	stuntime = 0.3
	modulate = Color(1000, 1000, 1000, 1000)
	$AnimatedSprite2D.play("Dead")
