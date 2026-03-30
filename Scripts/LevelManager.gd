class_name LevelManager extends Node2D

static var instance : LevelManager = null

@onready var player_prefab := preload("res://Assets/Scenes/player.tscn")
@onready var evidence_prefab := preload("res://Assets/Scenes/evidence.tscn")
@onready var pin_prefab := preload("res://Assets/Scenes/pin.tscn")
@onready var domain_tag := preload("res://Resources/Tags/Tag_Domain.tres")


@onready var buttons : Control = $CanvasLayer/MarginContainer/Buttons
@onready var player_holder : Node = $PlayerHolder
@onready var evidence_holder : Node = $EvidenceHolder
@onready var links_holder : Node = $LinksHolder
@onready var pins_holder : Node = $PinsHolder
@onready var fake_pin : Follower = $FakePin
@onready var fake_link : FakeLink = $FakeLink
@onready var raycaster : Raycaster = $Raycaster

@onready var helper_text : RichTextLabel = $CanvasLayer/MarginContainer/Rtl_HelperText
@onready var domain_text : RichTextLabel = $CanvasLayer/MarginContainer/Rtl_DomainText

@export var domains : Array[Tag] = []

#var _waiting_for_click := false

signal on_mouse_click
signal on_back_pressed

signal on_player_clicked(player)
signal on_evidence_clicked(evidence)
signal on_pin_clicked(pin)
signal on_link_clicked(pin)


var _debug_name : String :
	get: return "[b][" + name + "][/b]"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	instance = self
	
	# NOTE -> Only necessary if placed in editor
	for player:Player in player_holder.get_children():
		player.on_click_player.connect(on_player_clicked.emit.bind(player))
	
	
	# NOTE -> Only necessary if placed in editor
	for evidence:Evidence in evidence_holder.get_children():
		evidence.on_click_evidence.connect(on_evidence_clicked.emit.bind(evidence))
		#evidence.add_to_group("Evidence")
	
	# NOTE -> Only necessary if placed in editor
	for pin:Pin in pins_holder.get_children():
		pin.on_click_pin.connect(on_pin_clicked.emit.bind(pin))










#region Create functions


func create_player() -> Player:
	var _new_player : Player = player_prefab.instantiate()
	_new_player.setup()
	player_holder.add_child(_new_player)
	#_new_player.add_to_group("Players")
	return _new_player

func create_evidence() -> Evidence:
	var _new_evidence : Evidence = evidence_prefab.instantiate()
	_new_evidence.setup()
	evidence_holder.add_child(_new_evidence)
	_new_evidence.add_to_group("Evidence")
	for _tag in _new_evidence.tags:
		if has_domain(_tag).result:
			_new_evidence.add_tag(domain_tag)
			break
	return _new_evidence

func create_pin() -> Pin:
	var _new_pin : Pin = pin_prefab.instantiate()
	_new_pin.setup()
	_new_pin.add_to_group("Pins")
	#pins_holder.add_child(_new_pin) # pins live inside evidence normally
	return _new_pin

func create_link(pin1:Pin,pin2:Pin) -> Link:
	var _new_link = Link.new(pin1,pin2)
	links_holder.add_child(_new_link)
	return _new_link

#endregion

#region Domain functions

func add_domain(_tag:Tag) -> Test:
	if has_domain(_tag).result:
		print_rich(_debug_name," AddDomain > Tag '"+_tag.key+"="+str(_tag.value)+"' already present, cancelling")
		return Test.new(false,"Tag '"+_tag.key+"="+str(_tag.value)+"' already present")
	else:
		domains.append(_tag)
		_apply_domains()
		return Test.new(true,"")

func has_domain(_tag:Tag) -> Test:
	print_rich(_debug_name," HasDomain > Checking tag '"+_tag.key+"="+str(_tag.value)+"'...")
	if domains.has(_tag):
		print_rich(_debug_name," HasDomain > Found '"+_tag.key+"="+str(_tag.value)+"', returning true")
		return Test.new(true,"")
	
	print_rich(_debug_name," HasDomain > Did not find '"+_tag.key+"="+str(_tag.value)+"', returning false")
	return Test.new(false,"No matching results")

