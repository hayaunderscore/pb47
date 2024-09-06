extends Area2D

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent is not Bliggy: return
	parent.health_comp.health = 0
	parent.health_comp.dead = true
	if parent.hud:
		parent.hud.health_set(parent.health_comp.health)
	parent.death(self)
