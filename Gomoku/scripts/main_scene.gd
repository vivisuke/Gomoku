extends Node2D

var N_HORZ = g.N_HORZ
var N_VERT = g.N_VERT
var N_CELLS = N_HORZ*N_VERT

var bd

func _ready():
	bd = g.Board.new()
	update_board()
	pass # Replace with function body.

func update_board():
	for y in range(N_VERT):
		for x in range(N_HORZ):
			var c:int = bd.get_color(x, y)
			$Board/TileMap.set_cell(0, Vector2(x, y), c-1, Vector2i(0, 0))
	pass
func _process(delta):
	pass
