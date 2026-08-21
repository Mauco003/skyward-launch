extends Node
## The purpose of this script is to manage / update world related
## data, i.e: update atmosphere data

@onready var atmosphere = %Atmosphere;
@onready var wind = %Wind;
@onready var rocket = $"../Rocket";

@onready var compass = %Compass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	atmosphere.set_altitude(rocket.position.y);
	wind.set_altitude(rocket.position.y);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	atmosphere.set_altitude(rocket.position.y);
	wind.set_altitude(rocket.position.y);
	
	var rocket_axis = rocket.transform.basis.x;
	DebugDraw3d.vector(rocket.position, rocket_axis, Color.GREEN_YELLOW);
	var hdg = atan2(rocket_axis.z, rocket_axis.x);
	
	compass.update(hdg)
