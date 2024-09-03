extends CharacterBody2D
class_name Bliggy

@onready var spritePivot: Node2D = $SpritePivot
@onready var sprite: Sprite2D = $SpritePivot/Sprite2D
@onready var gun: Node2D = $GunPivot
@onready var anim: AnimationPlayer = $AnimationPlayer

@onready var col: CollisionShape2D = $FlatCollision
@onready var colPointy: CollisionPolygon2D = $SlopeCollision
@onready var switchSound: AudioStreamPlayer = $SwitchSound

@onready var gunSound: AudioStreamPlayer2D = $GunSound
@onready var shotgunSound: AudioStream = preload("res://sfx/shotgunOld.wav")
@onready var machinegunSound: AudioStream = preload("res://sfx/machinegun.wav")
@onready var revolverSound: AudioStream = preload("res://sfx/revolver.ogg")

@onready var health_comp: HealthComponent = $HealthComponent
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var iframes: Timer = $IFrames

@onready var recoilCheckLeft: RayCast2D = $RecoilCheckLeft
@onready var recoilCheckRight: RayCast2D = $RecoilCheckRight
@onready var slopeNormal: Node2D = $SlopeCheck
@onready var ledgeRay: RayCast2D = $LedgeCheck

@export var hud: HeadsUpDisplay
@onready var brolyki: PackedScene = preload("res://res/obj/VFX/broly_ki.tscn")

const MAX_SPEED = 300
const ACCELERATION = 50
const ACCELERATION_TURN = 60
const DECELERATION = 40
const ACCEL_DECEL = 15

const SHOTGUN_HFORCE = MAX_SPEED * 3
const SHOTGUN_HFORCE_WALLED = MAX_SPEED * 4
const SHOTGUN_HFORCE_FLOORED = MAX_SPEED * 2.5
const SHOTGUN_VFORCE = 600

const MACHINEGUN_HFORCE = MAX_SPEED * 2
const MACHINEGUN_VFORCE = 275

const REVOLVER_HFORCE = MAX_SPEED * 5
const REVOLVER_HFORCE_WALLED = MAX_SPEED * 5.75
const REVOLVER_HFORCE_FLOORED = MAX_SPEED * 7
const REVOLVER_VFORCE = 1200

const SHOTGUN_ID = 0
const MACHINEGUN_ID = 1
const REVOLVER_ID = 2

var facing: int = 1
var currentGun: int = 0
var guns: Array[BliggyGun]
@export var defaultGuns: Array[PackedScene]
@export var phantomCamera: PhantomCamera2D

var gunaxis: Vector2
var last_floor: bool = false

var checkpoint : Vector2

func _ready() -> void:
	for scene in defaultGuns:
		add_gun(scene.instantiate())
	gun.add_child(guns[currentGun])
	# Erm.... no?
	hitbox.automatically_deplete_health = false
	health_comp.death.connect(death)
	health_comp.health_deplete.connect(damage)
	health_comp.health = health_comp.max_health
	iframes.timeout.connect(iframe_timeout)
	checkpoint = global_position

func damp(from: float, to: float, time: float, dt: float) -> float:
	return move_toward(from, to, 1 - pow(time, dt))
	
func iframe_timeout():
	if not health_comp.dead:
		visible = true
		
var faceLerp: float = 1

