extends Control
class_name BeaconIndicator

var target:Node2D = null

func init(in_target:Node2D) -> BeaconIndicator:
	target = in_target
	return self
