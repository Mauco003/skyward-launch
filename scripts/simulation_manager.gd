extends Node
## The purpose of this script is to manage / update world related
## data, i.e: update atmosphere data

@onready var atmosphere = $"../Atmosphere";
@onready var wind = $"../Wind";
@onready var rocket = $"../Rocket";

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	atmosphere.set_altitude(rocket.position.y);
	wind.set_altitude(rocket.position.y);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	atmosphere.set_altitude(rocket.position.y);
	wind.set_altitude(rocket.position.y);
