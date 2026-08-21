extends RigidBody3D

@export var thrust_force: float = 3000.0 # Force magnitude in Newtons
var current_phase: Flight.Phase = Flight.Phase.READY;
var coefficients: Coefficients = Coefficients.new();
var is_thrusting = false;

@onready var logger = $"../Logger";

@onready var atmosphere: IsaAtmosphere = $"../Atmosphere";
@onready var wind: Wind = $"../Wind";

@onready var cameras: Array[Camera3D] = [$Body/FPVCamera, $ThirdPersonCamera];
var active_camera_id = 0;

@onready var telemetry = %Telemetry;
var telemetry_data: TelemetryPacket = TelemetryPacket.new();

## Telemetry data
var mach: float = 0;

func _ready() -> void:
	pass
	#coefficients = Coefficients.new()
	#atmosphere.set_altitude(1000);
	#print(atmosphere.temperature)
	#print(atmosphere.pressure)
	#print(atmosphere.density)
	#print(atmosphere.speed_of_sound)
	#inertia = Vector3(0.1354, 21.3504, 21.3527);
	#print(transform.basis)

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_view"):
		active_camera_id += 1;
		active_camera_id = active_camera_id if active_camera_id < cameras.size() else 0;
		cameras[active_camera_id].current = true;
	
	if Input.is_action_just_pressed("launch") && \
		(current_phase == Flight.Phase.READY || current_phase == Flight.Phase.THRUST):
		
		# Default action bound to Spacebar
		is_thrusting = !is_thrusting;
		next_phase();
		print_debug("Current phase: ", current_phase);

	if is_thrusting:
		# Applies force upward relative to the rocket's local orientation
		var thrust_vector = transform.basis.x * thrust_force
		apply_central_force(thrust_vector)
	
	var quats_to_global = quaternion.normalized();
	var quats_to_local = quats_to_global.inverse();
	
	var velocity = quats_to_local * linear_velocity;
	var wind_velocity = quats_to_local * wind.velocity;
	
	var relative_velocity = velocity - wind_velocity;
	var a = atmosphere.speed_of_sound;
	
	var velocity_magnitude = relative_velocity.length();
	mach = velocity_magnitude / a;
	
	# Debug velocity vector
	DebugDraw3d.vector(position, quats_to_global * relative_velocity, Color.RED)
	DebugDraw3d.vector(position, wind.velocity * 0.5, Color.CYAN);

	#print("Global velocity: ", relative_velocity);

	var ap = get_alpha_phi(relative_velocity);

	#print("[alphaTot, phi] = ", ap);
	#print("[alphaTot, phi]2 = ", ap2, ";");
	
	# Retrieving aerodynamic coefficients
	var coeffs = coefficients.get_coeffs(ap[0], mach, ap[1], 0, 0);
	
	# Computing aerodynamic forces 
	var q = 0.5 * atmosphere.density * velocity_magnitude ** 2;
	var s = 0.25 * PI * coefficients.ref_l ** 2;
	
	# Convert to rocket reference frame (rotate by 90 deg along z)
	var cf = coeffs[0] * Vector3(-1, 1, -1); #rotated(Vector3(0, 0, 1), PI/2);
	var cm = coeffs[1] * Vector3(1, 1, 1); #rotated(Vector3(0, 0, 1), PI/2);
	
	var f: Vector3 = q*s*cf; # Multiply by force coefficients
	var m: Vector3 = q*s*cm*coefficients.ref_l; # Multiply by moment coefficients
	
	#print("Velocity: ", velocity_magnitude, " m/s");
	#print("Relative velocity axibod: ", relative_velocity_axibody);
	#print("mach = ", mach, ";");
	
	#print("[CA, CY, CN] = ", cf);
	#print("[cl, cm, cn] = ", cm);
	#print("Force: ", f);
	#print("Torque: ", m);
	
	apply_central_force(quats_to_global * f);
	apply_torque(quats_to_global * m);
	
	# Debugging torques
	#var torque_axibody_local = Vector3(m.x, 0.0, 0.0)
	#var torque_transversal_local = m - torque_axibody_local

	## 2. Transform to GLOBAL frame for 3D world drawing
	#var origin = global_position
	#var basis = global_transform.basis

	#var torque_axibody_world = basis * torque_axibody_local
	#var torque_transversal_world = basis * torque_transversal_local
	#var torque_total_world = basis * m
	#
	#DebugDraw3d.vector(position, torque_axibody_world, Color.SKY_BLUE)
	#DebugDraw3d.vector(position, torque_transversal_world, Color.ORANGE)
	#DebugDraw3d.vector(position, torque_total_world, Color.BLACK)
	#print("torque_axibody magnitude: ", torque_axibody.length())

static func get_alpha_phi(velocity: Vector3) -> Vector2:
	var u := velocity.x
	var v := velocity.y
	var w := velocity.z
	
	#print("Velocity (alphatot-phi frame): ", [u, v, w])
	
	var v_mag := velocity.length()
	
	# Guard against zero-division if the object is perfectly stationary
	if is_zero_approx(v_mag):
		return Vector2.ZERO
	
	# Clamp to [-1.0, 1.0] to avoid NaN from floating-point overflow in acos
	var alpha_tot = atan2(sqrt(v*v + w*w), u);
	var phi := atan2(v, w)
	
	return Vector2(alpha_tot, phi)

func _process(_delta: float) -> void:
	telemetry_data.altitude = position.y;
	telemetry_data.mach = mach;
	telemetry_data.phase = current_phase;
	telemetry_data.velocity = linear_velocity;
	
	telemetry.update(telemetry_data);

func next_phase() -> void:
	if current_phase < Flight.Phase.LANDED:
		current_phase = (current_phase + 1) as Flight.Phase;
