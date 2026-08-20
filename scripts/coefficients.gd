class_name Coefficients
extends Node
# Coefficients - Load and manages coefficients
#
# coefficients are stored under assets/rockets/<rocket_name>/aeroCoefficients.bin
#
# The binary file is stored as follows
#   - ID,     char[4],  file identifier
#   - DIMS,   uint8[4], dimension sizes NALPHA, NMACH, ...
#
#   - ALPHA,  single[NALPHA]
#   - MACH,   single[NMACH]
#   - PHI,    single[NPHI]
#   - ABK,    single[NABK]
# 
#   - L       single[1], reference length (rocket diameter)
#   - XCG     single[1], reference xcg
# 
#   - COEFFS, single[6, NALPHA * NMACH * NPHI * NABK]
#
#   NOTE: The six coefficients are [CA, CY, CN, Cl, Cm, Cn], i.e. forces on
#         [x y z] and moments along [x y z] axes.
#         Check help of Coefficient class in msa toolkit for more info
#
#	NOTE: The reference system is as follows:
#	- x axibody, positive towards rear
#	- z aligned with an arbitrary reference  fin
#   - y to form a right handed tern

@export var rocket_name: String = "hydra";
#@onready var coeffsFile: PackedFloat32Array = preload("res://assets/rockets/hydra/aeroCoefficients.bin");
var nalpha: int = 0;
var nmach: int = 0;
var nphi: int = 0;
var nabk: int = 0;

var alpha: PackedFloat32Array;
var mach: PackedFloat32Array;
var phi: PackedFloat32Array;
var abk: PackedFloat32Array;

var ref_l: float;
var ref_xcg: float;

var data: PackedFloat32Array;

# Called when the node enters the scene tree for the first time.
func _init() -> void:
	var fp = FileAccess.open("res://assets/rockets/hydra/aeroCoefficients.bin", FileAccess.READ);
	
	var check = fp.get_buffer(4).get_string_from_ascii();
	if check != "AERO":
		push_error("Invalid file format. Try re-exporting using exportCoefficients under scripts/matlab");
		return;
	
	# Assuming 4 dimensions
	# Dimensions are alpha, mach, phi, abk
	#var dims: Array[int] = [0, 0, 0, 0];

	# WARNING: Do not alter the order of the following lines,
	# 		   As file reading is sequential.
	# Loading data sizes
	nalpha = fp.get_8();
	nmach = fp.get_8();
	nphi = fp.get_8();
	nabk = fp.get_8();

	# Loading data axes
	alpha = fp.get_buffer(4 * nalpha).to_float32_array();
	mach = fp.get_buffer(4 * nmach).to_float32_array();
	phi = fp.get_buffer(4 * nphi).to_float32_array();
	abk = fp.get_buffer(4 * nabk).to_float32_array();
	
	ref_l = fp.get_float()
	ref_xcg = fp.get_float();
	
	# Loading coefficients - 4 bytes * 6 coeffs * N data points
	data = fp \
		.get_buffer(4 * 6 * nalpha * nmach * nphi * nabk) \
		.to_float32_array();
	
	#print(get_by_idx(0, 0, 0, 0))
	#print(get_coeffs(0, 0, 0, 0, 0))
	#print(get_coeffs(0.0436, 0.2, 0, 0.3, 0))
	#print(get_coeffs(0.0436, 0.2, 0.6981, 0.3, 0))
	#print(get_coeffs(0.0436, 0.2, 2.4435, 0.3, 0))
	#print(get_coeffs(0.0436, 0.2, 2.4435, 0.3, 0.1))

func get_by_idx(ialpha: int, imach: int, iphi: int, iabk: int) -> PackedFloat32Array:
	var idx = ialpha + \
			  imach*nalpha + \
			  iphi*nalpha*nmach + \
			  iabk*nalpha*nmach*nphi;
		
	return data.slice(idx*6, (idx+1)*6);

