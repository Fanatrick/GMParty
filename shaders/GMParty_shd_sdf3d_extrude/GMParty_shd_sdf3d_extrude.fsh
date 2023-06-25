varying vec2 v_vTexcoord;

uniform vec2 ugmpSdf3dSize;
uniform vec3 ugmpSdf3dVolume;

vec4 sdf3dSample(vec3 pos) {
	vec3 vol = ugmpSdf3dVolume;
	if(	(clamp(pos.x, 0.0, vol.x) != pos.x)
	||	(clamp(pos.y, 0.0, vol.y) != pos.y)
	||	(clamp(pos.z, 0.0, vol.z) != pos.z)) {
		return vec4(0.0);
	}
	float size = ugmpSdf3dSize.x;
	float index = pos.x + pos.y * (vol.x) + pos.z * (vol.y*vol.x);
	vec2 uvs = vec2(mod(index, (size) ), floor(index / (size) )) / size;
	return texture2D(gm_BaseTexture, uvs);
}

float countNB(vec3 pos) {
	float c = 0.;
	float m = 0.;
	float d = 0.;
	float s = 0.;
	for(float i = -1.; i <= 1.; i ++) {
		for(float j = -1.; j <= 1.; j ++) {
			for(float k = -1.; k <= 1.; k ++) {
				m = (abs(i)+abs(j)+abs(k));
				if (m <= 0. || m >= 4.) {
					continue;
				}
				s = float(length(sdf3dSample(pos + vec3(i,  j, k)).xyz) > 0.0);
				c += s;
				d += s * float(m == 1.);
			}
		}
	}
	return c;
}

void main() {
	vec2 spos = floor(v_vTexcoord * ugmpSdf3dSize);
	float index = spos.x + spos.y * ugmpSdf3dSize.x;
	vec3 fpos;
	fpos.z = floor(index / (ugmpSdf3dVolume.y * ugmpSdf3dVolume.x));
	fpos.y = floor((index - fpos.z * ugmpSdf3dVolume.y * ugmpSdf3dVolume.x) / ugmpSdf3dVolume.x);
	fpos.x = mod(index, ugmpSdf3dVolume.x);
	
	gl_FragColor = texture2D(gm_BaseTexture, v_vTexcoord);
	
	float nb = countNB(fpos);
	if (gl_FragColor.a <= 0.0) {
		gl_FragColor = vec4(fpos, 1.0) * float(nb > 1.0);
	}
	
	if (gl_FragColor.a>0.5) {
		gl_FragColor = vec4(0.0);
	} else {
		gl_FragColor = vec4(fpos, 1.0);
	}
	
}
