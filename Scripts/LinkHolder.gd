class_name LinkHolder extends Node


signal on_link_clicked(pin)


#region Internal variables

var _debug_name : String :
	get: return "[b][" + name + "][/b]"

#endregion



#region Create evidence

func create_link(_pin1:Pin,_pin2:Pin) -> LinkTest:
	
	# Ignore if either pin is at max links
	if _pin1.full:
		print_rich("CanCreateLink > Pin '",_pin1.name,"' is at max links, choose again")
		return Test.new(false, "Pin '"+_pin1.name+"' at max links")
	if _pin2.full:
		print_rich("CanCreateLink > Pin '"+_pin2.name+"' is at max links, choose again")
		return Test.new(false, "Pin '"+_pin2.name+"' at max links")
	
	# Ignore if first pin is clicked again
	if _pin1 == _pin2:
		print_rich("CanCreateLink > Same pin clicked, choose again")
		return Test.new(false, "Same pin clicked")
	
	# Ignore if pins are already linked
	if _pin1.is_linked_to_pin(_pin2):
		print_rich("CanCreateLink > Pins already linked, choose again")
		return Test.new(false, "Pins already linked")
	
	# Ignore if pins are on the same evidence
	if _pin1.evidence == _pin2.evidence:
		print_rich("CanCreateLink > Pins on same evidence, choose again")
		return Test.new(false, "Pins on same evidence")
	
	
	var _new_link = Link.new(_pin1,_pin2)
	add_child(_new_link)
	_new_link.on_click_link.connect(on_link_clicked.emit.bind(_new_link))
	return LinkTest.new(true,"",_new_link)
	






#endregion
