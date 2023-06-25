varying vec2 v_vTexcoord;

uniform sampler2D ugmp_sdf3dSampler;
uniform vec2 ugmp_sdf3dSize;
uniform vec3 ugmp_sdf3dVolume;

uniform float u_slice;

vec4 sdf3dSample(vec3 pos) {
	vec3 vol = ugmp_sdf3dVolume;
	if(	(clamp(pos.x, 0.0, vol.x) != pos.x)
	||	(clamp(pos.y, 0.0, vol.y) != pos.y)
	||	(clamp(pos.z, 0.0, vol.z) != pos.z)) {
		return vec4(0.0);
	}
	float size = ugmp_sdf3dSize.x;
	float index = pos.x + pos.y * (vol.x) + pos.z * (vol.y*vol.x);
	vec2 uvs = vec2(mod(index, (size) ), floor(index / (size) )) / size;
	return texture2D(gm_BaseTexture, floor(uvs*size) / size);
}

void main() {
    //gl_FragColor.xyz = sdf3dSample(vec3(0.0, 0.0, 0.0) + vec3(u_slice, floor(v_vTexcoord * ugmp_sdf3dVolume.yz) ) ).rgb * (1.0 / ugmp_sdf3dVolume);
	gl_FragColor = sdf3dSample(vec3(0.0, 0.0, 0.0) + vec3(u_slice, floor(v_vTexcoord * ugmp_sdf3dVolume.yz) ) ) * vec4(1.0 / ugmp_sdf3dVolume, 1.0);
	//gl_FragColor = sdf3dSample(vec3(0.0, 0.0, 0.0) + vec3(floor(v_vTexcoord * ugmp_sdf3dVolume.xy), u_slice) );
	gl_FragColor = sdf3dSample(vec3(0.0, 0.0, 0.0) + vec3(u_slice, floor(v_vTexcoord * ugmp_sdf3dVolume.yz)) );
	
	gl_FragColor.xyz = 0.5 + (gl_FragColor.xyz)*0.1;
	//gl_FragColor.xyz = (gl_FragColor.xyz)*.015;
	
	gl_FragColor.a = 1.0;
}