func _physics_process(delta: float) -> void:
	if health_comp.dead:
		anim.play("Dead")
		velocity = Vector2.ZERO
		return
	
	if not is_on_floor() and last_floor:
		$WileTimer.start()
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if not iframes.is_stopped() and (floori(iframes.time_left*30) % 2 == 0):
		visible = !visible
		
	col.disabled = ledgeRay.is_colliding()
	colPointy.disabled = !col.disabled
	
	var axis: float = Input.get_axis("ui_left", "ui_right")
	if axis:
		if abs(velocity.x) > MAX_SPEED && axis != facing:
			velocity.x = move_toward(velocity.x, MAX_SPEED * axis, ACCELERATION)
		elif abs(velocity.x) > MAX_SPEED && axis == facing:
			velocity.x = move_toward(velocity.x, MAX_SPEED * axis, ACCEL_DECEL)
		else:
			velocity.x = move_toward(velocity.x, MAX_SPEED * axis, ACCELERATION)
		facing = axis
		anim.play("Walk")
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION)
		anim.play("Idle")
	faceLerp = lerpf(faceLerp, facing, 0.3)
	if faceLerp > 0.25 or faceLerp < -0.25:
		spritePivot.scale.x = faceLerp
	$SlopeCheck.scale.x = facing
	if not is_on_floor():
		anim.play("Airborne")
	
	var gunselect: float = Input.get_axis("switch_left", "switch_right")
	if Input.is_action_just_pressed("switch_left") or Input.is_action_just_pressed("switch_right"):
		# Remove the current gun
		for gunchild in gun.get_children():
			gun.remove_child(gunchild)
		currentGun += ceili(gunselect)
		if currentGun > guns.size() - 1:
			currentGun = 0
		if currentGun < 0:
			currentGun = guns.size() - 1
		match guns[currentGun].id:
			SHOTGUN_ID:
				gunSound.stream = shotgunSound
			MACHINEGUN_ID:
				gunSound.stream = machinegunSound
			REVOLVER_ID:
				gunSound.stream = revolverSound
		gun.add_child(guns[currentGun])
		guns[currentGun].ammoLabel.modulate.a = 1
		if hud:
			hud.set_ammo(guns[currentGun].ammo if guns[currentGun].max_ammo > 0 else -1)
		switchSound.play()
	
	gunaxis = Input.get_vector("left", "right", "up", "down")
	if gunaxis.x == 0 and gunaxis.y == 0:
		gunaxis.x = facing
	gunaxis.x *= -1 if gunaxis.y > 0 else 1
	var gunang = gunaxis.angle() + (slopeNormal.get_node("RecoilCheckDown").get_collision_normal().angle() + deg_to_rad(90)) if is_on_floor() and gunaxis.y == 0 else gunaxis.angle()
	gun.rotation = lerp_angle(gun.rotation, gunang, 0.2)
	guns[currentGun].ammoLabel.rotation = -gun.rotation * guns[currentGun].ammoLabel.scale.y
	# print(guns[currentGun].ammoLabel.rotation)
	var rotated: Vector2 = Vector2.RIGHT.rotated(gun.rotation)
	if rotated.x < 0:
		gun.scale.y = -1
	else:
		gun.scale.y = 1
		
	if is_on_floor() and guns[currentGun].max_ammo > 0 and not Input.is_action_pressed("shoot") and guns[currentGun].gunCooldown <= 0 and guns[currentGun].ammoCooldown <= 0:
		guns[currentGun].ammo += 1
		if guns[currentGun].ammo > guns[currentGun].max_ammo:
			guns[currentGun].ammo = guns[currentGun].max_ammo
		else:
			guns[currentGun].ammoLabel.modulate.a = 1
		if hud:
			hud.set_ammo(guns[currentGun].ammo if guns[currentGun].max_ammo > 0 else -1)
		guns[currentGun].ammoCooldown = 0.08
	
	if guns[currentGun].gunCooldown == 0:
		if guns[currentGun].id == MACHINEGUN_ID and Input.is_action_pressed("shoot") and guns[currentGun].ammo > 0:
			guns[currentGun].shoot_gun(gunang)
		elif Input.is_action_just_pressed("shoot"):
			$ShootTimer.start()
			guns[currentGun].shoot_gun(gunang)
		if hud:
			hud.set_ammo(guns[currentGun].ammo if guns[currentGun].max_ammo > 0 else -1)
		
	# Have to move this here
	if guns[currentGun].id != MACHINEGUN_ID && gunaxis.y > 0:
		if (is_on_floor() and not $ShootTimer.is_stopped()) or (not $WileTimer.is_stopped() and Input.is_action_just_pressed("shoot")):
			match guns[currentGun].id:
				SHOTGUN_ID:
					velocity.y = -SHOTGUN_VFORCE
					velocity.x = round(gunaxis.x) * -1 * SHOTGUN_HFORCE
				REVOLVER_ID:
					velocity.y = -REVOLVER_VFORCE
					velocity.x = round(gunaxis.x) * -1 * REVOLVER_HFORCE
			$WileTimer.stop()
			$ShootTimer.stop()
			
	if Input.is_action_just_pressed("ui_accept"):
		health_comp.health = 0
		health_comp.dead = true
		if hud:
			hud.health_set(health_comp.health)
		death(self)
		
	if Input.is_action_just_pressed("ui_cancel"):
		Map.move_player(Vector2(4, 10), "res://res/lvl/building_b.tscn")
	
	# Handle camera offsets and other things.
	if phantomCamera:
		phantomCamera.follow_damping_value.y = max(0.1, 0.5 - (abs(velocity.y) / SHOTGUN_VFORCE))
		phantomCamera.follow_offset.x = lerp(phantomCamera.follow_offset.x, 150.0 * facing, abs(velocity.x)/MAX_SPEED/30)
		if is_on_floor():
			phantomCamera.follow_offset.y = lerp(phantomCamera.follow_offset.y, -20.0, 0.5)
			if abs(get_floor_normal().angle()) > 2:
				phantomCamera.follow_offset.y = lerp(phantomCamera.follow_offset.y, -20.0 * get_floor_normal().y*4*-facing, abs(velocity.x)/MAX_SPEED)
		else:
			phantomCamera.follow_offset.y = lerp(phantomCamera.follow_offset.y, 0.0, abs(velocity.y)/MAX_SPEED*2/30)

	last_floor = is_on_floor()
	move_and_slide()
	
