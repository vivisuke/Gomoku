extends Node2D

enum {
	HUMAN = 0, AI_RANDOM, AI_DEPTH_1, AI_DEPTH_2, AI_DEPTH_3, 
}
const BGID = 2
const CELL_WD = 42

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
var put_pos = Vector2i(-10, -10)	# -10 for 画面外
#var prev_put_pos = Vector2(-1, -1)
var move_hist = []				# 着手履歴
var move_ix = -1				# 着手済みIX
var eval_labels = []

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
	init_labels()
	unit_test()
	pass # Replace with function body.

func init_labels():
	for y in range(N_VERT):
		for x in range(N_HORZ):
			var lbl = Label.new()
			lbl.text = ""
			#lbl.text = "%d" % (x+y)
			lbl.position = Vector2(x*CELL_WD, y*CELL_WD+10)
			lbl.size.x = CELL_WD-10
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			lbl.modulate = Color(1, 0, 0) # 赤色
			$Board.add_child(lbl)
			eval_labels.push_back(lbl)
func update_view():
	for y in range(N_VERT):
		for x in range(N_HORZ):
			var c:int = bd.get_color(x, y)
			$Board/TileMap.set_cell(0, Vector2(x, y), c-1, Vector2i(0, 0))
	if bd.n_space == 0:
		on_gameover(g.EMPTY)
		return
	update_next_underline()
	# prev_put_pos の強調を消し、put_pos を強調
	#if prev_put_pos.x >= 0:
	#	#$Board/BGTileMap.set_cell(0, prev_put_pos, -1, Vector2i(0, 0))
	if put_pos.x >= 0:
		#$Board/BGTileMap.set_cell(0, put_pos, BGID, Vector2i(0, 0))
		$Board/PutCursor.position = put_pos*CELL_WD
		print("put_pos = ", put_pos)
	else:
		$Board/PutCursor.position = Vector2(-10, -10)*CELL_WD
	#
	if won_color != g.EMPTY:
		$MessLabel.text = ("BLACK" if won_color == g.BLACK else "WHITE") + " won"
	elif bd.n_space == 0:
		$MessLabel.text = "draw"
	elif !game_started:
		$MessLabel.text = "push [Start Game]"
	else:
		print_next_turn()
	$HBC/FirstButton.disabled = move_ix < 0 || game_started
	$HBC/BackButton.disabled = move_ix < 0 || game_started
	$HBC/ForwardButton.disabled = move_hist.size() - 1 <= move_ix || game_started
	$HBC/LastButton.disabled = move_hist.size() - 1 <= move_ix || game_started
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
	if !bd.is_legal_put(x, y, next_color):
		bd.remove_color(x, y)
		return
	var sx = bd.is_six(x, y, next_color)
	print("is_six = ", sx)
	if next_color == g.BLACK && sx:
		# undone: beep ?
		bd.remove_color(x, y)
		$MessLabel.text = "overlines are prohibited"
		return
	var pos = Vector2i(x, y)
	move_ix = move_hist.size()
	move_hist.push_back(pos)
	$HBC/UndoButton.disabled = false
	var fv = bd.is_five(x, y, next_color)
	print("is_five = ", fv)
	#prev_put_pos = put_pos
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
	# テスト：is_five()
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
	# テスト：is_six(x, y, col) 
	b2.clear()
	b2.put_color(0, 0, g.BLACK)
	b2.put_color(1, 0, g.BLACK)
	b2.put_color(2, 0, g.BLACK)
	b2.put_color(3, 0, g.BLACK)
	b2.put_color(4, 0, g.BLACK)
	b2.put_color(5, 0, g.BLACK)
	assert( b2.is_six(3, 0, g.BLACK) )
	b2.remove_color(2, 0)
	b2.put_color(2, 0, g.WHITE)
	assert( !b2.is_six(3, 0, g.BLACK) )
	# テスト：is_four(x, y, col) 
	b2.clear()
	b2.put_color(0, 0, g.BLACK)
	b2.put_color(1, 0, g.BLACK)
	b2.put_color(2, 0, g.BLACK)
	assert( !b2.is_four(2, 0, g.BLACK) )	# 三の場合
	b2.put_color(3, 0, g.BLACK)
	assert( b2.is_four(3, 0, g.BLACK) )		# （連続）四の場合
	b2.put_color(4, 0, g.WHITE)
	assert( !b2.is_four(4, 0, g.BLACK) )	# 四が止められているの場合
	b2.remove_color(3, 0)
	b2.remove_color(4, 0)
	b2.put_color(4, 0, g.BLACK)
	assert( b2.is_four(4, 0, g.BLACK) )		# 飛び四 の場合
	b2.clear()
	b2.put_color(0, 0, g.BLACK)
	b2.put_color(1, 1, g.BLACK)
	b2.put_color(2, 2, g.BLACK)
	assert( !b2.is_four(2, 2, g.BLACK) )	# 三の場合
	b2.put_color(3, 3, g.BLACK)
	assert( b2.is_four(3, 3, g.BLACK) )		# （連続）四の場合
	b2.remove_color(3, 3)
	b2.put_color(4, 4, g.BLACK)
	assert( b2.is_four(4, 4, g.BLACK) )		# 飛び四 の場合
	b2.clear()
	b2.put_color(0, 0, g.WHITE)
	b2.put_color(1, 1, g.BLACK)
	b2.put_color(2, 2, g.BLACK)
	b2.put_color(3, 3, g.BLACK)
	b2.put_color(4, 4, g.BLACK)
	assert( b2.is_four(1, 1, g.BLACK) )		# （連続）四の場合
	assert( b2.is_four(2, 2, g.BLACK) )		# （連続）四の場合
	assert( b2.is_four(3, 3, g.BLACK) )		# （連続）四の場合
	assert( b2.is_four(4, 4, g.BLACK) )		# （連続）四の場合
	b2.put_color(1, 7, g.BLACK)				# ｜・●●●●｜
	b2.put_color(2, 8, g.BLACK)
	b2.put_color(3, 9, g.BLACK)
	b2.put_color(4, 10, g.BLACK)
	assert( b2.is_four(1, 7, g.BLACK) )		# （連続）四の場合
	assert( b2.is_four(2, 8, g.BLACK) )		# （連続）四の場合
	assert( b2.is_four(3, 9, g.BLACK) )		# （連続）四の場合
	assert( b2.is_four(4, 10, g.BLACK) )		# （連続）四の場合
	b2.put_color(0, 6, g.WHITE)					# ｜◯●●●●｜
	assert( !b2.is_four(1, 7, g.BLACK) )		# 四が止められているの場合
	assert( !b2.is_four(2, 8, g.BLACK) )		# 四が止められているの場合
	assert( !b2.is_four(3, 9, g.BLACK) )		# 四が止められているの場合
	assert( !b2.is_four(4, 10, g.BLACK) )		# 四が止められているの場合
	b2.put_color(0, 5, g.WHITE)					# ｜◯●●●●・｜
	b2.put_color(1, 6, g.BLACK)
	b2.put_color(2, 7, g.BLACK)
	b2.put_color(3, 8, g.BLACK)
	b2.put_color(4, 9, g.BLACK)
	assert( b2.is_four(1, 6, g.BLACK) )		# （連続）四の場合
	assert( b2.is_four(2, 7, g.BLACK) )		# （連続）四の場合
	assert( b2.is_four(3, 8, g.BLACK) )		# （連続）四の場合
	assert( b2.is_four(4, 9, g.BLACK) )		# （連続）四の場合
	# テスト：is_three(x, y, col) 
	b2.clear()
	b2.put_color(1, 0, g.BLACK)
	b2.put_color(2, 0, g.BLACK)
	b2.put_color(3, 0, g.BLACK)				# ｜・●●●・・…｜
	assert( b2.is_three(1, 0, g.BLACK) )	# 三の場合
	assert( b2.is_three(2, 0, g.BLACK) )	# 三の場合
	assert( b2.is_three(3, 0, g.BLACK) )	# 三の場合
	b2.put_color(5, 0, g.WHITE)				# ｜・●●●・◯…｜
	assert( !b2.is_three(1, 0, g.BLACK) )	# 非活三の場合
	assert( !b2.is_three(2, 0, g.BLACK) )	# 非活三の場合
	assert( !b2.is_three(3, 0, g.BLACK) )	# 非活三の場合
	b2.remove_color(3, 0)
	b2.remove_color(5, 0)
	b2.put_color(4, 0, g.BLACK)				# ｜・●●・●・…｜
	assert( b2.is_three(1, 0, g.BLACK) )	# 飛び三の場合
	assert( b2.is_three(2, 0, g.BLACK) )	# 飛び三の場合
	assert( b2.is_three(4, 0, g.BLACK) )	# 飛び三の場合
	b2.put_color(0, 0, g.WHITE)				# ｜◯●●・●・…｜
	assert( !b2.is_three(1, 0, g.BLACK) )	# 飛び三の場合
	assert( !b2.is_three(2, 0, g.BLACK) )	# 飛び三の場合
	assert( !b2.is_three(4, 0, g.BLACK) )	# 飛び三の場合
	# 問題：｜・●●●◯ が高評価されてしまう？
	b2.clear()
	b2.put_color(2, 0, g.BLACK)
	b2.put_color(3, 1, g.BLACK)
	b2.put_color(4, 2, g.BLACK)
	b2.put_color(5, 3, g.BLACK)
	b2.put_color(6, 4, g.WHITE)
	b2.calc_eval(g.WHITE)
	print("calc_eval(): ", b2.eval)
	#var t = b2.eval_bitmap(b2.d_black[8], b2.d_white[8], 9, g.WHITE)
	#print("eval_bitmap(): ", t)
	#
	b2.clear()
	b2.calc_eval(g.BLACK)
	assert(b2.eval == 0)
	b2.put_color(0, 0, g.BLACK)
	assert(b2.d_black[6] == 0b10000000000)
	b2.calc_eval(g.WHITE)
	print(b2.eval)
	assert(b2.eval == 3)
	# 合法手チェック
	b2.clear()
	b2.put_color(1, 0, g.BLACK)
	b2.put_color(2, 0, g.BLACK)
	b2.put_color(3, 0, g.BLACK)
	b2.put_color(4, 0, g.BLACK)
	b2.put_color(5, 0, g.BLACK)
	b2.put_color(6, 0, g.BLACK)				# ｜・●●●●●●・…｜
	assert( !b2.is_legal_put(1, 0, g.BLACK) )
	assert( !b2.is_legal_put(2, 0, g.BLACK) )
	assert( !b2.is_legal_put(3, 0, g.BLACK) )
	assert( !b2.is_legal_put(4, 0, g.BLACK) )
	assert( !b2.is_legal_put(5, 0, g.BLACK) )
	assert( !b2.is_legal_put(6, 0, g.BLACK) )
	b2.clear()
	b2.put_color(0, 4, g.WHITE)
	b2.put_color(1, 4, g.BLACK)
	b2.put_color(2, 4, g.BLACK)
	b2.put_color(3, 4, g.BLACK)
	b2.put_color(4, 3, g.BLACK)
	b2.put_color(4, 5, g.BLACK)
	b2.put_color(4, 4, g.BLACK)		
	assert( b2.is_legal_put(4, 4, g.BLACK) )	# 四三
	b2.put_color(4, 6, g.BLACK)
	assert( !b2.is_legal_put(4, 4, g.BLACK) )	# 四四
	b2.clear()
	b2.put_color(3, 4, g.BLACK)
	b2.put_color(5, 4, g.BLACK)
	b2.put_color(4, 3, g.BLACK)
	b2.put_color(4, 5, g.BLACK)
	b2.put_color(4, 4, g.BLACK)		
	assert( !b2.is_legal_put(4, 4, g.BLACK) )	# 三三
	b2.put_color(2, 4, g.WHITE)
	assert( b2.is_legal_put(4, 4, g.BLACK) )	# 横方向が 非活三
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
	#


