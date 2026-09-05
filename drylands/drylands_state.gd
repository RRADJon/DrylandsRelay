extends Node

signal stats_changed
signal score_changed
signal feed_event(text: String)
signal match_ended(won: bool)

const MAX_SHIELD := 100.0
const MAX_HEALTH := 100.0
const MAX_BOOST := 100.0
const MATCH_SECONDS := 8.0 * 60.0
const SCORE_LIMIT := 20
const SHIELD_RECHARGE_DELAY := 3.5
const SHIELD_RECHARGE_RATE := 24.0
const BOOST_RECHARGE_RATE := 20.0

var shield := MAX_SHIELD
var health := MAX_HEALTH
var boost := MAX_BOOST
var score := 0
var deaths := 0
var time_left := MATCH_SECONDS
var match_over := false
var last_damage_age := 999.0
var player: CharacterBody3D
var feed: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func reset_match() -> void:
	shield = MAX_SHIELD
	health = MAX_HEALTH
	boost = MAX_BOOST
	score = 0
	deaths = 0
	time_left = MATCH_SECONDS
	match_over = false
	last_damage_age = 999.0
	feed.clear()
	player = null
	stats_changed.emit()
	score_changed.emit()

func register_player(node: CharacterBody3D) -> void:
	player = node

func _process(delta: float) -> void:
	if match_over or get_tree().paused:
		return
	last_damage_age += delta
	time_left = maxf(0.0, time_left - delta)
	if last_damage_age >= SHIELD_RECHARGE_DELAY and shield < MAX_SHIELD:
		shield = minf(MAX_SHIELD, shield + SHIELD_RECHARGE_RATE * delta)
		stats_changed.emit()
	if not Input.is_action_pressed(&"boost") and boost < MAX_BOOST:
		boost = minf(MAX_BOOST, boost + BOOST_RECHARGE_RATE * delta)
		stats_changed.emit()
	if time_left <= 0.0:
		_finish_match(score >= SCORE_LIMIT)

func damage_player(amount: float, source := "RED ROBOT") -> void:
	if match_over or amount <= 0.0:
		return
	last_damage_age = 0.0
	var remaining := amount
	if shield > 0.0:
		var absorbed := minf(shield, remaining)
		shield -= absorbed
		remaining -= absorbed
	if remaining > 0.0:
		health = maxf(0.0, health - remaining)
	stats_changed.emit()
	if health <= 0.0:
		deaths += 1
		_push_feed("ELIMINATED BY %s" % source)
		_respawn_player()

func consume_boost(amount: float) -> bool:
	if match_over or boost <= 0.0:
		return false
	boost = maxf(0.0, boost - maxf(amount, 0.0))
	stats_changed.emit()
	return true

func record_robot_kill() -> void:
	if match_over:
		return
	score += 1
	_push_feed("RED ROBOT DISABLED  +1")
	score_changed.emit()
	if score >= SCORE_LIMIT:
		_finish_match(true)

func _respawn_player() -> void:
	shield = MAX_SHIELD
	health = MAX_HEALTH
	boost = MAX_BOOST
	stats_changed.emit()
	if not is_instance_valid(player):
		return
	var respawn_position: Variant = player.get("initial_position")
	if typeof(respawn_position) == TYPE_VECTOR3:
		player.global_position = respawn_position
	else:
		player.global_position = Vector3.ZERO
	player.velocity = Vector3.ZERO

func _push_feed(text: String) -> void:
	feed.push_front(text)
	if feed.size() > 4:
		feed.resize(4)
	feed_event.emit(text)

func _finish_match(won: bool) -> void:
	if match_over:
		return
	match_over = true
	match_ended.emit(won)
