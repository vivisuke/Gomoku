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
	var nput
	var h_black = []		# 水平方向ビットマップ
	var h_white = []		# 水平方向ビットマップ
	var v_black = []		# 垂直方向ビットマップ
	var v_white = []		# 垂直方向ビットマップ
	var u_black = []		# 右上方向ビットマップ
	var u_white = []		# 右上方向ビットマップ
	var d_black = []		# 右下方向ビットマップ
	var d_white = []		# 右下方向ビットマップ
	func _init():
		h_black.resize(N_VERT)
		h_white.resize(N_VERT)
		v_black.resize(N_HORZ)
		v_white.resize(N_HORZ)
		u_black.resize(N_DIAGONAL)
		u_white.resize(N_DIAGONAL)
		d_black.resize(N_DIAGONAL)
		d_white.resize(N_DIAGONAL)
		clear()
		#
		unit_test()
	func clear():
		nput = 0
		h_black.fill(0)
		h_white.fill(0)
		v_black.fill(0)
		v_white.fill(0)
		u_black.fill(0)
		u_white.fill(0)
		d_black.fill(0)
		d_white.fill(0)
		

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
	func xyToDrIxMask(x, y) -> Array:	# return [ix, mask]
		var ix = x - y + 5
		if ix < 0 || ix > 12: return [-1, 0]
		if ix <= 5:
			return [ix, 1<<(g.N_HORZ-1-x+(ix-5))]
		else:
			return [ix, 1<<(g.N_HORZ-1-y-(ix-5))]

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
	func xyToUrIxMask(x, y) -> Array:	# return [ix, mask]
		var ix = x + y - 10 + 5
		if ix < 0 || ix > 12: return [-1, 0]
		if ix <= 5:
			return [ix, 1<<(g.N_HORZ-1-x+(ix-5))]
		else:
			return [ix, 1<<(y-(ix-5))]
	func is_empty(x, y):	# h_black, h_white のみを参照
		var mask = 1 << (N_HORZ - 1 - x)
		return h_black[y]&mask == 0 && h_white[y]&mask == 0
	func get_color(x, y):	# h_black, h_white のみを参照
		var mask = 1 << (N_HORZ - 1 - x)
		if (h_black[y]&mask) != 0: return BLACK
		if (h_white[y]&mask) != 0: return WHITE
		return EMPTY
	func put_color(x, y, col):		# 前提：(x, y) は空欄、col：BLACK or WHITE
		nput += 1
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
	func remove_color(x, y):
		nput -= 1
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
	func is_five_sub(b, bitmap):		# b に着手後、五目並んだか？
		var mask = (b << 5) - 1			# 0b1 → 0b11111
		mask -= b - 1					# 0b2 → 0b111110
		for i in range(5):
			if (bitmap & mask) == mask: return true
			if (mask&1) == 1: break
			mask >>= 1
		return false
	func is_five(x, y, col):		# (x, y) に着手後、五目並んだか？
		var h = 1 << (N_HORZ - 1 - x)
		var v = 1 << (N_HORZ - 1 - y)
		var d = xyToDrIxMask(x, y)
		var u = xyToUrIxMask(x, y)
		if col == BLACK:
			if is_five_sub(h, h_black[y]): return true
			if is_five_sub(v, v_black[x]): return true
			if d[0] >= 0 && is_five_sub(d[1], d_black[d[0]]): return true
			if u[0] >= 0 && is_five_sub(u[1], u_black[u[0]]): return true
		elif col == WHITE:
			if is_five_sub(h, h_white[y]): return true
			if is_five_sub(v, v_white[x]): return true
			if d[0] >= 0 && is_five_sub(d[1], d_white[d[0]]): return true
			if u[0] >= 0 && is_five_sub(u[1], u_white[u[0]]): return true
		return false
	func unit_test():
		assert(xyToDrIxMask(0, 0) == [5, 0b10000000000])
		assert(xyToDrIxMask(10, 10) == [5, 0b1])
		assert(xyToDrIxMask(0, 1) == [4, 0b01000000000])
		assert(xyToDrIxMask(9, 10) == [4, 0b1])
		assert(xyToDrIxMask(0, 2) == [3, 0b00100000000])
		assert(xyToDrIxMask(8, 10) == [3, 0b1])
		assert(xyToDrIxMask(1, 0) == [6, 0b01000000000])
		assert(xyToDrIxMask(10, 9) == [6, 0b1])
		#
		assert(xyToUrIxMask(10, 0) == [5, 0b1])
		assert(xyToUrIxMask(0, 10) == [5, 0b10000000000])
		assert(xyToUrIxMask(9, 0) == [4, 0b1])
		assert(xyToUrIxMask(0, 9) == [4, 0b01000000000])
		assert(xyToUrIxMask(8, 0) == [3, 0b1])
		assert(xyToUrIxMask(0, 8) == [3, 0b00100000000])
		assert(xyToUrIxMask(10, 1) == [6, 0b1])
		assert(xyToUrIxMask(1, 10) == [6, 0b01000000000])
		assert(xyToUrIxMask(10, 2) == [7, 0b1])

func _ready():
	pass # Replace with function body.
func _process(delta):
	pass
