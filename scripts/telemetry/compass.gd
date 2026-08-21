extends Panel

@export var fov: float = PI / 2.0 
var current_heading: float = 0.0

func _ready() -> void:
	clip_contents = true

func update(heading: float) -> void:
	current_heading = wrapf(heading, 0, TAU)
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var center_x: float = w * 0.5
	var font: Font = ThemeDB.fallback_font
	
	for i in range(72):
		var angle: float = i * (TAU / 72.0)
		var diff: float = wrapf(angle - current_heading + PI, 0, TAU) - PI
		
		if abs(diff) <= fov * 0.5:
			var x: float = center_x + (diff / (fov * 0.5)) * (w * 0.5)
			var is_cardinal: bool = (i % 18 == 0)
			var tick_h: float = h * 0.4 if is_cardinal else h * 0.2
			
			draw_line(Vector2(x, h - tick_h), Vector2(x, h), Color.WHITE, 2.0)
			
			if is_cardinal:
				var texts: Array[String] = ["N", "E", "S", "W"]
				var text: String = texts[i / 18]
				var text_w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16).x
				draw_string(font, Vector2(x - text_w * 0.5, h - tick_h - 5), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
