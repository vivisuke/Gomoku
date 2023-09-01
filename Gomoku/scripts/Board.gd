extends ColorRect

const BD_WIDTH = 500
const N_HORZ = 11
const N_VERT = 11
const FRAME_WD = 38
#const CELL_WD = (BD_WIDTH - FRAME_WD) / N_HORZ
const CELL_WD = 42		# 42*12 = 504
const ORG_X = 42		# 原点
const ORG_Y = 42		# 原点
const RT_END = ORG_X+CELL_WD*(N_HORZ-1)
const LW_END = ORG_Y+CELL_WD*(N_VERT-1)

# Called when the node enters the scene tree for the first time.
func _ready():
	print("CELL_WD = ", CELL_WD)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _draw():
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
