extends Node2D

enum {
	HUMAN = 0, AI_RANDOM, AI_DEPTH_1, AI_DEPTH_2, AI_DEPTH_3, 
}
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
var game_over = false			# 勝敗がついたか？
var won_color = g.EMPTY			# 勝者
var next_color = g.BLACK		# 次の手番
var white_player = HUMAN
var black_player = HUMAN
var pressedPos = Vector2i(0, 0)
var put_pos = Vector2i(-1, -1)
var prev_put_pos = Vector2(-1, -1)
var move_hist = []				# 着手履歴

func _ready():
	#rng.randomize()		# Setups a time-based seed
	rng.seed = 0		# 固定乱数系列
	BOARD_ORG_X = $Board/TileMap.global_position.x
	BOARD_ORG_Y = $Board/TileMap.global_position.y
	BOARD_ORG = Vector2(BOARD_ORG_X, BOARD_ORG_Y)
	bd = g.Board.new()
	#bd.put_color(5, 5, g.BLACK)
	#bd.put_color(6, 5, g.WHITE)
	$HBC/UndoButton.disabled = true
	update_view()
	unit_test()
	pass # Replace with function body.

func update_view():
	for y in range(N_VERT):
		for x in range(N_HORZ):
			var c:int = bd.get_color(x, y)
			$Board/TileMap.set_cell(0, Vector2(x, y), c-1, Vector2i(0, 0))
	if bd.n_space == 0:
		on_gameover(g.EMPTY)
		return
	update_next_underline()
	if prev_put_pos.x >= 0:
		$Board/BGTileMap.set_cell(0, prev_put_pos, -1, Vector2i(0, 0))
	if put_pos.x >= 0:
		$Board/BGTileMap.set_cell(0, put_pos, 2, Vector2i(0, 0))
		print("put_pos = ", put_pos)
	if won_color != g.EMPTY:
		$MessLabel.text = ("BLACK" if won_color == g.BLACK else "WHITE") + " won"
	elif bd.n_space == 0:
		$MessLabel.text = "draw"
	elif !game_started:
		$MessLabel.text = "push [Start Game]"
	else:
		print_next_turn()
	pass
func print_next_turn():
	if next_color == g.BLACK:
		$MessLabel.text = "BLACK's turn"
	else:
		$MessLabel.text = "WHITE's turn"
func update_next_underline():
	$WhitePlayer/Underline.visible = game_started && next_color == g.WHITE
	$BlackPlayer/Underline.visible = game_started && next_color == g.BLACK
func _process(delta):
	if( game_started && !AI_thinking &&
			(next_color == g.WHITE && white_player >= AI_RANDOM ||
			next_color == g.BLACK && black_player >= AI_RANDOM) ):
		# AI の手番
		AI_thinking = true
		var op = bd.put_minmax(next_color)
		do_put(op.x, op.y)
		AI_thinking = false
	pass
func _input(event):
	if !game_started: return
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT:
		#print(event.position)
		#print($Board/TileMapLocal.local_to_map(event.position - BOARD_ORG))
		var pos: Vector2i = $Board/TileMap.local_to_map(event.position - BOARD_ORG)
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
			do_put(pos.x, pos.y)
			#bd.print_eval_ndiff(next_color)
	pass
func do_put(x, y):
	bd.put_color(x, y, next_color)
	var sx = bd.is_six(x, y, next_color)
	print("is_six = ", sx)
	if next_color == g.BLACK && sx:
		# undone: beep ?
		bd.remove_color(x, y)
		$MessLabel.text = "overlines are prohibited"
		return
	var pos = Vector2i(x, y)
	move_hist.push_back(pos)
	$HBC/UndoButton.disabled = false
	var fv = bd.is_five(x, y, next_color)
	print("is_five = ", fv)
	prev_put_pos = put_pos
	put_pos = pos
	if fv: on_gameover(next_color)
	next_color = (g.BLACK + g.WHITE) - next_color
	update_view()
	#bd.print_eval(next_color)
