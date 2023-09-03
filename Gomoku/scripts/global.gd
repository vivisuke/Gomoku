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
	var h_black = []		# 水平方向ビットマップ
	var h_white = []		# 水平方向ビットマップ
	var v_black = []		# 垂直方向ビットマップ
	var v_white = []		# 垂直方向ビットマップ
	var ur_black = []		# 右上方向ビットマップ
	var ur_white = []		# 右上方向ビットマップ
	var dr_black = []		# 右下方向ビットマップ
	var dr_white = []		# 右下方向ビットマップ
	func _init():
		h_black.resize(N_VERT); h_black.fill(0)
		h_white.resize(N_VERT); h_white.fill(0)
		v_black.resize(N_HORZ); v_black.fill(0)
		v_white.resize(N_HORZ); v_white.fill(0)
		ur_black.resize(N_DIAGONAL); ur_black.fill(0)
		ur_white.resize(N_DIAGONAL); ur_white.fill(0)
		dr_black.resize(N_DIAGONAL); dr_black.fill(0)
		dr_white.resize(N_DIAGONAL); dr_white.fill(0)
		#
		unit_test()

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
				ur_black[t0] |= mask
			elif col == WHITE:
				ur_white[t0] |= mask
		t = xyToDrIxMask(x, y)
		if t[0] >= 0:
			if col == BLACK:
				dr_black[t0] |= mask
			elif col == WHITE:
				dr_white[t0] |= mask
	func remove_color(x, y):
		var mask = 1 << (N_HORZ - 1 - x)
		h_black[y] &= ~mask
		h_white[y] &= ~mask
		mask = 1 << (N_HORZ - 1 - y)
		v_black[x] &= ~mask
		v_white[x] &= ~mask
		# done: 縦・斜めビットマップ更新
		var t = xyToUrIxMask(x, y)
		if t[0] >= 0:
			ur_black[t0] &= !mask
			ur_white[t0] &= !mask
		t = xyToDrIxMask(x, y)
		if t[0] >= 0:
			dr_black[t0] &= !mask
			dr_white[t0] &= !mask
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
