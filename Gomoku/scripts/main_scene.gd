extends Node2D

enum {
	HUMAN = 0, AI_DEPTH_0, AI_DEPTH_1, AI_DEPTH_2, AI_DEPTH_3, 
}
const ID_GRAY = 0
const ID_BG = 2
const CELL_WD = 42

var N_HORZ = g.N_HORZ
var N_VERT = g.N_VERT
var N_CELLS = N_HORZ*N_VERT
const N_DIAGONAL = 6 + 1 + 6		# 斜め方向ビットマップ配列数

var BOARD_ORG_X
var BOARD_ORG_Y
var BOARD_ORG

var bd
var rng = RandomNumberGenerator.new()
var AI_thinking = false
var search_depth = 0
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
var put_order = []				# 着手順序配列、要素：[eval, x, y]
var put_order_ix = -1
var calc_eval_pos = -1			# if >= 0: 空欄評価値計算中
var alpha
var beta
var best_pos

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
	$Board/SearchCursor.position = Vector2(-10, -10)*CELL_WD
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
			lbl.modulate = Color.RED		#(1, 0, 0) # 赤色
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
		#$Board/BGTileMap.set_cell(0, put_pos, ID_BG, Vector2i(0, 0))
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
	for y in range(N_VERT):
		for x in range(N_HORZ):
			var id = -1
			if next_color == g.BLACK && black_player == HUMAN && bd.is_empty(x, y):
				bd.put_color(x, y, g.BLACK)
				if !bd.is_legal_put(x, y, g.BLACK):
					id = ID_GRAY
				bd.remove_color(x, y)
			$Board/BGTileMap.set_cell(0, Vector2i(x, y), id, Vector2i(0, 0))
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
			(next_color == g.WHITE && white_player >= AI_DEPTH_0 ||
			next_color == g.BLACK && black_player >= AI_DEPTH_0) ):
		# AI の手番
		AI_thinking = true
		#var op = bd.put_minmax(next_color)
		#search_depth = (black_player if next_color == g.BLACK else white_player) - AI_DEPTH_0
		bd.build_put_order(next_color)
		alpha = g.ALPHA
		beta = g.BETA
		var x = bd.put_order[bd.put_order_ix][1]
		var y = bd.put_order[bd.put_order_ix][2]
		$Board/SearchCursor.position = Vector2(x, y) * CELL_WD
		#var depth = (black_player if next_color == g.BLACK else white_player) - AI_DEPTH_0
		#var op = bd.do_alpha_beta_search(next_color, depth)
		#do_put(op.x, op.y)
		#AI_thinking = false
	if bd.put_order_ix >= 0 && bd.put_order_ix < bd.put_order.size():
		var x = bd.put_order[bd.put_order_ix][1]
		var y = bd.put_order[bd.put_order_ix][2]
		bd.put_color(x, y, next_color)
		#bd.calc_eval(next_color)
		var oppo = (g.BLACK + g.WHITE) - next_color
		var depth = (black_player if next_color == g.BLACK else white_player) - AI_DEPTH_0
		var ev = bd.alpha_beta(oppo, alpha, beta, depth - 1)
		bd.remove_color(x, y)
		if next_color == g.BLACK:
			if bd.eval > alpha:
				alpha = bd.eval
				best_pos = [x, y]
		else:
			if bd.eval < beta:
				beta = bd.eval
				best_pos = [x, y]
		bd.put_order_ix += 1
		if bd.put_order_ix < bd.put_order.size():
			x = bd.put_order[bd.put_order_ix][1]
			y = bd.put_order[bd.put_order_ix][2]
			$Board/SearchCursor.position = Vector2(x, y) * CELL_WD
		else:
			print("best_pos = ", best_pos)
			do_put(best_pos[0], best_pos[1])
			bd.put_order_ix = -1
			AI_thinking = false
			$Board/SearchCursor.position = Vector2(-10, -10)*CELL_WD
	if calc_eval_pos >= 0:
		var x = bd.prio_pos[calc_eval_pos][0]
		var y = bd.prio_pos[calc_eval_pos][1]
		var ix = y * N_HORZ + x
		if bd.is_empty(x, y):
			bd.put_color(x, y, next_color)
			if bd.is_legal_put(x, y, next_color):
				var oppo = (g.BLACK + g.WHITE) - next_color
				var ev = bd.alpha_beta(oppo, g.ALPHA, g.BETA, 2)
				eval_labels[ix].text = "%d" % ev
			else:
				eval_labels[ix].text = "N/A"
			bd.remove_color(x, y)
		else:
			eval_labels[ix].text = ""
		calc_eval_pos += 1
		if calc_eval_pos >= bd.prio_pos.size():
			calc_eval_pos = -1
	if put_order_ix >= 0:
		var x = put_order[put_order_ix][1]
		var y = put_order[put_order_ix][2]
		var ix = y * N_HORZ + x
		if bd.is_empty(x, y):
			bd.put_color(x, y, next_color)
			if bd.is_legal_put(x, y, next_color):
				var oppo = (g.BLACK + g.WHITE) - next_color
				var ev = bd.alpha_beta(oppo, alpha, beta, 2)	# 2 for ３手先読み
				var col = Color.BLUE if ev >= 0 else Color.RED
				eval_labels[ix].modulate = col
				eval_labels[ix].text = "%d" % ev
				#if next_color == g.BLACK:
				#	alpha = max(alpha, ev)
				#else:
				#	beta = min(beta, ev)
			else:
				eval_labels[ix].text = "N/A"
			bd.remove_color(x, y)
		else:
			eval_labels[ix].text = ""
		put_order_ix += 1
		if put_order_ix >= put_order.size():
			put_order_ix = -1
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
			put_order_ix = -1
			calc_eval_pos = -1
	pass
