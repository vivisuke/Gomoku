extends Node2D

const N_HORZ = 11
const N_VERT = 11

class Board:
	var hbitmap = []		# 水平方向ビットマップ
	var vbitmap = []		# 垂直方向ビットマップ
	func _init():
		hbitmap.resize(N_VERT)
		hbitmap.fill(0)
		vbitmap.resize(N_HORZ)
		vbitmap.fill(0)


func _ready():
	pass # Replace with function body.
func _process(delta):
	pass