func _apply_domains() -> void:
	for evidence:Evidence in get_tree().get_nodes_in_group("Evidence"):
		if evidence.has_tag(domain_tag).result:
			continue
		for domain in domains:
			if evidence.has_tag(domain).result:
				evidence.add_tag(domain_tag)
				break
	
	# Change domain text
	var _domain_list : String 
	for domain in domains:
		_domain_list += str(domain.value) + " ("+domain.key+")"
	domain_text.text = "[b]Domains:[/b]  " + _domain_list


func _add_random_domain_on_button_press() -> void:
	var _index := randi() % 7
	var _tag : Tag = null
	
	print_rich(_debug_name," AddRandomDomain > Checking index '"+str(_index)+"'")
	match _index:
		0: _tag = load("res://Resources/Tags/Tag_Colour_Blue.tres")
		1: _tag = load("res://Resources/Tags/Tag_Colour_Green.tres")
		2: _tag = load("res://Resources/Tags/Tag_Colour_Purple.tres")
		3: _tag = load("res://Resources/Tags/Tag_Colour_Red.tres")
		4: _tag = load("res://Resources/Tags/Tag_Type_Item.tres")
		5: _tag = load("res://Resources/Tags/Tag_Type_Location.tres")
		6: _tag = load("res://Resources/Tags/Tag_Type_Person.tres")
	
	print_rich(_debug_name," AddRandomDomain > Adding new domain '"+_tag.key+"="+str(_tag.value)+"'")
	add_domain(_tag)
	
#endregion




#region Internal functions

func _unhandled_input(event: InputEvent) -> void:
	
	# Wait for escape key
	if event.is_action_pressed("back",false):
		on_back_pressed.emit()
	
	# Wait for mouse click
	#if !_waiting_for_click: return
	if event is InputEventMouseButton and event.is_action_pressed("mouse_left_click"):
		on_mouse_click.emit()



func _signal_fired_before_escape(_signal: Signal) -> Array:
	print("waiting for ", _signal)
	# Pass signals as an array
	var result = await Utilities.await_any([_signal,on_back_pressed])
	if result[0] == _signal:
		print("[LevelManager] Signal fired before escape! Params = ", result[1])
		return [true,result[1]]
	else:
		print("[LevelManager] Escape fired before signal!")
		return [false]


func _set_helper_text(text:String) -> void:
	helper_text.text = text
	helper_text.visible = text != ""

func _reset() -> void:
	_set_helper_text("")
	buttons.visible = true
	fake_pin.visible = false
	fake_link.visible = false
	raycaster.enabled = false
	Utilities.disconnect_all_from_signal(raycaster.collider_found)
	Utilities.disconnect_all_from_signal(raycaster.collider_lost)
	Utilities.disconnect_all_from_signal(raycaster.evidence_found)
	Utilities.disconnect_all_from_signal(raycaster.evidence_lost)

#endregion



#region Evidence functions 

func _create_evidence_on_button_press() -> void:
	buttons.visible = false
	_set_helper_text("Click to place an evidence")
	#_waiting_for_click = true
	
	var signal_result = await _signal_fired_before_escape(on_mouse_click)
	if signal_result[0]:
		var _new_evidence : Evidence = create_evidence()
		_new_evidence.global_position = get_global_mouse_position()
		_new_evidence.on_click_evidence.connect(on_evidence_clicked.emit.bind(_new_evidence))
	
	#_waiting_for_click = false
	_reset()

func _create_evidence_repeating_on_button_press() -> void:
	buttons.visible = false
	_set_helper_text("Click to place evidence (repeat until escape)")
	
	var signal_result : Array
	var _evidence : Evidence = null
	while (true):
		# Cancel if escape is pressed
		signal_result = await _signal_fired_before_escape(on_mouse_click)
		if !signal_result[0]:
			_reset()
			return
		
		_evidence = create_evidence()
		_evidence.global_position = get_global_mouse_position()
		_evidence.on_click_evidence.connect(on_evidence_clicked.emit.bind(_evidence))
	
	_reset()

