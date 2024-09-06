extends Resource
class_name EditedLevel

## The current version of the level.
## Set on level save.
@export var version: int = 1
## The full absolute path to the music file.
@export var music: String = "res://mus/akrillic.ogg"
## The relative path to the music file, for use in the properties dialog.
@export var relative_music: String = "mus/akrillic.ogg"
## The background graphic to use.
@export var background: String = "gfx/bg/bg01.png"
## The scroll to use for the background.
@export var bg_scroll: Vector2 = Vector2(0, 50)
## The scroll scale to use for the background.
@export var bg_scale: Vector2 = Vector2(0.5, 0.5)
## The base tile graphic to use.
@export var fuckedtiles: String = "gfx/tiles/tiles_inside.png"

## Tile layers.
enum TileLayer {
	FOREGROUND,
	FORERERGROUND,
	FORERERERGROUND,
	BACKERGROUND,
	BACKGROUND
}

## Every single fucking tile
@export var tiles: Array[Dictionary] = [
	{}, {}, {}, {}, {}
]
## Too lazy
@export var tile_col: Array[bool] = [
	true, true, true, true
]

func get_tiles_from_layer(layer: int) -> Dictionary:
	return tiles[layer]
func set_tiles(layer: int, dict: Dictionary):
	tiles[layer] = dict
