# RocketTelemetryUI.gd (attached to CanvasLayer or root Control)
extends PanelContainer

@onready var alt_label: Label = $VBoxContainer/Altitude
@onready var mach_label: Label = $VBoxContainer/Mach
@onready var phase_label: Label = $VBoxContainer/Phase

func update(data: TelemetryPacket) -> void:
	alt_label.text =   "ALT    %8.1f m" % data.altitude
	mach_label.text =  "MACH   %.2f" % data.mach;
	phase_label.text = "PHASE: %s" % Flight.Phase.find_key(data.phase);
	
	queue_redraw();
