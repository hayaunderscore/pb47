extends CanvasLayer
class_name HeadsUpDisplay

@onready var health: Sprite2D = $Health
@onready var deadHeart: Sprite2D = $DeadHeart
@onready var numbers: Array[Sprite2D] = [$"Numbers/0", $"Numbers/1", $"Numbers/2"]
var shake: float = 0
var shakeDecayMultiplier: float = 0
var timerActive: bool = false

func _ready() -> void:
	deadHeart.visible = false

func health_set(heal: int):
	heal = max(0, heal)
	# Yeah this is easier
	health.region_rect.position.x = (4 - heal) * 107
	deadHeart.global_position.x = 35 + 24 * heal
	deadHeart.global_position.y = 37 - 2 * heal
	var spawn = Globals.spawn_spinny(deadHeart, $Pivot, deadHeart, self)
	spawn.global_position = deadHeart.global_position
	spawn.velocity.y = -8
	spawn.velocity.x = 10
	spawn.rotspeed = 10
	spawn.modulate.a = 0.5
	shake = 2 * (4 - heal)
	shakeDecayMultiplier = (4 - heal)
	
func set_ammo(ammo: int):
	$Ammo.animation = "Full" if ammo > 0 else "None"
	$Label.text = "%03d" % ammo if ammo >= 0 else "---"

static func get_time_as_formatted_string(time_in_seconds: float, format: String) -> String:
	var formatted_time: String = ""
	
	var total_seconds = int(time_in_seconds)
	
	@warning_ignore("integer_division")
	var hours : int = total_seconds / 3600
	
	@warning_ignore("integer_division")
	var minutes : int = (total_seconds % 3600) / 60
	
	@warning_ignore("integer_division")
	var seconds : int = total_seconds % 60
	
	@warning_ignore("integer_division")
	var days : int = total_seconds / 86400
	
	var fractional_part := time_in_seconds - int(time_in_seconds)
	
	var milliseconds := int(fractional_part * 1000)
	
	var i : int = 0
	while i < format.length():
		if format[i] == "{":
			var idx : int = format.find("}",i)
			
			if idx == -1:
				break
			
			match format[i+1]:
				"d":
					formatted_time += str(days).pad_zeros(idx-i-1)
				"h":
					formatted_time += str(hours).pad_zeros(idx-i-1)
				"m":
					formatted_time += str(int(fractional_part * pow(10,idx-i-1))).pad_zeros(idx-i-1)
				"M":
					formatted_time += str(minutes).pad_zeros(idx-i-1)
				"s":
					formatted_time += str(seconds).pad_zeros(idx-i-1)
					
			i = idx + 1
		else:
			formatted_time += format[i]
			i += 1
			
	return formatted_time

var time: float = 0.0

func _process(delta: float) -> void:
	shake = max(0, shake - 0.1 * shakeDecayMultiplier)
	health.offset.x = randf_range(-2, 2)*shake
	health.offset.y = randf_range(-2, 2)*shake
	if timerActive and not get_tree().paused:
		time += delta
	$SpeedrunTime.text = "[right]" + str(get_time_as_formatted_string(time, "{MM}:{ss}.{mm}")) + "[/right]"