func _on_init_button_pressed():
	if game_started: return
	bd.clear()
	next_color = g.BLACK
	won_color = g.EMPTY
	move_hist.clear()
	move_ix = -1
	$HBC/UndoButton.disabled = true
	put_pos = Vector2i(-10, -10)
	#if put_pos != Vector2i(-1, -1):
	#	#$Board/BGTileMap.set_cell(0, put_pos, -1, Vector2i(0, 0))
	#	put_pos = Vector2i(-10, -10)
	for i in range(eval_labels.size()): eval_labels[i].text = ""
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
	update_view()
	#update_next_underline()


func _on_undo_button_pressed():
	if move_hist.size() < 2: return
	#$Board/BGTileMap.set_cell(0, put_pos, -1, Vector2i(0, 0))
	var p = move_hist.pop_back()
	bd.remove_color(p.x, p.y)
	#bd.eval_putxy(p.x, p.y)
	p = move_hist.pop_back()
	bd.remove_color(p.x, p.y)
	move_ix -= 2
	#bd.eval_putxy(p.x, p.y)
	$HBC/UndoButton.disabled = move_hist.is_empty()
	if !move_hist.is_empty():
		put_pos = move_hist.back()
		#$Board/BGTileMap.set_cell(0, put_pos, BGID, Vector2i(0, 0))	# 直前着手強調
	else:
		put_pos = Vector2i(-10, -10)

	update_view()
	pass # Replace with function body.


