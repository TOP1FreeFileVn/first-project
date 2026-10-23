shader_type canvas_item;

// Waves a flag cloth that hangs from its left (pole) edge. The pole side stays still;
// the fly end swings most. `phase` keeps neighbouring flags out of step.
uniform float amplitude = 3.0;   // pixels at the fly end
uniform float speed = 3.2;
uniform float waves = 1.6;       // ripples across the cloth
uniform float phase = 0.0;
uniform float hoist_u = 0.1;     // UV x of the pole edge

void vertex() {
	float along = clamp((UV.x - hoist_u) / (1.0 - hoist_u), 0.0, 1.0);
	float w = sin(TIME * speed + phase - along * waves * 6.2832);
	VERTEX.y += w * amplitude * along;
	VERTEX.x -= abs(w) * amplitude * 0.35 * along * along;
}
