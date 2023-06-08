#define EARLY_Z
#define MULTIPLE_ATLAS_TEXTURES

varying vec2 v_vTexcoord;				// uv
varying vec4 v_vColor;					// rgba
varying vec2 v_vImage;					// image_index, stage_index
varying float v_vSkip;

uniform sampler2D ugmpTexture0;
uniform sampler2D ugmpTexture1;
uniform sampler2D ugmpTexture2;
uniform sampler2D ugmpTexture3;

vec4 sample(float texid, in vec2 uvs) {
	if (texid <= 0.0) {
		return texture2D( ugmpTexture0, uvs );
	}
	else if (texid <= 1.0) {
		return texture2D( ugmpTexture1, uvs );
	}
	else if (texid <= 2.0) {
		return texture2D( ugmpTexture2, uvs );
	}
	else {
		return texture2D( ugmpTexture3, uvs );
	}
}

void main() {
	#ifndef EARLY_Z
	if (ceil(v_vSkip) > 0.5) {
		discard;
	}
	#endif
	
	#ifdef MULTIPLE_ATLAS_TEXTURES
    gl_FragColor = v_vColor * sample(v_vImage.y, v_vTexcoord);
	#else
	gl_FragColor = v_vColor * sample(ugmpTexture0, v_vTexcoord);
	#endif
	
	#ifdef EARLY_Z
	gl_FragColor *= (ceil(v_vSkip) > 0.0) ? 0.0 : 1.0;
	#endif
}
