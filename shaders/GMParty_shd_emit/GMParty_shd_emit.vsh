attribute vec2 in_Position;	// (particle vertex index, particle setting slot)

varying float v_vSlot;				// particle setting slot (X, Y, Z, COL, ..)
varying float v_vIndex;				// relative particle index (index + offset)
varying float v_vIndexAbsolute;		// absolute particle index (index)

uniform vec2 u_uIndexOffset;	// (index offset, max)
uniform vec3 u_uSize;			// tex, slot, grid

vec2 getPosition(in float _pos) {
	return vec2(mod(_pos, u_uSize.y), floor(_pos / u_uSize.y));
}

vec2 getSlot(in float _slot) {
	return vec2(mod(_slot, u_uSize.z), floor(_slot / u_uSize.z)) * u_uSize.y;
}

void main() {
	v_vIndexAbsolute = in_Position.x;
	v_vIndex = mod(in_Position.x + u_uIndexOffset.x, u_uIndexOffset.y);
	v_vSlot = in_Position.y;
	
	vec2 calculated_pos = getPosition(v_vIndex) + getSlot(v_vSlot);
    vec4 object_space_pos = vec4(calculated_pos + vec2(1.0), 0.0, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
	gl_PointSize = 1.0;
}
