varying vec2 v_vTexcoord;

uniform vec2 ugmpTexsize;
uniform float ugmpFactor;

float getHeight(vec2 uvs) {
	return texture2D( gm_BaseTexture, uvs ).x * ugmpFactor;
}

void main() {
	vec3 px = vec3(1.0 / ugmpTexsize, 0.0);
	vec2 uvs = v_vTexcoord;
	
    float height = getHeight(uvs);
    
	float lh = getHeight(uvs - px.xz);
    float rh = getHeight(uvs + px.xz);
    float th = getHeight(uvs - px.zy);
    float bh = getHeight(uvs + px.zy);

    vec3 gradx = vec3(px.xz, (rh - lh) );
    vec3 grady = vec3(px.zy, (bh - th) );

    vec3 normal = normalize(cross(grady, gradx));
	
	gl_FragColor = vec4(normal, height);
}
