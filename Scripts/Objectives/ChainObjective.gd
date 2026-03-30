class_name ChainObjective extends Objective

@export var required_tags : Dictionary[Tag,int] = {}
@export var required_length : int = 0
@export var requires_exact_length : bool = false
@export var requires_exact_tag_amounts : bool = false


@export_category("READ ONLY")
var last_pin : Pin = null
var saved_links : Array[Link] = []
var saved_evidence : Array[Evidence] = []
@export var saved_tags : Dictionary[Tag,int] = {}
@export var length : int = 0


func reset() -> void:
	last_pin = null
	saved_links = []
	saved_evidence = []
	saved_tags = {}
	length = 0

func check() -> Test:
	var _test = super.check()
	if !_test.result:
		return Test.new(false,_test.reason)
	
	# Make sure we meet the required chain length 
	if requires_exact_length && length != required_length:
		return Test.new(false,"Chain not the exact required length ("+str(length)+"!="+str(required_length)+")")
	elif length < required_length:
		return Test.new(false,"Chain less than required length ("+str(length)+"<"+str(required_length)+")")
	
	# Make sure we have all the required tags
	var _match := false
	for required_tag in required_tags:
		# Check if the tag is even present 
		if !saved_tags.has(required_tag):
			return Test.new(false,"Could not find required tag '"+required_tag.key+"="+required_tag.value+"'")
		# Check if enough of the tag is present
		if requires_exact_tag_amounts && (saved_tags.get(required_tag) != required_tags[required_tag]):
			return Test.new(false,"Not exact amount of required tag '"+required_tag.key+"="+str(required_tag.value)+"' ("+str(saved_tags.get(required_tag))+"!="+str(required_tags[required_tag])+")")
		elif !requires_exact_tag_amounts && (saved_tags.get(required_tag) < required_tags[required_tag]):
			return Test.new(false,"Not enough of required tag '"+required_tag.key+"="+str(required_tag.value)+"' ("+str(saved_tags.get(required_tag))+"<"+str(required_tags[required_tag])+")")
		
	
	completed.emit()
	
	return Test.new(true,"")


func check_pin(_pin:Pin) -> Test:
	
	# Check its not the same pin
	if _pin == last_pin:
		print(_debug_name,"CheckPin > Picked the same pin again, returning false")
		return Test.new(false,"That's the same pin")
	
	# Check its linked to the last pin
	if !_pin.is_linked_to_pin(last_pin):
		print(_debug_name,"CheckPin > New pin not linked to last pin, returning false")
		return Test.new(false,"Not linked to last pin")
	
	# Check we haven't already used that link
	if saved_links.has(_pin.get_link_to_pin(last_pin)):
		print(_debug_name,"CheckPin > Link from new pin to last pin already used, returning false")
		return Test.new(false,"Link already used")
	
	# Check that link is threaded by this player
	if _pin.get_link_to_pin(last_pin).threaded_by != player:
		print(_debug_name,"CheckPin > Link from new pin to last pin not threaded by this player, returning false")
		return Test.new(false,"Link not in your thread")
	
	return Test.new(true,"")



func assign_pin(_pin:Pin) -> Test:
	
	var _test : Test
	
	# (Skip all this if no pin assigned yet)
	if last_pin != null:
		
		# Make sure the pin is able to be used
		_test = check_pin(_pin)
		if !_test.result:
			print(_debug_name,"AssignPin > Pin check failed, returning false")
			return Test.new(false,_test.reason)
		
		# Save the link to this pin
		saved_links.append(_pin.get_link_to_pin(last_pin))
	

	# (Skip all this if pin isn't on an evidence)
	var _evidence = _pin.evidence
	if _evidence != null:
		
		# Save the evidence
		if !saved_evidence.has(_evidence):
			saved_evidence.append(_evidence)
			print(_debug_name,"AssignPin > Adding evidence '",_evidence.name,"'")
			print(_debug_name,"AssignPin > Saved evidence = ", saved_evidence)
		
		# Don't check tags if we're hidden (since player wouldn't know)
		if !_evidence.is_hidden:
			# Increment the number of each tag we've saved
			for tag:Tag in _evidence.tags:
				if saved_tags.has(tag): saved_tags[tag] = saved_tags[tag] + 1
				else: saved_tags[tag] = 1
				print(_debug_name,"AssignPin > Adding tag '",tag.resource_name,"'")
				print(_debug_name,"AssignPin > Tag '",tag.resource_name,"' = ", saved_tags[tag])
	
	length += 1
	last_pin = _pin
	
	print(_debug_name,"AssignPin > Length =",length,", last_pin = ",last_pin)
	
	return Test.new(true,"")
