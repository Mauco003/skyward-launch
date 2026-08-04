extends RigidBody3D

enum phases{
	READY,
	THRUST,
	COASTING,
	DROGUE,
	MAIN,
	LANDED
}

@export var thrust_force: float = 1000.0 # Force magnitude in Newtons
var current_phase: phases = phases.READY;
var is_thrusting = false;

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("launch") && \
		(current_phase == phases.READY || current_phase == phases.THRUST):
		
		# Default action bound to Spacebar
		is_thrusting = !is_thrusting;
		next_phase();
		print_debug("Current phase: ", current_phase);

	if is_thrusting:
		# Applies force upward relative to the rocket's local orientation
		var thrust_vector = transform.basis.x * thrust_force
		apply_central_force(thrust_vector)
		
func next_phase() -> void:
	if current_phase < phases.LANDED:
		current_phase+=1;
