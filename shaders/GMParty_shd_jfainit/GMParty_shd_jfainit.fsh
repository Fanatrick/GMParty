varying vec2 v_vTexcoord;

uniform vec2 ugmpTexsize;
uniform float ugmpCutoff;

void main() {
    float alp = texture2D(gm_BaseTexture, v_vTexcoord).a;
	
	vec2 pos = floor(v_vTexcoord * ugmpTexsize) * step(alp, ugmpCutoff);
	gl_FragColor = vec4(pos, 0.0, 1.0);
	//if (alp < ugmpCutoff) {
	//	discard;
	//}
}