func _on_black_player_selected(index):
	black_player = index
	pass # Replace with function body.


func _on_white_player_selected(index):
	white_player = index
	pass # Replace with function body.

func print_eval():
	var ix = 0
	for y in range(N_VERT):
		for x in range(N_HORZ):
			if bd.is_empty(x, y):
				bd.put_color(x, y, next_color)
				bd.calc_eval(next_color)
				eval_labels[ix].text = "%d" % bd.eval
				bd.remove_color(x, y)
			else:
				eval_labels[ix].text = ""
			ix += 1
func _on_rule_button_pressed():
	print_eval()
	#bd.print_eval_ndiff(next_color)
	pass # Replace with function body.


func _on_back_button_pressed():
	if move_ix >= 0:
		var p = move_hist[move_ix]
		move_ix -= 1
		bd.remove_color(p.x, p.y)
		#prev_put_pos = p
		#$Board/BGTileMap.set_cell(0, p, -1, Vector2i(0, 0))
		#prev_put_pos = Vector2i(-1, -1)
		if move_ix >= 0:
			put_pos = move_hist[move_ix]
			#var prev = move_hist[move_ix]
			#$Board/BGTileMap.set_cell(0, prev, BGID, Vector2i(0, 0))
		else:
			put_pos = Vector2i(-10, -10)
		next_color = (g.BLACK + g.WHITE) - next_color
		update_view()
func _on_forward_button_pressed():
	if move_ix + 1 < move_hist.size():
		#if move_ix >= 0:
		#	var prev = move_hist[move_ix]
		#	#$Board/BGTileMap.set_cell(0, prev, -1, Vector2i(0, 0))
		move_ix += 1
		put_pos = move_hist[move_ix]
		bd.put_color(put_pos.x, put_pos.y, next_color)
		#$Board/BGTileMap.set_cell(0, p, BGID, Vector2i(0, 0))
		next_color = (g.BLACK + g.WHITE) - next_color
		update_view()
	pass # Replace with function body.
func _on_first_button_pressed():
	while move_ix >= 0:
		var p = move_hist[move_ix]
		move_ix -= 1
		bd.remove_color(p.x, p.y)
	next_color = g.BLACK
	put_pos = Vector2i(-10, -10)
	update_view()
func _on_last_button_pressed():
	while move_ix + 1 < move_hist.size():
		move_ix += 1
		put_pos = move_hist[move_ix]
		bd.put_color(put_pos.x, put_pos.y, next_color)
		next_color = (g.BLACK + g.WHITE) - next_color
	update_view()
