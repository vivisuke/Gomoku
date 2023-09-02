extends ColorRect

const BD_WIDTH = 500
var N_HORZ = g.N_HORZ
var N_VERT = g.N_VERT
const FRAME_WD = 38
#const CELL_WD = (BD_WIDTH - FRAME_WD) / N_HORZ
const CELL_WD = 42		# 42*12 = 504
const ORG_X = CELL_WD*0.5
const ORG_Y = CELL_WD*0.5
var RT_END = CELL_WD*(N_HORZ-0.5)
var LW_END = CELL_WD*(N_VERT-0.5)

# Called when the node enters the scene tree for the first time.
func _ready():
	#print("CELL_WD = ", CELL_WD)
	for x in range(N_HORZ):
		var l = Label.new()
		l.text = "abcdefghijk"[x]
		l.set_position(Vector2(ORG_X+CELL_WD*x-4, -24))
		l.add_theme_color_override("font_color", Color.BLACK)
		add_child(l)
	for y in range(N_VERT):
		var l = Label.new()
		l.text = [" 1", " 2", " 3", " 4", " 5", " 6", " 7", " 8", " 9", "10", "11"][y]
		l.set_position(Vector2(-26, ORG_Y+CELL_WD*y-10))
		l.add_theme_color_override("font_color", Color.BLACK)
		add_child(l)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _draw():
	var style_box = StyleBoxFlat.new()      # 影、ボーダなどを描画するための矩形スタイルオブジェクト
	style_box.bg_color = color   # 矩形背景色
	style_box.shadow_offset = Vector2(0, 4)     # 影オフセット
	style_box.shadow_size = 8                   # 影（ぼかし）サイズ
	draw_style_box(style_box, Rect2(Vector2(0, 0), self.size))      # style_box に設定した矩形を描画
	#
	for x in range(N_HORZ):
		var wd = 2.5 if x == 0 || x == N_HORZ - 1 else 1
		draw_line(Vector2(ORG_X, ORG_Y+CELL_WD*x),
					Vector2(RT_END, ORG_Y+CELL_WD*x),
					Color.BLACK, wd)
		draw_line(Vector2(ORG_X+CELL_WD*x, ORG_Y),
					Vector2(ORG_X+CELL_WD*x, LW_END),
					Color.BLACK, wd)
	draw_circle(Vector2(ORG_X+CELL_WD*2, ORG_Y+CELL_WD*2), 3, Color.BLACK)
	draw_circle(Vector2(ORG_X+CELL_WD*8, ORG_Y+CELL_WD*2), 3, Color.BLACK)
	draw_circle(Vector2(ORG_X+CELL_WD*2, ORG_Y+CELL_WD*8), 3, Color.BLACK)
	draw_circle(Vector2(ORG_X+CELL_WD*8, ORG_Y+CELL_WD*8), 3, Color.BLACK)
	draw_circle(Vector2(ORG_X+CELL_WD*5, ORG_Y+CELL_WD*5), 3, Color.BLACK)
	pass
