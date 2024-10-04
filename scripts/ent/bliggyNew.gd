extends CharacterBody2D
class_name PlayerObject

## OTHER NODES ##

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var base_collision: CollisionShape2D = $CollisionBox
@onready var slope_collision: CollisionPolygon2D = $SlopeBox

@onready var health_comp: HealthComponent = $HealthComponent
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var hitstop: SakuraiComponent = $HitstopComponent

@onready var coyote: Timer = $CoyoteTimer
@onready var input_buffer: Timer = $BufferTimer

@onready var slopeColArea: Area2D = $CollisionSwitch

@onready var gunPivot: Node2D = $GunPivot

## VALUES ##

var direction: Vector2 = Vector2.ZERO
var gun_direction: Vector2 = Vector2.ZERO
var facing: int = 1

var gravity_multiplier: float = 1.0
var max_fall_speed: float = 640.0

var base_acceleration: float = 4096.0
var base_deceleration: float = 700.0
var air_mult: float = 0.76

var max_speed: float = 300.0

var shotgun_speed: float = 620.0

func _ready() -> void:
	facing = round(scale.x)
	scale.x = 1
	var gun = load("res://res/obj/BliggyShotgun.tscn").instantiate()
	gun.player = self
	gunPivot.add_child(gun)
	
func shotgun_propel(dir: Vector2):
	dir = round(dir)
	var newSpeed: Vector2 = dir * shotgun_speed
	if sign(velocity.x) == sign(newSpeed.x) and abs(velocity.x) > abs(newSpeed.x):
		newSpeed.x = velocity.x
	velocity.x = newSpeed.x
	velocity.y = -600.0

func attempt_correction(amount: int):
	var delta = get_physics_process_delta_time()
	if velocity.y < 0 and test_move(global_transform,
	Vector2(0, velocity.y*delta)):
		for i in range(1, amount*2+1):
			for j in [-1.0, 1.0]:
				if !test_move(global_transform.translated(Vector2(i*j/2, 0)),
				Vector2(0, velocity.y*delta)):
					translate(Vector2(i*j/2, 0))
					if velocity.x * j < 0: velocity.x = 0
					return

func _physics_process(delta: float) -> void:
	base_collision.disabled = slopeColArea.has_overlapping_bodies()
	slope_collision.disabled = !base_collision.disabled
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		# Limit fall speed
		velocity.y = min(velocity.y, max_fall_speed)
	
	direction = Input.get_vector("left", "right", "up", "down")
	if sign(direction.x) != 0:
		facing = sign(direction.x)
	sprite.scale.x = facing
	
	var mul: float = 1.0 if is_on_floor() else air_mult
	var signed: float = sign(direction.x)
	if abs(velocity.x) > max_speed and sign(velocity.x) == signed:
		velocity.x = move_toward(velocity.x, max_speed * signed, base_deceleration * mul * delta)
	else:
		velocity.x = move_toward(velocity.x, max_speed * signed, base_acceleration * mul * delta)
	
	gun_direction = direction
	if gun_direction.x == 0 and gun_direction.y == 0:
		gun_direction.x = facing
	gun_direction.x *= -1 if gun_direction.y > 0 else 1
	gunPivot.rotation = lerp_angle(gunPivot.rotation, gun_direction.angle(), 0.2)
	var rotated: Vector2 = Vector2.RIGHT.rotated(gunPivot.rotation)
	gunPivot.scale.y = sign(rotated.x)
	
	if Input.is_action_just_pressed("shoot"):
		shotgun_propel(gun_direction)
	
	# attempt_correction(24)
	
	print("velocity: ", velocity)
	
	move_and_slide()