func add_gun(gun: BliggyGun):
	gun.player = self
	if gun.max_ammo > 0:
		gun.ammo = gun.max_ammo
	guns.append(gun)

func gun_fire(id: int):
	gunSound.play()
	match id:
		SHOTGUN_ID:
			guns[currentGun].gunCooldown = 0.15
			if gunaxis.y <= 0:
				var hforce = SHOTGUN_HFORCE_FLOORED if is_on_floor() else SHOTGUN_HFORCE_WALLED
				if recoilCheckLeft.is_colliding() and recoilCheckLeft.get_collision_normal() == Vector2.RIGHT and gunaxis.x < 0:
					velocity.x = hforce
					velocity.y = -SHOTGUN_VFORCE / 2
					# print("hi")
				elif recoilCheckRight.is_colliding() and recoilCheckRight.get_collision_normal() == Vector2.LEFT and gunaxis.x > 0:
					velocity.x = -hforce
					velocity.y = -SHOTGUN_VFORCE / 2
		MACHINEGUN_ID:
			guns[currentGun].gunCooldown = 0.09
			guns[currentGun].addoffset.y = move_toward(guns[currentGun].addoffset.y, randi_range(-2, 2), 1)
			if not is_on_floor() && gunaxis.y != 0:
				velocity.x = gunaxis.x * -1 * MACHINEGUN_HFORCE
			if gunaxis.y != 0:
				velocity.y = MACHINEGUN_VFORCE * gunaxis.y * -1
		REVOLVER_ID:
			Globals.screen_shake(0.5)
			guns[currentGun].gunCooldown = 2.0
			velocity.x = REVOLVER_VFORCE / 3 * gunaxis.x * -1
			if gunaxis.y <= 0:
				var hforce = REVOLVER_HFORCE_FLOORED if is_on_floor() else REVOLVER_HFORCE_WALLED
				if recoilCheckLeft.is_colliding() and gunaxis.x < 0:
					velocity.x = hforce
					velocity.y = -REVOLVER_VFORCE / 2
					# print("hi")
				elif recoilCheckRight.is_colliding() and gunaxis.x > 0:
					velocity.x = -hforce
					velocity.y = -REVOLVER_VFORCE / 2
	pass

func death(who: Node2D):
	# Spawn difference circle and prepare to explode
	iframes.stop()
	visible = true
	gun.visible = false
	var broly := brolyki.instantiate()
	broly.global_position = global_position - Vector2(0, 55/2)
	Map.add_object(broly)
	SoundManager.play_sfx("res://sfx/sfx_scdfm74.ogg", 0.0, -10)
	Globals.spawn_spinny(guns[currentGun].sprite, self, gun)
	await get_tree().create_timer(0.5).timeout
	# Explode!
	visible = false
	gun.visible = true
	SoundManager.play_sfx("res://sfx/sfx_tyrondie.ogg", 0.0, -10)
	global_position.y -= 55/2
	Globals.spawn_explosion(self, 2, 0.25)
	Globals.screen_shake(2.0)
	# Prepare to respawn....
	await get_tree().create_timer(3.0).timeout
	global_position = checkpoint
	health_comp.dead = false
	health_comp.health = health_comp.max_health
	iframes.start()
	if hud:
		hud.health_set(health_comp.health)

func damage(old: int, health: int, who: Node2D):
	if not iframes.is_stopped():
		health_comp.health = old
		health_comp.dead = false
		return
	if not health <= 0:
		iframes.start()
	if hud:
		hud.health_set(health)
	if not health <= 0:
		velocity.y = -SHOTGUN_VFORCE / 1.5
		velocity.x = 600 * sign(global_position.x - who.global_position.x)
		move_and_slide()
		Globals.screen_shake(0.5)
		Globals.hitstop(self, 0.2)
		Globals.hitstop(who, 0.2)
		await $HitstopComponent/Timer.timeout
		SoundManager.play_sfx("res://sfx/bliggyHurt1.wav", 0.0, -8)
