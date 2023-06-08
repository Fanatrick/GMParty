varying vec2 v_vTexcoord;

uniform vec3 ugmpSrcSize;
uniform vec3 ugmpDestSize;
uniform vec2 ugmpOffset;

vec2 getPosition(in float _pos, vec3 _sizes) {
	return vec2(mod(_pos, _sizes.y), floor(_pos / _sizes.y)) / _sizes.x;
}

vec2 getSlot(in float _slot, vec3 _sizes) {
	return vec2(mod(_slot, _sizes.z), floor(_slot / _sizes.z)) / _sizes.z;
}

precision highp float;

void main() {
	vec2 ppos = floor(v_vTexcoord * ugmpDestSize.x);
	float pindex = mod(ppos.x, ugmpDestSize.y) + mod(ppos.y, ugmpDestSize.y) * ugmpDestSize.y;
	float pslot = floor(ppos.x / ugmpDestSize.y) + floor(ppos.y / ugmpDestSize.y) * ugmpDestSize.z;
	
	float pmax = ugmpSrcSize.y * ugmpSrcSize.y;
	if (pindex != clamp(pindex, 0.0, ugmpOffset.y)) {
		discard;
	}
	vec2 uvs = getPosition(mod(pmax + pindex + ugmpOffset.x - ugmpOffset.y, pmax), ugmpSrcSize) + getSlot(pslot, ugmpSrcSize);
    gl_FragColor = texture2D( gm_BaseTexture, uvs );
}