func _hide_evidence_on_button_press() -> void:
	buttons.visible = false
	_set_helper_text("Select an evidence to hide")
	
	# Select an evidence
	var signal_result : Array
	var _evidence : Evidence = null
	while (true):
		# Cancel if escape is pressed
		signal_result = await _signal_fired_before_escape(on_evidence_clicked)
		if !signal_result[0]:
			_reset()
			return
		_evidence = signal_result[1][0]
		
		#Ignore if the evidence is already hidden
		if _evidence.is_hidden:
			_set_helper_text("Evidence is already hidden, choose again")
			continue
		
		#Ignore if the pin is occupied
		if _evidence.occupied:
			_set_helper_text("Evidence is occupied, choose again")
			continue
		
		_evidence.is_hidden = true
		break
	
	_reset()


func _reveal_evidence_on_button_press() -> void:	
	buttons.visible = false
	_set_helper_text("Select an evidence to reveal")
	
	# Select an evidence
	var signal_result : Array
	var _evidence : Evidence = null
	while (true):
		# Cancel if escape is pressed
		signal_result = await _signal_fired_before_escape(on_evidence_clicked)
		if !signal_result[0]:
			_reset()
			return
		_evidence = signal_result[1][0]
		
		#Ignore if the evidence is already hidden
		if !_evidence.is_hidden:
			_set_helper_text("Evidence is already revealed, choose again")
			continue
		
		_evidence.is_hidden = false
		break
	
	_reset()



#endregion


#region Pin functions

func _create_pin_on_button_press() -> void:
	buttons.visible = false
	_set_helper_text("Click to place a pin")
	#_waiting_for_click = true
	fake_pin.follow()
	
	var signal_result = await _signal_fired_before_escape(on_mouse_click)
	if signal_result[0]:
		var _new_pin : Pin = create_pin()
		pins_holder.add_child(_new_pin)
		_new_pin.name = "Pin"
		_new_pin.on_click_pin.connect(on_pin_clicked.emit.bind(_new_pin))
		_new_pin.global_position = get_global_mouse_position()

	#_waiting_for_click = false
	_reset()


func _create_pin_on_evidence_on_button_press() -> void:
	buttons.visible = false
	_set_helper_text("Select an evidence to place pin on")
	
	# Select an evidence
	var signal_result : Array
	var _evidence : Evidence = null
	while (true):
		# Cancel if escape is pressed
		signal_result = await _signal_fired_before_escape(on_evidence_clicked)
		if !signal_result[0]:
			_reset()
			return
		_evidence = signal_result[1][0]
		
		#Ignore if evidence is hidden and already has 1 pin
		if _evidence.is_hidden && _evidence.pin_count >= 1:
			_set_helper_text("Hidden evidence has pin(s), choose again")
			continue
		
		#Ignore if the pin is at max links
		if _evidence.at_max_pins:
			_set_helper_text("Evidence is at max pins, choose again")
			continue
		break
	await get_tree().process_frame
	
	# Setup choosing placement for pin
	_set_helper_text("Choose where to place the pin")
	raycaster.track_evidence(_evidence)
	raycaster.evidence_found.connect(fake_pin.follow.bind(raycaster))
	raycaster.evidence_lost.connect(fake_pin.stop)
	
	# Wait for a successful raycast target
	while (true):
		# Cancel if escape is pressed
		signal_result = await _signal_fired_before_escape(on_mouse_click)
		if !signal_result[0]:
			break
		
		# Wait until mouse is near the border of evidence
		if !raycaster.has_collision:
			continue
		
		# Set pin position to border of evidence
		var _new_pin : Pin = create_pin()
		_new_pin.on_click_pin.connect(on_pin_clicked.emit.bind(_new_pin))
		_evidence.register_pin(_new_pin)
		#_evidence.pins_holder.add_child(_new_pin)
		#_evidence.draggable.on_moved.connect(_new_pin.draggable.on_moved.emit)
		#_new_pin.evidence = _evidence
		_new_pin.global_position = raycaster.collision_point
		break
	
	
	_reset()




#func _on_pin_click_debug() -> void:
	#print("[LevelManager] Pin clicked debug")

#endregion



#region Link functions

