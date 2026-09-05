extends Control

const CYAN := Color("52e7e4")
const GOLD := Color("f2bc43")
const WHITE := Color("f7f4ed")
const PANEL := Color(0.03, 0.03, 0.05, 0.46)
const JOYSTICK_RADIUS := 76.0
const LOOK_SENSITIVITY := 0.0042

var move_finger := -1
var look_finger := -1
var move_origin := Vector2.ZERO
var move_knob := Vector2.ZERO
var button_fingers: Dictionary = {}
var font: Font

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	font = ThemeDB.fallback_font
	visible = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	get_viewport().size_changed.connect(queue_redraw)
	set_process_input(visible)
	queue_redraw()

func _exit_tree() -> void:
	_release_movement()
	for action in [&"jump", &"shoot", &"aim", &"glide", &"boost"]:
		Input.action_release(action)

func _input(event: InputEvent) -> void:
	if not visible or get_tree().paused:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		var action := _button_at(event.position)
		if action != &"":
			button_fingers[event.index] = action
			_press_button(action)
		elif event.position.x < size.x * 0.43 and event.position.y > size.y * 0.36 and move_finger == -1:
			move_finger = event.index
			move_origin = event.position
			move_knob = event.position
			_update_move(Vector2.ZERO)
		elif look_finger == -1:
			look_finger = event.index
	else:
		if event.index == move_finger:
			move_finger = -1
			_release_movement()
		if event.index == look_finger:
			look_finger = -1
		if button_fingers.has(event.index):
			_release_button(button_fingers[event.index])
			button_fingers.erase(event.index)
	queue_redraw()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == move_finger:
		move_knob = move_origin + (event.position - move_origin).limit_length(JOYSTICK_RADIUS)
		_update_move((move_knob - move_origin) / JOYSTICK_RADIUS)
		queue_redraw()
	elif event.index == look_finger:
		var sync := _player_input()
		if sync != null and sync.has_method("rotate_camera"):
			sync.rotate_camera(event.relative * LOOK_SENSITIVITY)

func _update_move(v: Vector2) -> void:
	_release_movement()
	if v.x < -0.05:
		Input.action_press(&"move_left", absf(v.x))
	elif v.x > 0.05:
		Input.action_press(&"move_right", absf(v.x))
	if v.y < -0.05:
		Input.action_press(&"move_forward", absf(v.y))
	elif v.y > 0.05:
		Input.action_press(&"move_back", absf(v.y))

func _release_movement() -> void:
	for action in [&"move_left", &"move_right", &"move_forward", &"move_back"]:
		Input.action_release(action)

func _press_button(action: StringName) -> void:
	if action == &"shoot":
		Input.action_press(&"aim")
	Input.action_press(action)

func _release_button(action: StringName) -> void:
	Input.action_release(action)
	if action == &"shoot":
		Input.action_release(&"aim")

func _button_at(p: Vector2) -> StringName:
	var buttons := _button_rects()
	for action in buttons:
		if buttons[action].has_point(p):
			return action
	return &""

func _button_rects() -> Dictionary:
	var s := size
	var r := 58.0
	return {
		&"shoot": Rect2(Vector2(s.x - 2.35 * r, s.y - 2.25 * r), Vector2(r * 1.65, r * 1.65)),
		&"jump": Rect2(Vector2(s.x - 4.05 * r, s.y - 1.85 * r), Vector2(r * 1.35, r * 1.35)),
		&"glide": Rect2(Vector2(s.x - 4.15 * r, s.y - 3.35 * r), Vector2(r * 1.35, r * 1.35)),
		&"boost": Rect2(Vector2(s.x - 2.25 * r, s.y - 4.05 * r), Vector2(r * 1.35, r * 1.35)),
	}

func _player_input() -> Node:
	var players := get_tree().get_nodes_in_group(&"drylands_player")
	if players.is_empty():
		return null
	return players[0].get_node_or_null("InputSynchronizer")

func _draw() -> void:
	if not visible:
		return
	var base := move_origin if move_finger != -1 else Vector2(118, size.y - 118)
	var knob := move_knob if move_finger != -1 else base
	draw_circle(base, JOYSTICK_RADIUS, PANEL)
	draw_arc(base, JOYSTICK_RADIUS, 0, TAU, 48, Color(CYAN, 0.55), 3.0)
	draw_circle(knob, 31, Color(CYAN, 0.55))
	for action in _button_rects():
		var rect: Rect2 = _button_rects()[action]
		var center := rect.get_center()
		var radius := minf(rect.size.x, rect.size.y) * 0.5
		var active := button_fingers.values().has(action)
		draw_circle(center, radius, Color(GOLD if action == &"boost" else CYAN, 0.42 if active else 0.22))
		draw_arc(center, radius, 0, TAU, 40, Color(GOLD if action == &"boost" else CYAN, 0.72), 2.5)
		var label := String(action).to_upper()
		var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
		draw_string(font, center + Vector2(-text_size.x * 0.5, 5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, WHITE)