func on_gameover(wcol):
	game_started = false
	game_over = true
	$StartStopButton.set_pressed_no_signal(false)
	$StartStopButton.text = "Start Game"
	$StartStopButton.icon = $StartStopButton/PlayTexture.texture
	#var c = "BLACK" if next_color == g.WHITE else "WHITE"
	#$MessLabel.text = c + " won."
	#won_color = g.BLACK if next_color == g.WHITE else g.WHITE
	won_color = wcol
	$BlackPlayer/OptionButton.disabled = false
	$WhitePlayer/OptionButton.disabled = false
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
	assert(b2.u_black[6] == 0x001)
	b2.put_color(9, 1, g.BLACK)
	b2.put_color(8, 2, g.BLACK)
	b2.put_color(7, 3, g.BLACK)
	b2.put_color(6, 4, g.BLACK)
	print("u_black[5] = %03x" % b2.u_black[5])
	assert(b2.is_five(6, 4, g.BLACK))
	#
	b2.clear()
	b2.calc_eval(g.BLACK)
	assert(b2.eval == 0)
	b2.put_color(0, 0, g.BLACK)
	assert(b2.d_black[6] == 0b10000000000)
	b2.calc_eval(g.WHITE)
	print(b2.eval)
	assert(b2.eval == 3)
	#
	b2.clear()
	assert(b2.eval == 0)
	b2.print_eval_ndiff(g.BLACK)
	print("eval = ", b2.eval)
	b2.put_color(4, 4, g.BLACK)
	print("eval = ", b2.eval)
	b2.put_color(5, 5, g.WHITE)
	b2.put_color(5, 4, g.BLACK)
	b2.put_color(6, 4, g.WHITE)
	b2.put_color(4, 5, g.BLACK)
	b2.put_color(4, 6, g.WHITE)
	b2.print_eval_ndiff(g.BLACK)
	print("eval = ", b2.eval)


func _on_init_button_pressed():
	if game_started: return
	bd.clear()
	next_color = g.BLACK
	won_color = g.EMPTY
	move_hist.clear()
	$HBC/UndoButton.disabled = true
	if put_pos != Vector2i(-1, -1):
		$Board/BGTileMap.set_cell(0, put_pos, -1, Vector2i(0, 0))
		put_pos = Vector2i(-1, -1)
	update_view()
func _on_start_stop_button_toggled(button_pressed):
	game_started = button_pressed
	if game_started:
		#next_color = g.BLACK
		print_next_turn()
		$StartStopButton.text = "Stop Game"
		$StartStopButton.icon = $StartStopButton/StopTexture.texture
		$BlackPlayer/OptionButton.disabled = true
		$WhitePlayer/OptionButton.disabled = true
	else:
		$StartStopButton.text = "Start Game"
		$StartStopButton.icon = $StartStopButton/PlayTexture.texture
		$BlackPlayer/OptionButton.disabled = false
		$WhitePlayer/OptionButton.disabled = false
	update_next_underline()


func _on_undo_button_pressed():
	if move_hist.size() < 2: return
	$Board/BGTileMap.set_cell(0, put_pos, -1, Vector2i(0, 0))
	var p = move_hist.pop_back()
	bd.remove_color(p.x, p.y)
	#bd.eval_putxy(p.x, p.y)
	p = move_hist.pop_back()
	bd.remove_color(p.x, p.y)
	#bd.eval_putxy(p.x, p.y)
	$HBC/UndoButton.disabled = move_hist.is_empty()
	if !move_hist.is_empty():
		put_pos = move_hist.back()
		$Board/BGTileMap.set_cell(0, put_pos, 2, Vector2i(0, 0))
	else:
		put_pos = Vector2i(-1, -1)

	update_view()
	pass # Replace with function body.


func _on_black_player_selected(index):
	black_player = index
	pass # Replace with function body.


func _on_white_player_selected(index):
	white_player = index
	pass # Replace with function body.


func _on_rule_button_pressed():
	bd.print_eval_ndiff(next_color)
	pass # Replace with function body.
