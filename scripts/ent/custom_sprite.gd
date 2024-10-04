extends Sprite2D

var sprite_: String
var last_path: String

func _ready():
	var path: String = sprite_
	if path.is_empty(): return
	# 3 is the source id for the most commonly used tileset
	# which is also used in the level editor!
	if FileAccess.file_exists("res://" + path):
		texture = load("res://" + path)
		return
	if last_path.is_empty(): return
	if not FileAccess.file_exists(last_path + path): return
	var full_path: String = last_path + path
	var spr: Image = Image.load_from_file(full_path)
	if spr == null: return
	texture = ImageTexture.create_from_image(spr)
	print("found sprite!")
