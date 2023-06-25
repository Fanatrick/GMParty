varying vec2 v_vTexcoord;

uniform vec2 ugmpTexsize;

void main() {
	vec2 coord = floor(v_vTexcoord * ugmpTexsize);
	
	vec2 jump = texture2D( gm_BaseTexture, v_vTexcoord).xy;
	
	jump = mix(jump, coord, float(distance(jump, coord) < 1.0));
	
	gl_FragColor = vec4(jump - coord, 1.0, 1.0);
}
