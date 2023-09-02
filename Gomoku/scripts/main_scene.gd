extends Node2D

var N_HORZ = g.N_HORZ
var N_VERT = g.N_VERT
var N_CELLS = N_HORZ*N_VERT

var BOARD_ORG_X
var BOARD_ORG_Y
var BOARD_ORG

var bd
var rng = RandomNumberGenerator.new()
var AI_thinking = false
var waiting = 0;				# ウェイト中カウンタ
var game_started = true			# ゲーム中か？
var next_color = g.BLACK		# 次の手番
#var white_player = HUMAN
#var black_player = HUMAN
var pressedPos = Vector2(0, 0)
var put_pos = Vector2(-1, -1)
var prev_put_pos = Vector2(-1, -1)

func _ready():
	#rng.randomize()		# Setups a time-based seed
	rng.seed = 0		# 固定乱数系列
	BOARD_ORG_X = $Board/TileMap.global_position.x
	BOARD_ORG_Y = $Board/TileMap.global_position.y
	BOARD_ORG = Vector2(BOARD_ORG_X, BOARD_ORG_Y)
	bd = g.Board.new()
	#bd.put_color(5, 5, g.BLACK)
	#bd.put_color(6, 5, g.WHITE)
	update_view()
	pass # Replace with function body.

func update_view():
	update_next_underline()
	for y in range(N_VERT):
		for x in range(N_HORZ):
			var c:int = bd.get_color(x, y)
			$Board/TileMap.set_cell(0, Vector2(x, y), c-1, Vector2i(0, 0))
	if prev_put_pos.x >= 0:
		$Board/BGTileMap.set_cell(0, prev_put_pos, -1, Vector2i(0, 0))
	if put_pos.x >= 0:
		$Board/BGTileMap.set_cell(0, put_pos, 2, Vector2i(0, 0))
		print("put_pos = ", put_pos)
	pass
func update_next_underline():
	$WhitePlayer/Underline.visible = game_started && next_color == g.WHITE
	$BlackPlayer/Underline.visible = game_started && next_color == g.BLACK
func _process(delta):
	pass
func _input(event):
	if !game_started: return
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT:
		#print(event.position)
		#print($Board/TileMapLocal.local_to_map(event.position - BOARD_ORG))
		var pos = $Board/TileMap.local_to_map(event.position - BOARD_ORG)
		#print(pos)
		#print("mouse button")
		if event.is_pressed():
			#print("pressed")
			pressedPos = pos
		elif pos == pressedPos:
			#print("released")
			#if n_put == 0:
			#	game_started = true
			#	return
			if pos.x < 0 || pos.x >= N_HORZ || pos.y < 0 || pos.y > N_VERT: return
			if !bd.is_empty(pos.x, pos.y): return
			#print(pos)
			bd.put_color(pos.x, pos.y, next_color)
			next_color = (g.BLACK + g.WHITE) - next_color
			prev_put_pos = put_pos
			put_pos = pos
			update_view()
	pass
