@tool
extends EditorInspectorPlugin

signal pattern_selected(pattern: Pattern2D)


func _can_handle(object):
	if object is Pattern2D:
		emit_signal("pattern_selected", object)
		return true
	return false
