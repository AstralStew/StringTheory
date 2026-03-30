class_name Draggable extends Area2D

@export var can_drag := false

var hovered = false
var mouse_in = false
var dragging = false

var _debug_name : String :
	get: return "{" + str(Time.get_ticks_msec()) + "} [" + get_parent().name + "/Draggable]"


signal on_click

signal on_moved


#region Internal functions

func _unhandled_input(event: InputEvent) -> void:
	if dragging:
		#print(_debug_name, " got unhandled input")
		if event is InputEventMouseButton and event.is_action_released("mouse_left_click"):
			print(_debug_name, " Stopped dragging.")
			dragging = false
		
		if event is InputEventMouseMotion:
			(get_parent() as Node2D).position += event.relative / ZoomableCamera.current_zoom
			on_moved.emit()
	

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	
	#hovered = event is InputEventMouseMotion
	if event is InputEventMouseButton and event.is_action_pressed("mouse_left_click"):
		
		print(_debug_name, " got input event")
		on_click.emit()
		if !dragging and can_drag:
			print(_debug_name, " Started dragging...")
			dragging=true
		#get_viewport().set_input_as_handled()


func _on_mouse_entered() -> void:
	hovered = true

func _on_mouse_exited() -> void:
	hovered = false


#endregion
