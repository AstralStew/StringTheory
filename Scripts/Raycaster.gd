class_name Raycaster extends RayCast2D

@export var debugging : bool = false
@export var track_evidence_max_distance : float = 150.0

@export_category("READ ONLY")
@export var evidence : Evidence = null
@export var collision_object : Node2D = null
@export var has_collision : bool = false
@export var collision_point : Vector2 = Vector2.ZERO

signal evidence_found()
signal evidence_lost

signal collider_found()
signal collider_lost()



#region Aiming link

func aim_link(_starting_pin:Pin, _distance:float) -> void:
	if enabled:
		enabled = false
		await get_tree().physics_frame
	evidence = null
	
	# Add the starting pin's evidence + pins to exceptions
	clear_exceptions()
	if _starting_pin.evidence != null:
		var _evidence = _starting_pin.evidence
		for child in _evidence.find_children("*","CollisionObject2D",true):
			if debugging: print("!!! child '",child,"' of ",_evidence.name,"is a CollisionObject2D, adding to exceptions")
			add_exception(child)
	
	aiming_link(_starting_pin, _distance)
	

func aiming_link(_starting_pin:Pin, _distance:float) -> void:
	enabled = true
	var _direction = Vector2.ZERO
	
	# Loop raycasts until disabled
	while (enabled):
		
		global_position = _starting_pin.global_position
		_direction = (get_global_mouse_position() - _starting_pin.global_position).normalized()
		target_position = to_local(global_position + (_direction * _distance))
		
		if is_colliding():
			collision_point = get_collision_point()
			# If we haven't sent event yet or the collision object changed 
			if !has_collision || (collision_object != (get_collider() as CollisionObject2D).get_parent()):
				collision_object = (get_collider() as CollisionObject2D).get_parent()
				if debugging: print_rich("[color=green][b]Collision found! collision_object = ", collision_object.name)
				collider_found.emit()
				has_collision = true
		elif has_collision:
			collision_object = null
			if debugging: print_rich("[color=green][b]Collision lost.")
			collider_lost.emit()
			has_collision = false
		
		await get_tree().physics_frame
	


#region Tracking evidence

func track_evidence(_evidence:Evidence) -> void:
	if enabled:
		enabled = false
		await get_tree().physics_frame
	evidence = _evidence
	
	# Add all other evidence to exceptions
	clear_exceptions()
	for e in get_tree().get_nodes_in_group("Evidence"):
		if debugging: print("e = ", e.name)
		if e != evidence:
			if debugging: print(e.name," is not ",evidence.name)
			for child in e.find_children("*","CollisionObject2D",true):
				if debugging: print("!!! child '",child,"' of ",e.name,"is a CollisionObject2D, adding to exceptions")
				add_exception(child)
	
	tracking_evidence()
	

func tracking_evidence() -> void:
	enabled = true
	var draggable = evidence.draggable
	var direction = Vector2.ZERO
	
	# Do a single raycast to set initial positions
	# Assume we're hovering over the draggable
	await get_tree().physics_frame
	global_position = draggable.global_position 
	target_position = to_local((get_global_mouse_position() - draggable.global_position) * track_evidence_max_distance)
	if is_colliding():
		collision_point = get_collision_point()
		if !has_collision:
			evidence_found.emit()
			has_collision = true
	elif has_collision:
		evidence_lost.emit()
		has_collision = false
	
	# Loop raycasts until disabled
	while (enabled):
		if draggable.hovered:
			global_position = draggable.global_position 
			direction = (get_global_mouse_position() - draggable.global_position).normalized()
			target_position = to_local(global_position + (direction * track_evidence_max_distance))
		else:
			global_position = get_global_mouse_position()
			direction = (draggable.global_position - get_global_mouse_position()).normalized()
			target_position = to_local(global_position + (direction * track_evidence_max_distance))
		
		# Check for collisions
		if is_colliding():
			# Evidence - Save contact point and emit signal
			if (get_collider() as CollisionObject2D).get_parent().is_in_group("Evidence"):
				collision_point = get_collision_point()
				if !has_collision:
					evidence_found.emit()
					has_collision = true
		# Make sure we know we aren't colliding
			elif has_collision:
					evidence_lost.emit()
					has_collision = false
		elif has_collision:
			evidence_lost.emit()
			has_collision = false
		
		await get_tree().physics_frame
		

#endregion
