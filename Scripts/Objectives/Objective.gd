class_name Objective extends Resource


@export_category("READ ONLY")
@export var is_registered : bool = false
@export var time_since_active : float = 0.0:
	get: return Time.get_ticks_msec() - time_registered if is_registered else -1.0

var player : Player = null
var time_registered : float = 0.0

signal registered
signal deregistered
signal completed

var _debug_name : String :
	get: return "[b][" + resource_name + "(Objective)][/b]"


func reset() -> void:
	pass



func register(_player:Player) -> Test:
	if _player == null:
		print_rich(_debug_name," Register > ERR - No player defined! Ignoring.")
		return Test.new(false,"No player defined!")
	player = _player
	player.on_objective_lost.connect(deregister)
	
	time_registered = Time.get_ticks_msec()
	is_registered = true
	registered.emit()
	return Test.new(true,"")

func deregister() -> void:
	player = null
	player.on_objective_lost.disconnect(deregister)
	
	time_registered = 0.0
	is_registered = false
	deregistered.emit()


func check() -> Test:
	if !is_registered:
		return Test.new(false,"Objective is not registered!")
	if player == null:
		return Test.new(false,"No player defined!")
	return Test.new(true,"")
