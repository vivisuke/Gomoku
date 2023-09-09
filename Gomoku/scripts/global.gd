extends Node2D

enum {
	EMPTY = 0, BLACK, WHITE,
}
const N_HORZ = 11
const N_VERT = 11
const N_DIAGONAL = 6 + 1 + 6		# 斜め方向ビットマップ配列数

func xyToIX(x, y): return y*N_HORZ + x
func ixToX(ix: int): return ix % N_HORZ
func ixToY(ix: int): return ix / N_HORZ

class Board:
	const evtable = [		# 五路評価値テーブル
		0,		# ・・・・・
		1,		# ・・・・●
		1,		# ・・・●・
		4,		# ・・・●●
		1,		# ・・●・・
		2,		# ・・●・●
		4,		# ・・●●・
		10,		# ・・●●●
		1,		# ・●・・・
		2,		# ・●・・●
		2,		# ・●・●・
		10,		# ・●・●●
		2,		# ・●●・・
		10,		# ・●●・●
		10,		# ・●●●・
		100,	# ・●●●●
		1,		# ●・・・・
		2,		# ●・・・●
		2,		# ●・・●・
		6,		# ●・・●●
		2,		# ●・●・・
		5,		# ●・●・●
		10,		# ●・●●・
		100,	# ●・●●●
		4,		# ●●・・・
		6,		# ●●・・●
		10,		# ●●・●・
		100,	# ●●・●●
		10,		# ●●●・・
		100,	# ●●●・●
		100,	# ●●●●・
		9999,	# ●●●●●
	]
	#var nput
	var n_space				# 空欄数
	var eval = 0			# 評価値
	var h_black = []		# 水平方向ビットマップ
	var h_white = []		# 水平方向ビットマップ
	var v_black = []		# 垂直方向ビットマップ
	var v_white = []		# 垂直方向ビットマップ
	var u_black = []		# 右上方向ビットマップ
	var u_white = []		# 右上方向ビットマップ
	var d_black = []		# 右下方向ビットマップ
	var d_white = []		# 右下方向ビットマップ
	var h_eval = []			# 水平方向評価値（黒から見た値）
	var v_eval = []			# 垂直方向評価値
	var u_eval = []			# 右上方向評価値
	var d_eval = []			# 右下方向評価値
	func _init():
		h_black.resize(N_VERT)
		h_white.resize(N_VERT)
		v_black.resize(N_HORZ)
		v_white.resize(N_HORZ)
		u_black.resize(N_DIAGONAL)
		u_white.resize(N_DIAGONAL)
		d_black.resize(N_DIAGONAL)
		d_white.resize(N_DIAGONAL)
		h_eval.resize(N_VERT)
		v_eval.resize(N_HORZ)
		u_eval.resize(N_DIAGONAL)
		d_eval.resize(N_DIAGONAL)
		clear()
		#
		unit_test()
	func clear():
		#nput = 0
		n_space = N_HORZ * N_VERT
		eval = 0
		h_black.fill(0)
		h_white.fill(0)
		v_black.fill(0)
		v_white.fill(0)
		u_black.fill(0)
		u_white.fill(0)
		d_black.fill(0)
		d_white.fill(0)
		h_eval.fill(0)
		v_eval.fill(0)
		u_eval.fill(0)
		d_eval.fill(0)
		

	#  5  6    12
	#	┌────────┐→x
	#   │＼＼…＼        │  
	#   │＼＼    ＼      │  
	#   │：        ＼    │  
	#  0│＼          ＼  │  
	#   │  ＼          ＼│  
	#   │    ＼        ：│  
	#   │      ＼    ＼＼│  
	#   │        ＼…＼＼│  
	#   └────────┘  
	#   ↓y
	func xyToDrIxMask(x, y) -> Array:	# return [ix, mask, nbit]
		var ix = x - y + 6
		if ix < 0 || ix > 12: return [-1, 0]
		if ix <= 6:
			return [ix, 1<<(g.N_HORZ-1-x+(ix-6)), 5+ix]
		else:
			return [ix, 1<<(g.N_HORZ-1-y-(ix-6)), 17-ix]

	#             0         5
	#	┌────────┐→x
	#   │        ／…／／│  
	#   │      ／    ／／│  
	#   │    ／        ：│  
	#   │  ／          ／│12  
	#   │／          ／  │  
	#   │：        ／    │  
	#   │／／    ／      │  
	#   │／／…／        │  
	#   └────────┘  
	#   ↓y
	func xyToUrIxMask(x, y) -> Array:	# return [ix, mask, nbit]
		var ix = x + y - 10 + 6
		if ix < 0 || ix > 12: return [-1, 0]
		if ix <= 6:
			return [ix, 1<<(g.N_HORZ-1-x+(ix-6)), 5+ix]
		else:
			return [ix, 1<<(y-(ix-6)), 17-ix]
	func is_empty(x, y):	# h_black, h_white のみを参照
		var mask = 1 << (N_HORZ - 1 - x)
		return h_black[y]&mask == 0 && h_white[y]&mask == 0
	func get_color(x, y):	# h_black, h_white のみを参照
		var mask = 1 << (N_HORZ - 1 - x)
		if (h_black[y]&mask) != 0: return BLACK
		if (h_white[y]&mask) != 0: return WHITE
		return EMPTY
	# 着手・盤面評価
	func put_color(x, y, col):		# 前提：(x, y) は空欄、col：BLACK or WHITE
		#nput += 1
		n_space -= 1
		var mask = 1 << (N_HORZ - 1 - x)
		if col == BLACK:
			h_black[y] |= mask
		elif col == WHITE:
			h_white[y] |= mask
		mask = 1 << (N_HORZ - 1 - y)
		if col == BLACK:
			v_black[x] |= mask
		elif col == WHITE:
			v_white[x] |= mask
		# done: 斜めビットマップ更新
		var t = xyToUrIxMask(x, y)
		if t[0] >= 0:
			if col == BLACK:
				u_black[t[0]] |= t[1]
			elif col == WHITE:
				u_white[t[0]] |= t[1]
		t = xyToDrIxMask(x, y)
		if t[0] >= 0:
			if col == BLACK:
				d_black[t[0]] |= t[1]
			elif col == WHITE:
				d_white[t[0]] |= t[1]
		eval_putxy(x, y, BLACK+WHITE-col)	# 結果は eval に格納される
	func remove_color(x, y):
		#nput -= 1
		n_space += 1
		var mask = 1 << (N_HORZ - 1 - x)
		h_black[y] &= ~mask
		h_white[y] &= ~mask
		mask = 1 << (N_HORZ - 1 - y)
		v_black[x] &= ~mask
		v_white[x] &= ~mask
		# done: 縦・斜めビットマップ更新
		var t = xyToUrIxMask(x, y)
		if t[0] >= 0:
			u_black[t[0]] &= ~t[1]
			u_white[t[0]] &= ~t[1]
		t = xyToDrIxMask(x, y)
		if t[0] >= 0:
			d_black[t[0]] &= ~t[1]
			d_white[t[0]] &= ~t[1]
		eval_putxy(x, y, EMPTY)
	const is34table = [		# 三四テーブル
		false,		# ・・・・・
		false,		# ・・・・●
		false,		# ・・・●・
		false,		# ・・・●●
		false,		# ・・●・・
		false,		# ・・●・●
		false,		# ・・●●・
		true,		# ・・●●●
		false,		# ・●・・・
		false,		# ・●・・●
		false,		# ・●・●・
		true,		# ・●・●●
		false,		# ・●●・・
		true,		# ・●●・●
		true,		# ・●●●・
		true,		# ・●●●●
		false,		# ●・・・・
		false,		# ●・・・●
		false,		# ●・・●・
		false,		# ●・・●●
		false,		# ●・●・・
		false,		# ●・●・●
		true,		# ●・●●・
		true,		# ●・●●●
		false,		# ●●・・・
		false,		# ●●・・●
		true,		# ●●・●・
		true,		# ●●・●●
		true,		# ●●●・・
		true,		# ●●●・●
		true,		# ●●●●・
		false,		# ●●●●●
	]
	func is_forced(b5):
		return is34table[b5]
		#return (b5 == 0b01110 || b5 == 0b01111 || b5 == 0b10111 ||
		#		b5 == 0b11011 || b5 == 0b11101 || b5 == 0b11110)
	func eval_bitmap(black, white, nbit, nxcol):		# bitmap（下位 nbit）を評価
		var ev = 0
		for i in range(nbit - 4):
			var b5 = black & 0x1f
			var w5 = white & 0x1f
			if b5 != 0:
				if w5 == 0:
					ev += evtable[b5]
					if nxcol == BLACK && is_forced(b5):
						ev += evtable[b5] * 2
				else:
					pass	# 黒白両方ある場合は、評価値: 0
			else:
				if w5 != 0:
					ev -= evtable[w5]
					if nxcol == WHITE && is_forced(w5):
						ev -= evtable[w5] * 2
				else:
					pass	# 黒白両方空欄のみの場合は、評価値: 0
			black >>= 1
			white >>= 1
		return ev
	func calc_eval(next_color):			# 評価関数計算、非差分計算
		eval = 0
		for y in range(N_VERT):
			h_eval[y] = eval_bitmap(h_black[y], h_white[y], N_HORZ, next_color)
			eval += h_eval[y]
		for x in range(N_HORZ):
			v_eval[x] = eval_bitmap(v_black[x], v_white[x], N_VERT, next_color)
			eval += v_eval[x]
		var len = 5
		for i in range(N_DIAGONAL):
			u_eval[i] = eval_bitmap(u_black[i], u_white[i], len, next_color)
			eval += u_eval[i]
			d_eval[i] = eval_bitmap(d_black[i], d_white[i], len, next_color)
			eval += d_eval[i]
			if len < 11: len += 1
			else: len -= 1
	func eval_putxy(x, y, next_color):	# (x, y) に着手した場合の差分評価
		eval -= h_eval[y]
		h_eval[y] = eval_bitmap(h_black[y], h_white[y], N_HORZ, EMPTY)
		eval += h_eval[y]
		eval -= v_eval[x]
		v_eval[x] = eval_bitmap(v_black[x], v_white[x], N_VERT, EMPTY)
		eval += v_eval[x]
		var t = xyToUrIxMask(x, y)
		if t[0] >= 0:
			eval -= u_eval[t[0]]
			u_eval[t[0]] = eval_bitmap(u_black[t[0]], u_white[t[0]], t[2], EMPTY)
			eval += u_eval[t[0]]
		t = xyToDrIxMask(x, y)
		if t[0] >= 0:
			eval -= d_eval[t[0]]
			d_eval[t[0]] = eval_bitmap(d_black[t[0]], d_white[t[0]], t[2], EMPTY)
			eval += d_eval[t[0]]
		# done: 差分計算
		#var ev = 0
		#for i in range(N_HORZ):
		#	ev += h_eval[i]
		#	ev += v_eval[i]
		#for i in range(N_DIAGONAL):
		#	ev += u_eval[i]
		#	ev += d_eval[i]
		return eval
	func is_five_sub(bitmap: int):		# 着手後、五目並んだか？
		#var a = bitmap
		#for i in range(4):
		#	bitmap >>= 1
		#	a &= bitmap
		var a = bitmap & (bitmap>>1) & (bitmap>>2) & (bitmap>>3) & (bitmap>>4)
		return a != 0
	#func is_five_sub(b: int, bitmap: int):		# b に着手後、五目並んだか？
		#var mask = (b << 5) - 1			# 0b1 → 0b11111
		#mask -= b - 1					# 0b2 → 0b111110
		#for i in range(5):
		#	if (bitmap & mask) == mask: return true
		#	if (mask&1) == 1: break
		#	mask >>= 1
		#return false
	func is_five(x, y, col):		# (x, y) に着手後、五目並んだか？
		var h = 1 << (N_HORZ - 1 - x)
		var v = 1 << (N_HORZ - 1 - y)
		var d = xyToDrIxMask(x, y)
		var u = xyToUrIxMask(x, y)
		if col == BLACK:
			if is_five_sub(h_black[y]): return true
			if is_five_sub(v_black[x]): return true
			if d[0] >= 0 && is_five_sub(d_black[d[0]]): return true
			if u[0] >= 0 && is_five_sub(u_black[u[0]]): return true
		elif col == WHITE:
			if is_five_sub(h_white[y]): return true
			if is_five_sub(v_white[x]): return true
			if d[0] >= 0 && is_five_sub(d_white[d[0]]): return true
			if u[0] >= 0 && is_five_sub(u_white[u[0]]): return true
		return false
	func is_six_sub(bitmap: int):		# 着手後、六目並んだか？
		var a = bitmap & (bitmap>>1) & (bitmap>>2) & (bitmap>>3) & (bitmap>>4) & (bitmap>>5)
		return a != 0
	func is_six(x, y, col):		# (x, y) に着手後、六目並んだか？
		var h = 1 << (N_HORZ - 1 - x)
		var v = 1 << (N_HORZ - 1 - y)
		var d = xyToDrIxMask(x, y)
		var u = xyToUrIxMask(x, y)
		if col == BLACK:
			if is_six_sub(h_black[y]): return true
			if is_six_sub(v_black[x]): return true
			if d[0] >= 0 && is_six_sub(d_black[d[0]]): return true
			if u[0] >= 0 && is_six_sub(u_black[u[0]]): return true
		elif col == WHITE:
			if is_six_sub(h_white[y]): return true
			if is_six_sub(v_white[x]): return true
			if d[0] >= 0 && is_six_sub(d_white[d[0]]): return true
			if u[0] >= 0 && is_six_sub(u_white[u[0]]): return true
		return false
	func put_minmax(next_color):
		#var op = Vector2i(-1, -1)
		var lst = []
		if next_color == BLACK:		# 黒番
			var mx = -99999
			for y in range(N_VERT):
				for x in range(N_HORZ):
					if is_empty(x, y):
						put_color(x, y, next_color)
						if !is_six(x, y, next_color):
							calc_eval(WHITE)
							if eval > mx:
								mx = eval
								#op = Vector2i(x, y)
								lst = [Vector2i(x, y)]
							elif eval == mx:
								lst.push_back(Vector2i(x, y))
						remove_color(x, y)
		else:						# 白番
			var mn = 99999
			for y in range(N_VERT):
				for x in range(N_HORZ):
					if is_empty(x, y):
						put_color(x, y, next_color)
						calc_eval(BLACK)
						if eval < mn:
							mn = eval
							#op = Vector2i(x, y)
							lst = [Vector2i(x, y)]
						elif eval == mn:
							lst.push_back(Vector2i(x, y))
						remove_color(x, y)
		if lst.size() == 1: return lst[0]
		var r = randi() % lst.size()
		return lst[r]
	func print():
		for y in range(N_VERT):
			var txt = ""
			var mask = 1 << 10
			for i in range(N_HORZ):
				if (h_black[y] & mask) != 0: txt += " X"
				elif (h_white[y] & mask) != 0: txt += " O"
				else: txt += " ."
				mask >>= 1
			print(txt)
	func print_eval(next_color):
		for y in range(N_VERT):
			var txt = ""
			var mask = 1 << 10
			for x in range(N_HORZ):
				if (h_black[y] & mask) != 0: txt += "   X"
				elif (h_white[y] & mask) != 0: txt += "   O"
				else:
					put_color(x, y, next_color)
					txt += ("%4d" % eval)
					remove_color(x, y)
				mask >>= 1
			print(txt)
	func print_eval_ndiff(next_color):
		for y in range(N_VERT):
			var txt = ""
			var mask = 1 << 10
			for x in range(N_HORZ):
				if (h_black[y] & mask) != 0: txt += "    X"
				elif (h_white[y] & mask) != 0: txt += "    O"
				else:
					put_color(x, y, next_color)
					if next_color == BLACK && is_six(x, y, BLACK):
						txt += "  ---"
					else:
						calc_eval(next_color)
						txt += ("%5d" % eval)
					remove_color(x, y)
				mask >>= 1
			print(txt)
	func unit_test():
		assert(xyToDrIxMask(0, 0) == [6, 0b10000000000, 11])
		assert(xyToDrIxMask(10, 10) == [6, 0b1, 11])
		assert(xyToDrIxMask(0, 1) == [5, 0b01000000000, 10])
		assert(xyToDrIxMask(9, 10) == [5, 0b1, 10])
		assert(xyToDrIxMask(0, 2) == [4, 0b00100000000, 9])
		assert(xyToDrIxMask(8, 10) == [4, 0b1, 9])
		assert(xyToDrIxMask(1, 0) == [7, 0b01000000000, 10])
		assert(xyToDrIxMask(10, 9) == [7, 0b1, 10])
		#
		assert(xyToUrIxMask(10, 0) == [6, 0b1, 11])
		assert(xyToUrIxMask(0, 10) == [6, 0b10000000000, 11])
		assert(xyToUrIxMask(9, 0) == [5, 0b1, 10])
		assert(xyToUrIxMask(0, 9) == [5, 0b01000000000, 10])
		assert(xyToUrIxMask(8, 0) == [4, 0b1, 9])
		assert(xyToUrIxMask(0, 8) == [4, 0b00100000000, 9])
		assert(xyToUrIxMask(10, 1) == [7, 0b1, 10])
		assert(xyToUrIxMask(1, 10) == [7, 0b01000000000, 10])
		assert(xyToUrIxMask(10, 2) == [8, 0b1, 9])

func _ready():
	pass # Replace with function body.
func _process(delta):
	pass
