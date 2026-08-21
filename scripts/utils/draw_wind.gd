extends Node
@onready var line_2d: Line2D = $Line2D
@onready var wind: Wind = $"../Wind"
@onready var rocket = $"../Rocket"

func draw_curve_line(samples: int = 50) -> void:
	var points = PackedVector2Array()
	var max_alt = wind.max_altitude
	
	var size = get_viewport().get_visible_rect().size;
	var graph_width = size.x;
	var graph_height = size.y;
	
	var _screen_offset = Vector2(0, 0) # Baseline origin (X, Y)
	var step_size = 1/ float(samples);
	var step = 0;
	
	wind.randomize();
	
	for i in range(samples):
		var alt = step * max_alt
		wind.set_altitude(alt)
		
		# Position X horizontally, subtract Y to draw upward
		#var px = wind.magnitude / wind.max_magnitude * graph_width;
		var px = wind.elevation/TAU * graph_width;
		var py = step * graph_height;  # Scale factor if magnitude is small
		
		points.append(Vector2(px, py))
		step += step_size;
	
	#points.append(Vector2.ZERO);
	#points.append(Vector2(graph_width, graph_height));

	line_2d.points = points

func _ready() -> void:
	draw_curve_line();

func _process(_delta: float) -> void:
	pass
	#DebugDraw3d.vector(rocket.position, wind.velocity * 0.5, Color.CYAN);
