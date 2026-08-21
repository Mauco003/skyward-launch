## Collection of static quantities / types referred to flight of the rocket 
class_name Flight
extends RefCounted

enum Phase{
	## The rocket is armed and ready to fly
	READY,
	## The rocket is accelerating: engine is on
	THRUST,
	## The rocket is gaining altitude and decelerating
	COASTING,
	## Drogue chute has opened
	DROGUE,
	## Main chute has opened
	MAIN,
	## The rocket has reached ground
	LANDED
}
