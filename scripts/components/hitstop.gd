extends Node2D
class_name SakuraiComponent

@export var hitstop_time: float = 0.1
@onready var timer: Timer = $Timer

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	timer.timeout.connect(restore_process)
	
func restore_process():
	var parent = get_parent()
	parent.set_process(true)
	parent.set_physics_process(true)

func hit_stop():
	timer.wait_time = hitstop_time
	timer.start()
	var parent = get_parent()
	parent.set_process(false)
	parent.set_physics_process(false)
