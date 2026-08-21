class_name AeroLogger
extends Node

# Buffers
var time_log: Array[float] = []
var alpha_tot_log: Array[float] = []
var mach_log: Array[float] = []
var phi_log: Array[float] = []

# Force coefficients [CA, CY, CN]
var ca_log: Array[float] = []
var cy_log: Array[float] = []
var cn_log: Array[float] = []

# Moment coefficients [Cl, Cm, Cn] (or roll, pitch, yaw)
var cl_log: Array[float] = []
var cm_log: Array[float] = []
var c_n_mom_log: Array[float] = []

func log_step(
	alpha_tot: float,
	mach: float,
	phi: float,
	cf_raw: Vector3, # coeffs[0] -> (CA, CY, CN)
	cm_raw: Vector3  # coeffs[1] -> (Cl, Cm, Cn)
) -> void:
	time_log.append(Time.get_ticks_msec() / 1000.0)
	alpha_tot_log.append(alpha_tot)
	mach_log.append(mach)
	phi_log.append(phi)
	
	ca_log.append(cf_raw.x)
	cy_log.append(cf_raw.y)
	cn_log.append(cf_raw.z)
	
	cl_log.append(cm_raw.x)
	cm_log.append(cm_raw.y)
	c_n_mom_log.append(cm_raw.z)

func _format_array(arr: Array) -> String:
	return str(arr)

func _format_matrix_3xN(row1: Array[float], row2: Array[float], row3: Array[float]) -> String:
	var s1 = str(row1).trim_prefix("[").trim_suffix("]")
	var s2 = str(row2).trim_prefix("[").trim_suffix("]")
	var s3 = str(row3).trim_prefix("[").trim_suffix("]")
	return "[" + s1 + ";\n " + s2 + ";\n " + s3 + "]"

func dump_logs() -> void:
	var output: String = ""
	output += "time = " + _format_array(time_log) + ";\n"
	output += "alphaTot = " + _format_array(alpha_tot_log) + ";\n"
	output += "mach = " + _format_array(mach_log) + ";\n"
	output += "phi = " + _format_array(phi_log) + ";\n\n"
	
	# Row-major 3xN: Row 1 = CA, Row 2 = CY, Row 3 = CN
	output += "% Force Coefficients: [CA; CY; CN]\n"
	output += "CF = " + _format_matrix_3xN(ca_log, cy_log, cn_log) + ";\n\n"
	
	# Row-major 3xN: Row 1 = Cl, Row 2 = Cm, Row 3 = Cn
	output += "% Moment Coefficients: [Cl; Cm; Cn]\n"
	output += "CM = " + _format_matrix_3xN(cl_log, cm_log, c_n_mom_log) + ";\n"
	
	print("\n========== AERODYNAMIC LOG DUMP ==========\n" + output + "==========================================\n")
	
	# Save to text file
	var file_path = "res://aero_log.txt"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(output)
		file.close()
		print("Aerodynamic log successfully written to: ", OS.get_user_data_dir() + "/aero_log.txt")
	else:
		printerr("Failed to open file at: ", file_path)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		dump_logs()
