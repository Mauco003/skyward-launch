extends Node3D

class DebugLine:
	var start: Vector3
	var end: Vector3
	var color: Color
	var time_left: float

	func _init(p_start: Vector3, p_end: Vector3, p_color: Color, p_duration: float) -> void:
		start = p_start
		end = p_end
		color = p_color
		time_left = p_duration

var _lines: Array[DebugLine] = []
var _immediate_mesh: ImmediateMesh
var _mesh_instance: MeshInstance3D

func _ready() -> void:
	# Keep debug rendering running regardless of parent transforms
	top_level = true
	
	_immediate_mesh = ImmediateMesh.new()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _immediate_mesh
	
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mesh_instance.material_override = mat
	
	add_child(_mesh_instance)

func _process(delta: float) -> void:
	if _lines.is_empty():
		_immediate_mesh.clear_surfaces()
		return
	
	_immediate_mesh.clear_surfaces()
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	var i := 0
	while i < _lines.size():
		var ln := _lines[i]
		
		# Draw vertices with their individual colors
		_immediate_mesh.surface_set_color(ln.color)
		_immediate_mesh.surface_add_vertex(ln.start)
		_immediate_mesh.surface_set_color(ln.color)
		_immediate_mesh.surface_add_vertex(ln.end)
		
		# Countdown duration (0.0 = clear on the next frame)
		ln.time_left -= delta
		if ln.time_left <= 0.0:
			_lines.remove_at(i)
		else:
			i += 1
			
	_immediate_mesh.surface_end()

# --- Public API ---

## Draws a single line between two 3D points
func line(from: Vector3, to: Vector3, color: Color = Color.WHITE, duration: float = 0.0) -> void:
	_lines.append(DebugLine.new(from, to, color, duration))

## Draws a vector starting from a position with a directional arrow head
func vector(start: Vector3, vec: Vector3, color: Color = Color.RED, duration: float = 0.0) -> void:
	if vec.is_zero_approx():
		return
	
	var target := start + vec
	line(start, target, color, duration)
	
	# Compute perpendicular basis for the arrow head
	var dir := vec.normalized()
	var ortho := dir.cross(Vector3.UP)
	if ortho.is_zero_approx():
		ortho = dir.cross(Vector3.RIGHT)
	ortho = ortho.normalized()
	
	var head_len := minf(vec.length() * 0.25, 0.4)
	var p1 := target - dir * head_len + ortho * (head_len * 0.4)
	var p2 := target - dir * head_len - ortho * (head_len * 0.4)
	
	line(target, p1, color, duration)
	line(target, p2, color, duration)

## Draws a wireframe oriented bounding box (or axis-aligned box)
func box(center: Vector3, size: Vector3, color: Color = Color.BLUE, duration: float = 0.0) -> void:
	var half := size * 0.5
	var c := [
		center + Vector3(-half.x, -half.y, -half.z), # 0
		center + Vector3( half.x, -half.y, -half.z), # 1
		center + Vector3( half.x, -half.y,  half.z), # 2
		center + Vector3(-half.x, -half.y,  half.z), # 3
		center + Vector3(-half.x,  half.y, -half.z), # 4
		center + Vector3( half.x,  half.y, -half.z), # 5
		center + Vector3( half.x,  half.y,  half.z), # 6
		center + Vector3(-half.x,  half.y,  half.z)  # 7
	]
	
	# Bottom face
	line(c[0], c[1], color, duration); line(c[1], c[2], color, duration)
	line(c[2], c[3], color, duration); line(c[3], c[0], color, duration)
	# Top face
	line(c[4], c[5], color, duration); line(c[5], c[6], color, duration)
	line(c[6], c[7], color, duration); line(c[7], c[4], color, duration)
	# Vertical pillars
	line(c[0], c[4], color, duration); line(c[1], c[5], color, duration)
	line(c[2], c[6], color, duration); line(c[3], c[7], color, duration)

## Draws an AABB directly
func aabb(box_bounds: AABB, color: Color = Color.CYAN, duration: float = 0.0) -> void:
	box(box_bounds.get_center(), box_bounds.size, color, duration)

## Draws a 3-axis wireframe sphere (equator, prime meridian, and horizontal cross-section)
func sphere(center: Vector3, radius: float = 0.5, color: Color = Color.YELLOW, duration: float = 0.0, segments: int = 16) -> void:
	var step := TAU / float(segments)
	
	for i in range(segments):
		var a1 := i * step
		var a2 := (i + 1) * step
		
		var cos1 := cos(a1) * radius
		var sin1 := sin(a1) * radius
		var cos2 := cos(a2) * radius
		var sin2 := sin(a2) * radius
		
		# XY circle
		line(center + Vector3(cos1, sin1, 0.0), center + Vector3(cos2, sin2, 0.0), color, duration)
		# XZ circle (Ground plane)
		line(center + Vector3(cos1, 0.0, sin1), center + Vector3(cos2, 0.0, sin2), color, duration)
		# YZ circle
		line(center + Vector3(0.0, cos1, sin1), center + Vector3(0.0, cos2, sin2), color, duration)

## Clears all active debug draw requests immediately
func clear() -> void:
	_lines.clear()
	_immediate_mesh.clear_surfaces()
