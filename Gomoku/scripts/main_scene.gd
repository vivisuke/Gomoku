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
var game_started = false		# ゲーム中か？
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
	unit_test()
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
			var fv = bd.is_five(pos.x, pos.y, next_color)
			print("is_five = ", fv)
			next_color = (g.BLACK + g.WHITE) - next_color
			prev_put_pos = put_pos
			put_pos = pos
			if fv: on_gameover()
			update_view()
	pass
func on_gameover():
	game_started = false
	$StartStopButton.set_pressed_no_signal(false)
	$StartStopButton.text = "Start Game"
	$StartStopButton.icon = $StartStopButton/PlayTexture.texture
	var c = "BLACK" if next_color == g.WHITE else "WHITE"
	$MessLabel.text = c + " won."
func unit_test():
	var b2 = g.Board.new()
	b2.put_color(0, 0, g.BLACK)
	b2.put_color(1, 0, g.BLACK)
	b2.put_color(2, 0, g.BLACK)
	b2.put_color(3, 0, g.BLACK)
	b2.put_color(4, 0, g.BLACK)
	print("h_black[0] = %03x" % b2.h_black[0])
	print("five" if b2.is_five(4, 0, g.BLACK) else "NOT five")
	assert(b2.is_five(4, 0, g.BLACK))
	b2.clear()
	b2.put_color(0, 0, g.BLACK)
	b2.put_color(1, 1, g.BLACK)
	b2.put_color(2, 2, g.BLACK)
	b2.put_color(3, 3, g.BLACK)
	b2.put_color(4, 4, g.BLACK)
	assert(b2.is_five(4, 4, g.BLACK))
	b2.clear()
	b2.put_color(10, 0, g.BLACK)
	assert(b2.u_black[5] == 0x001)
	b2.put_color(9, 1, g.BLACK)
	b2.put_color(8, 2, g.BLACK)
	b2.put_color(7, 3, g.BLACK)
	b2.put_color(6, 4, g.BLACK)
	print("u_black[5] = %03x" % b2.u_black[5])
	assert(b2.is_five(6, 4, g.BLACK))


func _on_init_button_pressed():
	if game_started: return
	bd.clear()
	put_pos = Vector2(-1, -1)
	update_view()
func _on_start_stop_button_toggled(button_pressed):
	game_started = button_pressed
	if game_started:
		next_color = g.BLACK
		$StartStopButton.text = "Stop Game"
		$StartStopButton.icon = $StartStopButton/StopTexture.texture
	else:
		$StartStopButton.text = "Start Game"
		$StartStopButton.icon = $StartStopButton/PlayTexture.texture
	update_next_underline()
