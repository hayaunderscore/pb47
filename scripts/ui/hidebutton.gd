extends Button

@export var container_to_move: Container
@export var move_vector: Vector2
var last_position: Vector2
var last_button_position: Vector2

@export var additional_elements: Array[Control]
var last_positions: Array[Vector2]

func _toggled(toggled_on: bool) -> void:
	SoundManager.play_sfx("res://sfx/new/ui/rctclick.wav")
	if toggled_on:
		var tween: Tween = get_tree().create_tween()
		last_position = container_to_move.position
		last_button_position = position
		var move: Vector2 = move_vector * container_to_move.size
		if move_vector.x != 0:
			tween.parallel().tween_property(container_to_move, "position:x", last_position.x + move.x, 0.25).set_trans(Tween.TRANS_QUAD)
			tween.parallel().tween_property(self, "position:x", move.x + last_button_position.x, 0.25).set_trans(Tween.TRANS_QUAD)
		if move_vector.y != 0:
			tween.parallel().tween_property(container_to_move, "position:y", last_position.y + move.y, 0.25).set_trans(Tween.TRANS_QUAD)
			tween.parallel().tween_property(self, "position:y", move.y + last_button_position.y, 0.25).set_trans(Tween.TRANS_QUAD)
		last_positions.clear()
		for i in range(0, additional_elements.size()):
			last_positions.push_back(additional_elements[i].position)
			if move_vector.x != 0:
				tween.parallel().tween_property(additional_elements[i], "position:x", move.x + last_positions[i].x, 0.25).set_trans(Tween.TRANS_QUAD)
			if move_vector.y != 0:
				tween.parallel().tween_property(additional_elements[i], "position:y", move.y + last_positions[i].y, 0.25).set_trans(Tween.TRANS_QUAD)
	else:
		var tween: Tween = get_tree().create_tween()
		if move_vector.x != 0:
			tween.parallel().tween_property(container_to_move, "position:x", last_position.x, 0.25).set_trans(Tween.TRANS_QUAD)
			tween.parallel().tween_property(self, "position:x", last_button_position.y, 0.25).set_trans(Tween.TRANS_QUAD)
		if move_vector.y != 0:
			tween.parallel().tween_property(container_to_move, "position:y", last_position.y, 0.25).set_trans(Tween.TRANS_QUAD)
			tween.parallel().tween_property(self, "position:y", last_button_position.y, 0.25).set_trans(Tween.TRANS_QUAD)
		for i in range(0, additional_elements.size()):
			if move_vector.x != 0:
				tween.parallel().tween_property(additional_elements[i], "position:x", last_positions[i].x, 0.25).set_trans(Tween.TRANS_QUAD)
			if move_vector.y != 0:
				tween.parallel().tween_property(additional_elements[i], "position:y", last_positions[i].y, 0.25).set_trans(Tween.TRANS_QUAD)