func get_coeffs(x_alpha: float, x_mach: float, x_phi: float, x_abk: float, delta_xcg:float) -> Array[Vector3]:
	x_phi = wrapf(x_phi, 0, TAU);
	
	var alpha_int = get_idx(alpha, x_alpha, nalpha);
	var mach_int = get_idx(mach, x_mach, nmach);
	var phi_int = get_idx_modular(phi, x_phi, nphi);
	var abk_int = get_idx(abk, x_abk, nabk);
	
	var ia = alpha_int[0];
	var im = mach_int[0];
	var ip = phi_int[0];
	var iabk = abk_int[0];
	
	var fa = alpha_int[1];
	var fm = mach_int[1];
	var fp = phi_int[1];
	var fabk = abk_int[1];
	
	# 3. Fin wrapping logic
	var n_wraps = phi_int[2];
	var delta_phi = n_wraps * phi[nphi-1];
	
	# Interpolation formula: https://math.stackexchange.com/questions/1342364/formula-for-n-dimensional-linear-interpolation
	var coeff: PackedFloat32Array;
	coeff.resize(6);
	coeff.fill(0.0);
	
	var sa: int = 0; 
	var sm: int = 0; 
	var sp: int = 0; 
	var sabk: int = 0
	
	for i in range(16):
		sa   = i % 2;
		sm   = (i/2) % 2; @warning_ignore("integer_division")
		sp   = (i/4) % 2; @warning_ignore("integer_division")
		sabk = (i/8) % 2; @warning_ignore("integer_division")
		
		var ffa: float = 1-fa if sa == 0 else fa;
		var ffm: float = 1-fm if sm == 0 else fm;
		var ffp: float = 1-fp if sp == 0 else fp;
		var ffabk: float = 1-fabk if sabk == 0 else fabk;
		
		var temp = get_by_idx(ia + sa, im + sm, ip + sp, iabk + sabk);
			
		for j in range(6):
			temp[j] *= ffa * ffm * ffp * ffabk
			coeff[j] += temp[j]; 
	
	# 5. Rotate lateral/directional coefficients back if wrapped
	if n_wraps > 0:
		var cos_d = cos(delta_phi)
		var sin_d = sin(delta_phi)

		var CY = coeff[1]
		var CN = coeff[2]
		var Cm = coeff[4]
		var Cn = coeff[5]
		
		# R * [CY; CN]
		coeff[1] = cos_d * CY - sin_d * CN
		coeff[2] = sin_d * CY + cos_d * CN
		
		# R' * [Cm; Cn] (this part was already correct)
		coeff[4] = cos_d * Cm + sin_d * Cn
		coeff[5] = -sin_d * Cm + cos_d * Cn
		
	# coeff[3] += (d / l) * 0.0 # Cl remains unchanged
	coeff[4] += (delta_xcg / ref_l) * coeff[2] # Cm depends on CN
	coeff[5] += (delta_xcg / ref_l) * coeff[1] # Cn depends on CY
	
	# Compute stability margin
	#var cfaTot = sin(x_phi)*coeff[1] + cos(x_phi)*(-coeff[2]);
	#var cmaTot = cos(x_phi)*coeff[4] - sin(x_phi)*coeff[5];
	#
	#var SM = cmaTot / cfaTot;
	#print("SM: ", SM);
	
	# Return vector of force coefficients and moment coefficients
	return [Vector3(coeff[0], coeff[1], coeff[2]), 
		 	Vector3(coeff[3], coeff[4], coeff[5])];

## This function returns the following:
## - Index of the lower boundary
## - Fraction of value inside boundaries
func get_idx(axes: PackedFloat32Array, x: float, n: int) -> Array:
	# Handle boundary conditions
	if x <= axes[0]:
		return [0, 0]
	
	if x >= axes[n-1]:
		return [n-2, 1]
	
	# Search for index
	# Linear search is performed, since axes are generally small in size
	
	var idx: int = 0;
	var fr: float = 0;
	
	for i in range(1, n):
		if x <= axes[i]:
			idx = i-1;
			fr = (x - axes[idx]) / (axes[idx+1] - axes[idx]);
			break;
	
	return [idx, fr];

## This function returns the following:
## - Index of the lower boundary
## - Fraction of value inside boundaries
## - Number of cycles for modular opearations. Default: 1
func get_idx_modular(axes: PackedFloat32Array, x: float, n: int) -> Array:
	var x_remainder = fposmod(x, axes[n-1]);
	
	# Add small offset to compensate for floating point error 
	var n_wraps = floor(x / axes[n-1] + 1e-5);
	
	var output = get_idx(axes, x_remainder, n)
	output.append(n_wraps);
	
	return output;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
