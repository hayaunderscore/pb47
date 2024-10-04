extends Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_entered.connect(hover)
	mouse_exited.connect(unhover)

func hover():
	SoundManager.play_sfx("res://sfx/pb5_hover.wav", 0, -8)
	pass

func unhover():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var atlas: AtlasTexture = icon as AtlasTexture
	atlas.region.position.y = 48 if is_hovered() else 0
