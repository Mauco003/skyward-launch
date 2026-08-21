extends Node
class_name Wind
## Class designed to export velocities in NUE frame
## (North, Up, East), as expressed in the godot reference frame

@export var max_magnitude: float = 10;
@export var max_altitude: float  = 4000;
@export var n_nodes: int = 5;

var azimuth_curve = Curve.new();
var elevation_curve = Curve.new();
var magnitude_curve = Curve.new();

var azimuth: float
var elevation: float
var magnitude: float

var velocity: Vector3 = Vector3.ZERO;

func _ready() -> void:
	# Set boundaries for curves
	elevation_curve.max_value = PI/2;
	elevation_curve.min_value = -PI/2;
	azimuth_curve.max_value = TAU;
	magnitude_curve.max_value = max_magnitude;
	
	azimuth_curve.max_domain = max_altitude;
	elevation_curve.max_domain = max_altitude;
	magnitude_curve.max_domain = max_altitude;
	
	# Generate random distribution just to init
	randomize();

## This function is mainly intended for inizialization and testing, as fully random
## wind generally does not reflect the real behaviout of wind.
## Distribution is uniform to keep complexity low.
func randomize() -> void:
	# Assumption of equispaced nodes wrt altitude
	
	var step_size:float = 1 / float(n_nodes);
	var h: float = 0.; # Height normalized on max_altitude
	
	for i in range(n_nodes):
		azimuth_curve.add_point(Vector2(h, randf() * TAU));
		elevation_curve.add_point(Vector2(h, randf() * PI - PI/2));
		magnitude_curve.add_point(Vector2(h, randf() * max_magnitude));
		
		h += step_size * max_altitude;
	
	azimuth_curve.bake();
	elevation_curve.bake();
	magnitude_curve.bake();

func from_data() -> void:
	print("TODO: Feature not yet implemented");
	pass

func set_altitude(altitude: float) -> void:
	azimuth    = azimuth_curve.sample_baked(altitude);
	elevation  = elevation_curve.sample_baked(altitude);
	magnitude  = magnitude_curve.sample_baked(altitude);

	velocity[0] = -magnitude * cos(azimuth) * cos(elevation); # North (X)
	velocity[1] = -magnitude * sin(elevation);                # Up (Y)
	velocity[2] = -magnitude * sin(azimuth) * cos(elevation); # East (Z)
