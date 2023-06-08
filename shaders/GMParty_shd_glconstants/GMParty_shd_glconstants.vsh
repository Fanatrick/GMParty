attribute vec3 in_Position;                  // (x,y,z)
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec2 v_vTexcoord;
varying float v_vVTF;

uniform sampler2D u_uSamplerVTF;

float VTFSupported() {
	float _lookup = ceil(texture2D(u_uSamplerVTF, vec2(0.5)).r * 255.);
	return floor(float(_lookup == 98.));
}

void main() {
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
	
	v_vTexcoord = in_Position.xy;
	v_vVTF = VTFSupported();
}
