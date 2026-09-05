extends Control

const CYAN := Color("52e7e4")
const GOLD := Color("f2bc43")
const RED := Color("ff536d")
const WHITE := Color("f7f4ed")
const PANEL := Color(0.045, 0.038, 0.072, 0.84)
const PANEL_SOFT := Color(0.045, 0.038, 0.072, 0.65)
const MUTED := Color(0.75, 0.78, 0.82, 0.9)

var font: Font

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	font = ThemeDB.fallback_font
	DrylandsState.stats_changed.connect(queue_redraw)
	DrylandsState.score_changed.connect(queue_redraw)
	DrylandsState.feed_event.connect(func(_text: String): queue_redraw())
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var s := size
	if s.x <= 0.0 or s.y <= 0.0:
		return
	_draw_vitals(Vector2(22, 22))
	_draw_match(Vector2(s.x * 0.5, 22))
	_draw_feed(Vector2(s.x - 310, 30))
	_draw_weapon(Vector2(s.x - 305, s.y - 136))
	_draw_center_reticle(Vector2(s.x * 0.5, s.y * 0.5))
	if get_tree().paused:
		_draw_pause_or_results(s)

func _panel(rect: Rect2, radius := 14.0, color := PANEL) -> void:
	draw_style_box(_box(color, radius), rect)

func _box(color: Color, radius: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = int(radius)
	box.corner_radius_top_right = int(radius)
	box.corner_radius_bottom_left = int(radius)
	box.corner_radius_bottom_right = int(radius)
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.border_color = Color(1, 1, 1, 0.08)
	return box

func _text(text: String, pos: Vector2, px: int, color := WHITE, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	draw_string(font, pos, text, align, width, px, color)

func _draw_vitals(pos: Vector2) -> void:
	var rect := Rect2(pos, Vector2(278, 126))
	_panel(rect)
	_text("DRYLANDS // RELAY", pos + Vector2(16, 24), 14, CYAN)
	_bar(pos + Vector2(16, 38), "SHIELD", DrylandsState.shield / 100.0, CYAN)
	_bar(pos + Vector2(16, 67), "HEALTH", DrylandsState.health / 100.0, RED)
	_bar(pos + Vector2(16, 96), "BOOST", DrylandsState.boost / 100.0, GOLD)

func _bar(pos: Vector2, label: String, fraction: float, color: Color) -> void:
	_text(label, pos + Vector2(0, 13), 12, MUTED)
	var track := Rect2(pos + Vector2(70, 2), Vector2(168, 12))
	draw_rect(track, Color(1, 1, 1, 0.10), true)
	draw_rect(Rect2(track.position, Vector2(track.size.x * clampf(fraction, 0.0, 1.0), track.size.y)), color, true)
	_text(str(int(round(fraction * 100.0))), pos + Vector2(244, 13), 12, WHITE)

func _draw_match(pos: Vector2) -> void:
	var rect := Rect2(pos - Vector2(94, 0), Vector2(188, 66))
	_panel(rect)
	var mins := int(DrylandsState.time_left) / 60
	var secs := int(DrylandsState.time_left) % 60
	_text("%d:%02d" % [mins, secs], rect.position + Vector2(0, 31), 28, WHITE, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
	_text("%d / %d  •  ELIMINATIONS" % [DrylandsState.score, DrylandsState.SCORE_LIMIT], rect.position + Vector2(0, 53), 11, CYAN, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)

func _draw_feed(pos: Vector2) -> void:
	var y := pos.y
	for line in DrylandsState.feed:
		_panel(Rect2(Vector2(pos.x, y), Vector2(282, 27)), 8.0, PANEL_SOFT)
		_text(line, Vector2(pos.x + 10, y + 19), 11, WHITE)
		y += 32

func _draw_weapon(pos: Vector2) -> void:
	_panel(Rect2(pos, Vector2(282, 112)))
	_text("ARC RIFLE", pos + Vector2(16, 27), 13, CYAN)
	_text("ENERGY CARBINE", pos + Vector2(16, 53), 20, WHITE)
	_text("LMB / FIRE  •  RMB / AIM", pos + Vector2(16, 78), 11, MUTED)
	_text("F GLIDE  •  Q BOOST", pos + Vector2(16, 97), 11, GOLD)

func _draw_center_reticle(center: Vector2) -> void:
	var gap := 6.0
	var arm := 10.0
	draw_line(center + Vector2(-gap - arm, 0), center + Vector2(-gap, 0), CYAN, 2.0)
	draw_line(center + Vector2(gap, 0), center + Vector2(gap + arm, 0), CYAN, 2.0)
	draw_line(center + Vector2(0, -gap - arm), center + Vector2(0, -gap), CYAN, 2.0)
	draw_line(center + Vector2(0, gap), center + Vector2(0, gap + arm), CYAN, 2.0)

func _draw_pause_or_results(s: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.46), true)
	var rect := Rect2(Vector2(s.x * 0.5 - 230, s.y * 0.5 - 95), Vector2(460, 190))
	_panel(rect, 20.0, Color(0.035, 0.03, 0.06, 0.96))
	if DrylandsState.match_over:
		_text("RELAY SECURED" if DrylandsState.score >= DrylandsState.SCORE_LIMIT else "TIME EXPIRED", rect.position + Vector2(0, 58), 30, GOLD, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
		_text("%d eliminations • %d deaths" % [DrylandsState.score, DrylandsState.deaths], rect.position + Vector2(0, 96), 16, WHITE, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
		_text("TAP / ENTER TO RESTART", rect.position + Vector2(0, 145), 13, CYAN, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
	else:
		_text("PAUSED", rect.position + Vector2(0, 70), 30, WHITE, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
		_text("ESC / START TO RESUME", rect.position + Vector2(0, 125), 13, CYAN, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
