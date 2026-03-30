class_name Spherecaster extends ShapeCast2D

## ---------------------------------------------
##
##
## NOTE > This isn't really a thing right now
##
##
## ---------------------------------------------

@export var max_distance : float = 50.0

@export_category("READ ONLY")
@export var evidence : Evidence = null
@export var has_collision : bool = false
@export var collision_point : Vector2 = Vector2.ZERO

signal evidence_found
signal evidence_lost

#func track(_evidence:Evidence) -> void:
	#if enabled:
		#enabled = false
		#await get_tree().physics_frame
	#evidence = _evidence
	#
	#clear_exceptions()
	#for e in get_tree().get_nodes_in_group("Evidence"):
		#print("e = ", e.name)
		#if e != evidence:
			#print(e.name," is not ",evidence.name)
			#for child in e.find_children("*","CollisionObject2D",true):
				#print("!!! child '",child,"' of ",e.name,"is a CollisionObject2D, adding to exceptions")
				#add_exception(child)
	#
	#tracking()


func tracking() -> void:
	enabled = true
	var draggable = evidence.draggable
	var direction = Vector2.ZERO
	
	# Do a single raycast to set initial positions
	# Assume we're hovering over the draggable
	#await get_tree().physics_frame
	#global_position = draggable.global_position 
	#target_position = to_local((get_global_mouse_position() - draggable.global_position)* max_distance)
	#if is_colliding():
		#collision_point = get_collision_point()
		#if !has_collision:
			#evidence_found.emit()
			#has_collision = true
	#elif has_collision:
		#evidence_lost.emit()
		#has_collision = false
	
	# Loop shapecasts until disabled
	while (enabled):
		if draggable.hovered:
			global_position = draggable.global_position 
			direction = (get_global_mouse_position() - draggable.global_position).normalized()
			target_position = to_local(global_position + (direction * max_distance))
		else:
			global_position = get_global_mouse_position()
			direction = (draggable.global_position - get_global_mouse_position()).normalized()
			target_position = to_local(global_position + (direction * max_distance))
		
		if is_colliding():
			collision_point = get_collision_point(0)
			if !has_collision:
				evidence_found.emit()
				has_collision = true
		elif has_collision:
			evidence_lost.emit()
			has_collision = false
		
		await get_tree().physics_frame
		
	


#func tracking() -> void:
	#enabled = true
	#var draggable = evidence.draggable
	#var direction = Vector2.ZERO
	#
	## Do a single raycast to set initial positions
	## Assume we're hovering over the draggable
	#await get_tree().physics_frame
	#global_position = draggable.global_position 
	#target_position = to_local((get_global_mouse_position() - draggable.global_position)* max_distance)
	#if is_colliding():
		#collision_point = get_collision_point()
		#if !has_collision:
			#evidence_found.emit()
			#has_collision = true
	#elif has_collision:
		#evidence_lost.emit()
		#has_collision = false
	#
	## Loop raycasts until disabled
	#while (enabled):
		#if draggable.hovered:
			#global_position = draggable.global_position 
			#direction = (get_global_mouse_position() - draggable.global_position).normalized()
			#target_position = to_local(global_position + (direction * max_distance))
		#else:
			#global_position = get_global_mouse_position()
			#direction = (draggable.global_position - get_global_mouse_position()).normalized()
			#target_position = to_local(global_position + (direction * max_distance))
		#
		#if is_colliding():
			#collision_point = get_collision_point()
			#if !has_collision:
				#evidence_found.emit()
				#has_collision = true
		#elif has_collision:
			#evidence_lost.emit()
			#has_collision = false
		#
		#await get_tree().physics_frame
		#
	#
