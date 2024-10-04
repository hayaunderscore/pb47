extends Enemy

var facing = 1
var stuntime = 0.0
var taunting = false
var findEnemy: Node2D
var ogcolor: Color
var aaaa: AudioStream = preload("res://sfx/new/minidomuScream.wav")
var randomSpeed: float = 0.0

func _ready():
	ogcolor = modulate
	$AudioStreamPlayer2D.stream = aaaa
	hitbox.monitoring = false
	hitbox.monitorable = false
	randomSpeed = randi_range(-20, 20)
	$AnimatedSprite2D.scale.x = facing
	$Node2D.scale.x = facing
	super()

func _process(delta: float) -> void:
	stuntime = max(0, stuntime - delta)
	if stuntime:
		modulate = Color(1000, 1000, 1000, 1000) if (floori(stuntime*30) & 3) else Color.WHITE
	velocity += get_gravity() * delta
	if stuntime == 0 and is_instance_valid(findEnemy) and not $AnimationPlayer.is_playing():
		$AnimatedSprite2D.play("Run")
		$AnimatedSprite2D.speed_scale = 6
		var dist = findEnemy.global_position - global_position
		facing = sign(dist.normalized().x)
		if facing != 0:
			$AnimatedSprite2D.scale.x = facing
			$Node2D.scale.x = facing
		velocity.x = (310 + randomSpeed) * facing
		if $Node2D/JumpCheck.is_colliding() and is_on_floor():
			velocity.y = -400
	else:
		velocity.x = move_toward(velocity.x, 0, 30)
	
	move_and_slide()
	
func taunt(_victim: Node2D):
	pass

var lastwho: Node2D
func death(_who: Node2D):
	$AnimationPlayer.play("Explode")
	$AnimatedSprite2D.play("Dead")
	# $HitboxComponent.queue_free()
	
@warning_ignore("integer_division")
func explode():
	global_position.y -= 55/2
	Globals.spawn_spinny_animated($AnimatedSprite2D, self, self)
	var expl = Globals.spawn_explosion(self, 4, 0.25)
	expl.get_node("AudioStreamPlayer2D").stream = preload("res://sfx/bloopExplode2.wav")
	expl.get_node("AudioStreamPlayer2D").volume_db = 0
	expl.get_node("AudioStreamPlayer2D").play()
	var ranged: Area2D = $ExplodeRange2
	if ranged.has_overlapping_areas():
		for area in ranged.get_overlapping_areas():
			if area is HitboxComponent:
				if area.health_component:
					area.health_component.damage(2, self)
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

func _on_mini_range_area_entered(area: Area2D) -> void:
	findEnemy = area
	hitbox.set_deferred("monitorable", true)
	hitbox.set_deferred("monitoring", true)
	$AudioStreamPlayer2D.play()

func _on_explode_range_entered(body: Node2D) -> void:
	if body == hitbox: return
	if body.get_parent() is not Bliggy: return
	death(body)