func do_put(x, y):
	bd.put_color(x, y, next_color)
	assert( bd.check_hv_bitmap() )
	assert( bd.check_hud_bitmap() )
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
	b2.verbose = true
	var ev1101 = b2.eval_bitmap(0b00011010000, 0, 11, g.BLACK)
	var ev1011 = b2.eval_bitmap(0b00001011000, 0, 11, g.BLACK)
	b2.verbose = false
	assert( ev1101 == ev1011 )
	#var ev1011 = b2.eval_bitmap(0b000000110, 0, 11, g.BLACK)
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
	# 評価値対称性チェック
	b2.clear()
	b2.put_color(5, 4, g.BLACK)
	b2.put_color(5, 6, g.BLACK)
	b2.put_color(4, 5, g.BLACK)
	b2.put_color(6, 5, g.BLACK)
	b2.put_color(0, 0, g.WHITE)
	b2.put_color(10, 0, g.WHITE)
	b2.put_color(0, 10, g.WHITE)
	b2.put_color(10, 10, g.WHITE)
	b2.put_color(5, 3, g.BLACK)
	var evu = b2.calc_eval(g.BLACK)
	b2.remove_color(5, 3)
	b2.put_color(5, 7, g.BLACK)
	var evd = b2.calc_eval(g.BLACK)
	b2.remove_color(5, 7)
	assert( evu == evd )
	# 黒白三・四数チェック
	b2.clear()
	assert( b2.n_black_three == 0 )
	assert( b2.n_white_three == 0 )
	assert( b2.n_black_four == 0 )
	assert( b2.n_white_four == 0 )
	b2.put_color(0, 0, g.BLACK)
	b2.put_color(1, 0, g.BLACK)
	assert( b2.n_black_three == 0 )
	assert( b2.n_white_three == 0 )
	assert( b2.n_black_four == 0 )
	assert( b2.n_white_four == 0 )
	b2.put_color(2, 0, g.BLACK)
	assert( b2.n_black_three == 1 )
	assert( b2.n_white_three == 0 )
	assert( b2.n_black_four == 0 )
	assert( b2.n_white_four == 0 )
	b2.put_color(0, 1, g.WHITE)
	b2.put_color(0, 2, g.WHITE)
	b2.put_color(0, 3, g.WHITE)
	assert( b2.n_black_three == 1 )
	assert( b2.n_white_three == 1 )
	assert( b2.n_black_four == 0 )
	assert( b2.n_white_four == 0 )
	b2.clear()
	b2.put_color(3, 3, g.BLACK)
	b2.put_color(4, 4, g.BLACK)
	b2.put_color(6, 6, g.BLACK)
	b2.put_color(7, 7, g.BLACK)
	assert( b2.n_black_three == 2 )
	assert( b2.n_white_three == 0 )
	assert( b2.n_black_four == 1 )
	assert( b2.n_white_four == 0 )
	# 評価関数差分計算
	b2.clear()
	assert( b2.eval == 0 )
	b2.put_color(0, 0, g.BLACK)
	print("eval = ", b2.eval)
	print("h_eval[0] = ", b2.h_eval[0])
	print("h_eval[1] = ", b2.h_eval[1])
	print("v_eval[0] = ", b2.v_eval[0])
	print("d_eval[6] = ", b2.d_eval[6])
	print("d_eval[5] = ", b2.d_eval[5])
	assert( b2.calc_eval_diff(g.WHITE) > 0 )
	b2.put_color(0, 1, g.WHITE)
	print("eval = ", b2.eval)
	print("h_eval[0] = ", b2.h_eval[0])
	print("h_eval[1] = ", b2.h_eval[1])
	print("v_eval[0] = ", b2.v_eval[0])
	print("d_eval[6] = ", b2.d_eval[6])
	print("d_eval[5] = ", b2.d_eval[5])
	assert( b2.calc_eval_diff(g.BLACK) < 0 )		# 白の方が中央にあり、黒は端っこ