func _create_link_on_button_press() -> void:
	buttons.visible = false
	_set_helper_text("Click first pin")
	
	# Select a first pin
	var signal_result : Array
	var _pin1 : Pin = null
	while (true):
		# Cancel if escape is pressed
		signal_result = await _signal_fired_before_escape(on_pin_clicked)
		if !signal_result[0]:
			_reset()
			return
		_pin1 = signal_result[1][0]
		
		#Ignore if the pin is at max links
		if _pin1.full:
			_set_helper_text("Pin is at max links, choose again")
			continue
		break
	await get_tree().process_frame
	
	

	# Loop until we have a second pin
	_set_helper_text("Click second pin")
	fake_link.global_position = _pin1.global_position
	fake_link.follow()
	var _pin2 : Pin = null
	while (true):
		# Nominate a second pin candidate, or cancel if escape is pressed
		signal_result = await _signal_fired_before_escape(on_pin_clicked)
		if !signal_result[0]:
			_reset()
			return
		_pin2 = signal_result[1][0]
		
		# Ignore if the pin is at max links
		if _pin2.full:
			_set_helper_text("Pin is at max links, choose again")
			continue
		# Ignore if first pin is clicked again
		if _pin2 == _pin1:
			_set_helper_text("Same pin clicked, choose again")
			print("[LevelManager] Same pin clicked, ignoring.")
			continue
		# Ignore if its already linked here
		if _pin1.is_linked_to_pin(_pin2):
			_set_helper_text("Pin already linked here, choose again")
			print("[LevelManager] Pin already linked here, ignoring.")
			continue
		# Ignore if its on the same evidence
		if _pin1.evidence == _pin2.evidence:
			_set_helper_text("Pins are on same evidence, choose again")
			print("[LevelManager] Pin is on the same evidence, ignoring.")
			continue
		
		# Create a link to the second pin
		var _new_link = create_link(_pin1,_pin2)
		_new_link.on_click_link.connect(on_link_clicked.emit.bind(_new_link))
		
		_reset()
		break


func _create_link_by_aim_on_button_press() -> void:
	buttons.visible = false
	_set_helper_text("Click starting pin")
	
	# Select a first pin
	var _distance : float = 500.0
	var signal_result : Array
	var _pin1 : Pin = null
	while (true):
		# Cancel if escape is pressed
		signal_result = await _signal_fired_before_escape(on_pin_clicked)
		if !signal_result[0]:
			_reset()
			return
		_pin1 = signal_result[1][0]
		
		#Ignore if the pin is at max links
		if _pin1.full:
			_set_helper_text("Pin is at max links, choose again")
			continue
		break
	await get_tree().process_frame
	
	# Setup aiming the link
	_set_helper_text("Choose where to place the pin")
	raycaster.aim_link(_pin1,_distance)
	
	# Setup fake pin rules
	raycaster.collider_found.connect(func():
		if raycaster.collision_object is Evidence: fake_pin.follow(raycaster)
		else: fake_pin.stop()
	)
	raycaster.collider_lost.connect(fake_pin.stop)
	
	# Setup fake link rules
	fake_link.global_position = _pin1.global_position
	raycaster.collider_found.connect(func():
		if raycaster.collision_object is Pin:
			if raycaster.collision_object.is_linked_to_pin(_pin1):
				fake_link.valid = false
			elif raycaster.collision_object.evidence == _pin1.evidence:
				fake_link.valid = false
			else:
				fake_link.valid = true
			fake_link.follow(raycaster.collision_object, 0.0)
			return
		elif raycaster.collision_object is Evidence:
			fake_link.valid = true
		else:
			fake_link.valid = false
		fake_link.follow(raycaster,0.0)
	)
	raycaster.collider_lost.connect(func():
		fake_link.follow(null, _distance)
		fake_link.valid = false
	)
	
	# Set initial fake link position
	fake_link.follow(null, _distance)
	fake_link.valid = false

	
	# Wait for a successful raycast target
	_set_helper_text("Aim for an evidence!")
	var _pin2 : Pin = null
	var _evidence : Evidence = null
	while (true):
		# Cancel if escape is pressed
		signal_result = await _signal_fired_before_escape(on_mouse_click)
		if !signal_result[0]:
			break
		
		# Wait until mouse is near the border of evidence
		if !raycaster.has_collision:
			continue
		
		# Check if we have collided with evidence
		if raycaster.collision_object is Evidence:
			_evidence = raycaster.collision_object
			
			#Ignore if evidence is hidden and already has 1 pin
			if _evidence.is_hidden && _evidence.pin_count >= 1:
				_set_helper_text("Hidden evidence has pin(s), choose again")
				continue
			
			# Ignore if the evidence is at max pins
			if _evidence.at_max_pins:
				_set_helper_text("Evidence is at max links, choose again")
				continue
		
			# Create pin at collision point on evidence
			var _new_pin : Pin = create_pin()
			_new_pin.on_click_pin.connect(on_pin_clicked.emit.bind(_new_pin))
			_evidence.register_pin(_new_pin)
			_new_pin.global_position = raycaster.collision_point
			_pin2 = _new_pin
		
		# Check if we have collided with evidence
		if raycaster.collision_object is Pin:
			_pin2 = raycaster.collision_object
			# Ignore if the pin is at max links
			if _pin2.full:
				_set_helper_text("Pin is at max links, choose again")
				continue
			# Ignore if first pin is clicked again
			if _pin2 == _pin1:
				_set_helper_text("Same pin clicked, choose again")
				print("[LevelManager] Same pin clicked, ignoring.")
				continue
			# Ignore if its already linked here
			if _pin1.is_linked_to_pin(_pin2):
				_set_helper_text("Pin already linked here, choose again")
				print("[LevelManager] Pin already linked here, ignoring.")
				continue
			# Ignore if its on the same evidence
			if _pin1.evidence == _pin2.evidence:
				_set_helper_text("Pins are on same evidence, choose again")
				print("[LevelManager] Pin is on the same evidence, ignoring.")
				continue
		
		# Create a link to the second pin
		var _new_link = create_link(_pin1,_pin2)
		_new_link.on_click_link.connect(on_link_clicked.emit.bind(_new_link))
		
		break
		
	_reset()
	


