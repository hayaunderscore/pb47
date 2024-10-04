@tool
extends Node2D

const GRID_STEP = 32
const GRID_SIZE = 24

func _draw():
	if modulate.a == 0: return
	for i in range(GRID_SIZE):
		var col = Color("#ffffff20")
		var width = 1.0
		draw_line(Vector2(i * GRID_STEP, 0), Vector2(i * GRID_STEP, GRID_SIZE * GRID_STEP), col, width)
	
	for j in range(GRID_SIZE):
		var col = Color("#ffffff20")
		var width = 1.0
		draw_line(Vector2(0, j * GRID_STEP), Vector2(GRID_SIZE * GRID_STEP, j * GRID_STEP), col, width)
