extends Node
class_name IsaAtmosphere

@export var t0 = 288.15; 	# Temperature at sea level [K]
@export var p0 = 101325; 	# Pressure at sea level [Pa]
@export var rho0 = 1.225;   # Density at sea level [kg/m^3]
@export var a = 6.5*1e-3;   # Temperature coefficient vs altitude
@export var R = 8314.29/29; # Specific gas constant
@export var gamma = 1.4;	# Gas cp/cv ratio

# Reference gravity acceleration
var g0 = ProjectSettings.get("physics/3d/default_gravity");

var altitude: float
var temperature: float
var pressure: float
var speed_of_sound: float
var density: float

func set_altitude(alt: float) -> void:
	altitude = alt;
	
	temperature = t0 - a*altitude;
	pressure = p0 * (temperature/t0) ** (g0/(a*R));
	density = rho0 * (pressure/p0) * (t0/temperature);
	
	speed_of_sound = sqrt(gamma * R * temperature);
