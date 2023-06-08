varying vec2 v_vTexcoord;

uniform vec2 ugmpTexsize;
uniform float ugmpOffset;

void main() {
    vec2 px = 1.0 / ugmpTexsize;
	
	vec2 thisc = v_vTexcoord * ugmpTexsize;
	float min_dist = 65536.0;
	vec2 new_coord = vec2(0.0);
	
	vec4 nb;
	float dist;
	for(float i = -1.; i <= 1.; i ++) {
		for(float j = -1.; j <= 1.; j ++) {
			nb = texture2D( gm_BaseTexture, v_vTexcoord + px * vec2(i,j) * ugmpOffset);
			dist = distance(nb.xy, thisc.xy);
			if (dist < (min_dist * float(length(nb.xy) > 0.0))) {
				new_coord = nb.xy;
				min_dist = dist;
			}
		}
	}
	
	gl_FragColor = vec4(new_coord, 0.0, 0.0);
}
