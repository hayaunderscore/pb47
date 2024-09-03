extends Area2D

func _on_area_entered(area: Area2D) -> void:
	if area.get_parent() is not Bliggy: return
	var bliggy: Bliggy = area.get_parent()
	if bliggy.hud:
		bliggy.hud.timerActive = true
	$Sprite2D.frame = 1
	$CollisionShape2D.queue_free()
