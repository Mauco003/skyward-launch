extends Node
## The purpose of this script is to manage / update world related
## data, i.e: update atmosphere data

@onready var atmosphere = %Atmosphere;
@onready var wind = %Wind;
@onready var rocket = $"../Rocket";

@onready var compass = %Compass

## Rocket starting altitude. Used to calculate altitude a.m.s.l.
@export var initial_altitude = 0;

var altitude_amsl: float;
var altitude_agl: float;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	atmosphere.set_altitude(rocket.position.y);
	wind.set_altitude(rocket.position.y);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	altitude_agl = rocket.position.y;
	altitude_amsl = altitude_agl + initial_altitude;
	
	# Atmosphere altitude is defined amsl to correctly compute ISA air
	atmosphere.set_altitude(altitude_amsl);
	# Wind altitude is defined agl
	wind.set_altitude(rocket.position.y);
	
	var rocket_axis = rocket.transform.basis.x;
	DebugDraw3d.vector(rocket.position, rocket_axis, Color.GREEN_YELLOW);
	var hdg = atan2(rocket_axis.z, rocket_axis.x);
	
	compass.update(hdg)
