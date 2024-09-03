@tool
extends Node2D
class_name BliggyGun

@onready var shooter: PatternShooter2D = $ShootPoint
@onready var spritePivot: Node2D = $SpritePivot
@onready var sprite: Sprite2D = $SpritePivot/Sprite2D
@onready var ammoLabel: Node2D = $AmmoCounter
@onready var ammoLabelText: RichTextLabel = $AmmoCounter/Ammo

@export_group("General")
## The pattern to use when the shoot button is pressed.
@export var pattern: Pattern2D
## The id of the gun, for use with the player script.
@export_range(0, 2048) var id: int
## The player using the gun. REQUIRED, otherwise it will not run.
@export var player: Bliggy
## Max ammo. 0 means no ammo.
@export_range(0, 999) var max_ammo: int = 0

var ammo: int = 0
var gunCooldown: float = 0
var ammoCooldown: float = 0
var playedReload: bool = false
var addoffset: Vector2

@export_group("Visual")
@export var texture: Texture2D:
	set(new_tex):
		if not Engine.is_editor_hint(): return
		sprite.texture = new_tex
		texture = new_tex

## The visual offset to apply on firing the gun.
@export_range(0, 32) var recoil_offset: int = 10
## The visual rotation to apply on firing the gun.
@export_range(0, 90) var recoil_rotation: int = 20
## The speed to reset the offset with.
@export_range(0.01, 32, 0.1) var offset_speed: float = 0.2
## The speed to reset the rotation with.
@export_range(0.01, 90, 0.1) var rotation_speed: float = 0.8

func sprite_changed():
	print("hi")
	sprite.texture = texture

func _ready():
	if Engine.is_editor_hint(): return
	assert(player, "A gun needs a designated player!")
	if not pattern:
		return
	shooter.pattern = pattern
	shooter.owner_bullet = player
	ammo = max_ammo
	
func shoot_gun(rotation: float):
	if Engine.is_editor_hint(): return
	if gunCooldown != 0: return
	if max_ammo > 0:
		ammo -= 1
		if ammo < 0: ammo = 0 
		ammoLabel.modulate.a = 1
		if ammo <= 0:
			ammoLabel.modulate.g = 0
			ammoLabel.modulate.b = 0
			return
	shooter.rotation = rotation
	shooter.fire_pattern()
	# This is generally redundant but who cares
	player.gun_fire(id)
	playedReload = false
	sprite.offset.x = -recoil_offset
	spritePivot.rotation_degrees = -recoil_rotation

var elapsed_time: float = 0.0

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	elapsed_time += delta
	ammoLabel.modulate.a = move_toward(ammoLabel.modulate.a, 0, 0.075)
	ammoLabel.modulate.g = move_toward(ammoLabel.modulate.g, 255, 0.075)
	ammoLabel.modulate.b = move_toward(ammoLabel.modulate.b, 255, 0.075)
	sprite.offset.x = move_toward(sprite.offset.x, 0, offset_speed) + addoffset.x
	sprite.offset.y = cos(elapsed_time*3) + addoffset.y
	spritePivot.rotation_degrees = move_toward(spritePivot.rotation_degrees, 0, rotation_speed)
	if max_ammo > 0:
		ammoLabelText.text = "[center]%03d[/center]" % ammo
	var rotated: Vector2 = Vector2.RIGHT.rotated(ammoLabel.rotation)
	if rotated.x < 0:
		ammoLabel.scale.y = -1
	else:
		ammoLabel.scale.y = 1
		
	if has_node("reload") and gunCooldown == 0 and not playedReload:
		playedReload = true
		get_node("reload").play()
		
	gunCooldown = max(0, gunCooldown - delta)
	ammoCooldown = max(0, ammoCooldown - delta)
	pass