func _on_init_button_pressed():
	if game_started: return
	bd.clear()
	next_color = g.BLACK
	won_color = g.EMPTY
	move_hist.clear()
	move_ix = -1
	bd.put_order_ix = -1
	AI_thinking = false
	$HBC/UndoButton.disabled = true
	put_pos = Vector2i(-10, -10)
	#if put_pos != Vector2i(-1, -1):
	#	#$Board/BGTileMap.set_cell(0, put_pos, -1, Vector2i(0, 0))
	#	put_pos = Vector2i(-10, -10)
	clear_eval_labels()
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
		clear_eval_labels()
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
		#$Board/BGTileMap.set_cell(0, put_pos, ID_BG, Vector2i(0, 0))	# 直前着手強調
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
	print("print_eval():")
	var ix = 0
	for y in range(N_VERT):
		for x in range(N_HORZ):
			if bd.is_empty(x, y):
				bd.put_color(x, y, next_color)
				if bd.is_legal_put(x, y, next_color):
					bd.calc_eval(next_color)
					eval_labels[ix].text = "%d" % bd.eval
					#if (x == 5 && y == 3) || (x == 5 && y == 8):
					#	var txt = "(%d, %d):\n" % [x, y]
					#	for i in range(N_VERT): txt += "%d, " % bd.h_eval[i]
					#	txt += "\n"
					#	for i in range(N_VERT): txt += "%d, " % bd.v_eval[i]
					#	txt += "\n"
					#	for i in range(N_DIAGONAL): txt += "%d, " %  bd.u_eval[i]
					#	txt += "\n"
					#	for i in range(N_DIAGONAL): txt += "%d, " %  bd.d_eval[i]
					#	print(txt)
				else:
					eval_labels[ix].text = "N/A"
				bd.remove_color(x, y)
			else:
				eval_labels[ix].text = ""
			ix += 1
	print("")
func print_eval_tbl():
	print("print_eval_tbl():")
	for i in range(bd.prio_pos.size()):
		var x = bd.prio_pos[i][0]
		var y = bd.prio_pos[i][1]
		var ix = y * N_HORZ + x
		if bd.is_empty(x, y):
			bd.put_color(x, y, next_color)
			if bd.is_legal_put(x, y, next_color):
				#bd.calc_eval(next_color)
				#eval_labels[ix].text = "%d" % bd.eval
				var ev = bd.alpha_beta(next_color, g.ALPHA, g.BETA, 1)
				eval_labels[ix].text = "%d" % ev
			else:
				eval_labels[ix].text = "N/A"
			bd.remove_color(x, y)
		else:
			eval_labels[ix].text = ""
func build_put_order():
	put_order = []
	for i in range(bd.prio_pos.size()):
		var x = bd.prio_pos[i][0]
		var y = bd.prio_pos[i][1]
		var ix = y * N_HORZ + x
		if bd.is_empty(x, y):
			bd.put_color(x, y, next_color)
			if bd.is_legal_put(x, y, next_color):
				bd.calc_eval(next_color)
				put_order.push_back([bd.eval, x, y])
			bd.remove_color(x, y)
	#print(put_order, "\n")
	if next_color == g.BLACK:
		put_order.sort_custom(func(lhs, rhs): return lhs[0] > rhs[0])
	else:
		put_order.sort_custom(func(lhs, rhs): return lhs[0] < rhs[0])
	#print(put_order, "\n")
	alpha = g.ALPHA
	beta = g.BETA
	put_order_ix = 0
func clear_eval_labels():
	for i in range(eval_labels.size()):
		eval_labels[i].text = ""
func _on_rule_button_pressed():
	clear_eval_labels()
	build_put_order()
	#calc_eval_pos = 0
	#print_eval()
	#print_eval_tbl()	# prio_pos[] 順に表示
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
			#$Board/BGTileMap.set_cell(0, prev, ID_BG, Vector2i(0, 0))
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
		#$Board/BGTileMap.set_cell(0, p, ID_BG, Vector2i(0, 0))
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