func _thread_link_on_button_press() -> void:
	buttons.visible = false	
	_set_helper_text("Click the owning player")
	
	# Save the player, or cancel if escape is pressed
	var signal_result = await _signal_fired_before_escape(on_player_clicked)
	if !signal_result[0]:
		_reset()
		return
	var _player : Player = signal_result[1][0]
	await get_tree().process_frame
	
	# Select a link
	_set_helper_text("Select a link")
	var _link : Link = null
	while (true):
		# Cancel if escape is pressed
		signal_result = await _signal_fired_before_escape(on_link_clicked)
		if !signal_result[0]:
			_reset()
			return
		_link = signal_result[1][0]
		
		# Ignore if the link is already threaded
		if _link.is_threaded:
			_set_helper_text("Link is already threaded, choose again")
			continue
		
		_link.thread(_player)
		break
	
	_reset()
	

func _unthread_link_on_button_press() -> void:
	buttons.visible = false
	_set_helper_text("Click the owning player")
	
	# Select a link
	_set_helper_text("Select a link")
	var signal_result : Array
	var _link : Link = null
	while (true):
		# Cancel if escape is pressed
		signal_result = await _signal_fired_before_escape(on_link_clicked)
		if !signal_result[0]:
			_reset()
			return
		_link = signal_result[1][0]
		
		# Ignore if the link is already unthreaded
		if !_link.is_threaded:
			_set_helper_text("Link is already unthreaded, choose again")
			continue
		
		_link.thread(null)
		break
	
	_reset()
	

#endregion


#region Player functions


func _create_player_on_button_press() -> void:
	buttons.visible = false
	_set_helper_text("Click to place an player")
		
	var signal_result = await _signal_fired_before_escape(on_mouse_click)
	if signal_result[0]:
		var _new_player : Player = create_player()
		#_new_player.player_colour = Color.from_hsv(randf() * 360,1,1)
		_new_player.global_position = get_global_mouse_position()
		_new_player.on_click_player.connect(on_player_clicked.emit.bind(_new_player))
		
	_reset()

func _create_player_on_pin_on_button_press() -> void:
	buttons.visible = false
	_set_helper_text("Click the starting pin for the player")
	
	# Select a first pin
	var signal_result : Array
	var _pin1 : Pin = null
	while (true):
		# Cancel if escape is pressed
		signal_result = await _signal_fired_before_escape(on_pin_clicked)
		if !signal_result[0]:
			_reset()
			return
		_pin1 = signal_result[1][0]
		
		#Ignore if the pin is at max links
		if _pin1.occupied:
			_set_helper_text("Pin is occupied, choose again")
			continue
		break
	
	var _new_player : Player = create_player()
	#_new_player.player_colour = Color.from_hsv(randf() * 360,1,1)
	_new_player.on_click_player.connect(on_player_clicked.emit.bind(_new_player))
	_new_player.move_to_pin(_pin1)
	#_new_player._occupy_pin(_pin1)
	
	_reset()


