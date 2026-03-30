class_name Utilities


## This function awaits the first signal to fire among the ones provided
##[br]Returns an array where - 
##[br]    0 is the signal returned and
##[br]    1->n are the params of the original signal
static func await_any(signals:Array[Signal]) -> Signal:
	var worker = RefCounted.new()
	worker.add_user_signal("result")
		
	for _signal in signals:
		_signal.connect(
			func(...params):
				worker.emit_signal("result",_signal,params),
				CONNECT_ONE_SHOT
		)
	
	return Signal(worker, "result")


static func disconnect_all_from_signal(_signal:Signal):
	for dict in _signal.get_connections():
		_signal.disconnect(dict.callable)
