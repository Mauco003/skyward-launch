class_name RocketData
extends Resource

@export_group("Mass")
@export var name: String = "Default Rocket"
@export var mass_dry: float = 15.0 # kg
@export var mass_wet: float = 25.0 # kg
@export var center_of_mass: Vector3 = Vector3.ZERO
@export var inertia_tensor: Vector3 = Vector3(10.0, 10.0, 1.0) # Inertia around X, Y, Z

@export_group("Algorithms")
@export var burn_time: float = 3.5 # seconds
@export var average_thrust: float = 800.0 # N
@export var thrust_curve: Curve # Built-in visual curve editor for thrust over time

@export_group("Aerodynamics")
@export var reference_area: float = 0.012 # m^2 (frontal area)
@export var cd_curve: Curve3D # Drag coefficient (Cd) relative to Mach number or Angle of Attack