func _move_player_on_button_press() -> void:
	buttons.visible = false
	_set_helper_text("Click player to move")
	
	# Save the player, or cancel if escape is pressed
	var signal_result = await _signal_fired_before_escape(on_player_clicked)
	if !signal_result[0]:
		_reset()
		return
	var _player : Player = signal_result[1][0]
	await get_tree().process_frame
	
	# Loop until we choose a pin
	_set_helper_text("Click pin to move to")
	var _target_pin : Pin = null
	while (true):
		# Save the pin, or cancel if escape is pressed
		signal_result = await _signal_fired_before_escape(on_pin_clicked)
		if !signal_result[0]:
			_reset()
			return
		_target_pin = signal_result[1][0]
		
		# Keep trying until player was able to move to a pin
		var test = _player.move_to_pin(_target_pin)
		if !test.result:
			_set_helper_text(test.reason + ", pick again")
			continue
		
		_reset()
		break




func _backtrack_player_on_button_press(repeat_until_esc : bool = false) -> void:
	buttons.visible = false
	_set_helper_text("Click player to backtrack")
	
	# Save the player, or cancel if escape is pressed
	var signal_result = await _signal_fired_before_escape(on_player_clicked)
	if !signal_result[0]:
		_reset()
		return
	var _player : Player = signal_result[1][0]
	await get_tree().process_frame
	
	# Loop until we choose a pin
	helper_text.text = "Click linked pin to backtrack to"
	var _target_pin : Pin = null
	while (true):
		# Save the pin, or cancel if escape is pressed
		signal_result = await _signal_fired_before_escape(on_pin_clicked)
		if !signal_result[0]:
			_reset()
			return
		_target_pin = signal_result[1][0]
		
		# Keep trying until player was able to move to a pin
		var test = _player.backtrack(_target_pin)
		if !test.result:
			_set_helper_text(test.reason + ", pick again")
			continue
		
		if repeat_until_esc:
			helper_text.text = "Click linked pin to backtrack to (repeat until escape)"
		else:
			_reset()
			return
	
#endregion



#region Objectives
var _chain : ChainObjective = load("res://Resources/Objectives/example_chain_objective.tres")
func _test_chain_on_button_press() -> void:
	buttons.visible = false
	_set_helper_text("Click player to test chain")
	
	#_chain = load("res://Resources/Objectives/example_chain_objective.tres")
	_chain.reset()
	
	# Save the player, or cancel if escape is pressed
	var signal_result = await _signal_fired_before_escape(on_player_clicked)
	if !signal_result[0]:
		_reset()
		return
	var _player : Player = signal_result[1][0]
	await get_tree().process_frame
	
	
	# Save the starting pin, or cancel if escape is pressed
	_set_helper_text("Click pin to begin chain")
	signal_result = await _signal_fired_before_escape(on_pin_clicked)
	if !signal_result[0]:
		_reset()
		return
	
	var _target_pin : Pin = signal_result[1][0]
	await get_tree().process_frame
	
	
	# Setup the chain
	_chain.register(_player)
	_chain.assign_pin(_target_pin)
	
	
	# Loop until chain is completed, or cancel if escape is pressed
	_set_helper_text("Click pin to continue chain")
	var _test : Test
	while (true):
		# Save the pin, or cancel if escape is pressed
		signal_result = await _signal_fired_before_escape(on_pin_clicked)
		if !signal_result[0]:
			_reset()
			return
		_target_pin = signal_result[1][0]
		
		# Keep trying until a worthy pin was selected
		_test = _chain.assign_pin(_target_pin)
		if !_test.result:
			_set_helper_text(_test.reason + ", pick again")
			continue
		
		# Keep going until chain is completed
		_test = _chain.check()
		if !_test.result:
			_set_helper_text(_test.reason + ", click pin to continue chain")
			continue
		
		print_rich(_debug_name,"[b] YOU DID IT BIG DOG [/b]")
		
		_reset()
		return


#endregion
