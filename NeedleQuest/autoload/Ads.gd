extends Node
## AdsManager - fully isolated from gameplay.
## This is an abstraction layer: in this build rewarded ads are SIMULATED
## (they always succeed after a short delay). To integrate a real SDK
## (AdMob etc.), replace the body of show_rewarded() only - no other
## system touches ad logic.

signal rewarded_finished(success: bool)

var enabled: bool = true
var _busy: bool = false


func is_available() -> bool:
	return enabled and not _busy


## Shows a rewarded ad, then calls back with success=true/false.
func show_rewarded(callback: Callable) -> void:
	if not is_available():
		callback.call(false)
		return
	_busy = true
	# --- SIMULATION: pretend an ad played for 0.6s. ---
	var timer := get_tree().create_timer(0.6)
	timer.timeout.connect(func() -> void:
		_busy = false
		rewarded_finished.emit(true)
		callback.call(true)
	)
