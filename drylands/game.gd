extends Node

const LEVEL_SCENE: PackedScene = preload("res://level/level.tscn")
const HUD_SCRIPT: Script = preload("res://drylands/hud.gd")
const MOBILE_SCRIPT: Script = preload("res://drylands/mobile_controls.gd")

var level: Node
var hud: Control
var mobile_controls: Control
var paused_by_user := false
var web_start_layer: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_runtime_input_actions()
	if OS.has_feature("web"):
		_show_web_start()
	else:
		_start_match_runtime()

func _start_match_runtime() -> void:
	if is_instance_valid(level):
		return
	DrylandsState.reset_match()
	level = LEVEL_SCENE.instantiate()
	add_child(level)
	if level.has_signal("quit"):
		level.quit.connect(_toggle_pause)

	var ui_layer := CanvasLayer.new()
	ui_layer.name = "DrylandsUI"
	ui_layer.layer = 20
	ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui_layer)

	hud = HUD_SCRIPT.new()
	hud.name = "HUD"
	ui_layer.add_child(hud)

	mobile_controls = MOBILE_SCRIPT.new()
	mobile_controls.name = "MobileControls"
	ui_layer.add_child(mobile_controls)

	if not DrylandsState.match_ended.is_connected(_on_match_ended):
		DrylandsState.match_ended.connect(_on_match_ended)

func _show_web_start() -> void:
	web_start_layer = CanvasLayer.new()
	web_start_layer.name = "BrowserStart"
	web_start_layer.layer = 100
	web_start_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(web_start_layer)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	web_start_layer.add_child(root)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.015, 0.012, 0.025, 1.0)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 330)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.03, 0.06, 0.96)
	panel_style.border_color = Color(0.32, 0.91, 0.89, 0.34)
	panel_style.set_border_width_all(1)
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.corner_radius_bottom_right = 20
	panel_style.content_margin_left = 38
	panel_style.content_margin_right = 38
	panel_style.content_margin_top = 34
	panel_style.content_margin_bottom = 34
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 14)
	panel.add_child(stack)

	var eyebrow := Label.new()
	eyebrow.text = "DRYLANDS // RELAY"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_color_override("font_color", Color("52e7e4"))
	eyebrow.add_theme_font_size_override("font_size", 16)
	stack.add_child(eyebrow)

	var title := Label.new()
	title.text = "BROWSER COMBAT TEST"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("f7f4ed"))
	title.add_theme_font_size_override("font_size", 34)
	stack.add_child(title)

	var copy := Label.new()
	copy.text = "Official Godot TPS movement, character animation, camera, combat, robots and level — with the Drylands shield, glide, boost and match layer on top."
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.custom_minimum_size = Vector2(520, 64)
	copy.add_theme_color_override("font_color", Color(0.78, 0.81, 0.86, 1.0))
	copy.add_theme_font_size_override("font_size", 15)
	stack.add_child(copy)

	var controls := Label.new()
	controls.text = "WASD MOVE  •  RMB AIM  •  LMB FIRE  •  SPACE JUMP  •  SHIFT SPRINT  •  F GLIDE  •  Q BOOST"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.add_theme_color_override("font_color", Color("f2bc43"))
	controls.add_theme_font_size_override("font_size", 13)
	stack.add_child(controls)

	var button := Button.new()
	button.text = "CLICK TO DEPLOY"
	button.custom_minimum_size = Vector2(300, 58)
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(_begin_from_web_gate)
	stack.add_child(button)
	button.grab_focus()

	var note := Label.new()
	note.text = "Chrome/Edge recommended. Click once to unlock mouse-look and browser audio."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_color_override("font_color", Color(0.66, 0.69, 0.75, 1.0))
	note.add_theme_font_size_override("font_size", 12)
	stack.add_child(note)

func _begin_from_web_gate() -> void:
	# Pointer lock and browser audio are most reliable when requested directly
	# from a real click/tap user gesture.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if is_instance_valid(web_start_layer):
		web_start_layer.queue_free()
	_start_match_runtime()

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(level):
		return
	if event.is_action_pressed(&"ui_cancel") and not DrylandsState.match_over:
		_toggle_pause()
		get_viewport().set_input_as_handled()
	elif DrylandsState.match_over and (event.is_action_pressed(&"ui_accept") or event is InputEventScreenTouch and event.pressed):
		_restart_match()
		get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	if DrylandsState.match_over or not is_instance_valid(level):
		return
	paused_by_user = not paused_by_user
	get_tree().paused = paused_by_user
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if paused_by_user else Input.MOUSE_MODE_CAPTURED)
	if is_instance_valid(hud):
		hud.queue_redraw()

func _on_match_ended(_won: bool) -> void:
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if is_instance_valid(hud):
		hud.queue_redraw()

func _restart_match() -> void:
	get_tree().paused = false
	DrylandsState.reset_match()
	get_tree().reload_current_scene()

func _ensure_runtime_input_actions() -> void:
	_add_key_action(&"sprint", KEY_SHIFT)
	_add_key_action(&"glide", KEY_F)
	_add_key_action(&"boost", KEY_Q)

func _add_key_action(action: StringName, physical_key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var key := InputEventKey.new()
	key.physical_keycode = physical_key
	InputMap.action_add_event(action, key)
