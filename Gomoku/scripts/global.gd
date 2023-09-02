extends Node2D

enum {
	EMPTY = 0, BLACK, WHITE,
}
const N_HORZ = 11
const N_VERT = 11

func xyToIX(x, y): return y*N_HORZ + x
func ixToX(ix: int): return ix % N_HORZ
func ixToY(ix: int): return ix / N_HORZ

class Board:
	var h_black = []		# 水平方向ビットマップ
	var h_white = []		# 水平方向ビットマップ
	var v_black = []		# 垂直方向ビットマップ
	var v_white = []		# 垂直方向ビットマップ
	func _init():
		h_black.resize(N_VERT)
		h_black.fill(0)
		h_white.resize(N_VERT)
		h_white.fill(0)
		v_black.resize(N_HORZ)
		v_black.fill(0)
		v_white.resize(N_HORZ)
		v_white.fill(0)
	func get_color(x, y):	# h_black, h_white のみを参照
		var mask = 1 << (N_HORZ - 1 - x)
		if (h_black[y]&mask) != 0: return BLACK
		if (h_white[y]&mask) != 0: return WHITE
		return EMPTY

func _ready():
	pass # Replace with function body.
func _process(delta):
	pass
