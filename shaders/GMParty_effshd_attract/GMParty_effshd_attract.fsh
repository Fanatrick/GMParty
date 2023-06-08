uniform vec3 ugmpSize;					// (texsize, slotsize, gridsize)
uniform float ugmpForce;				// 
uniform int ugmpForceAbsolute;			// 

uniform int ugmpShapeType;				// passed via collider
uniform vec2 ugmpShapeDistMult;			//
uniform vec4 ugmpShapeCTX1;				//
uniform vec4 ugmpShapeCTX2;				//
uniform vec4 ugmpShapeCTX3;				//
uniform sampler2D ugmpShapeCTXSampler;	//
uniform vec2 ugmpShapeCTXSamplerSize;	//
uniform vec4 ugmpShapeCTXSamplerUVs;	//

uniform vec2 ugmpParticleTypeRange;		//

varying vec2 v_vTexcoord;

vec4 lookup(in vec2 _uvs, in float _slot, in sampler2D _tex) {
	vec2 _offset = vec2(mod(_slot, ugmpSize.z), floor(_slot / ugmpSize.z)) * (1.0 / ugmpSize.z);
	return texture2D(_tex, _uvs + _offset);
}

//------------------------------------------------------------//
// Colliders
#define C_BOX			0
#define C_SPHERE		1
#define C_CYLINDER		2
#define C_PILL			3
#define C_TEX2D			4

vec3 fbox(vec3 _ppos, vec3 _start, vec3 _end, vec2 _minmax) {
	vec3 _center = (_start + _end) * 0.5;
	vec3 _sides = abs(_end - _start) * 0.5;
	vec3 _off = _ppos - _center;
	vec3 _absoff = abs(_off);
	vec3 _dist = vec3(
		clamp(_sides.x - _absoff.x, 0.0, _sides.x),
		clamp(_sides.y - _absoff.y, 0.0, _sides.y),
		clamp(_sides.z - _absoff.z, 0.0, _sides.z)
	);
	vec3 _vel =			vec3(_dist.x, 0.0, 0.0);
	_vel = mix(_vel,	vec3(0.0, _dist.y, 0.0), float(_dist.x > _dist.y));
	_vel = mix(_vel,	vec3(0.0, 0.0, _dist.z), float(_dist.y > _dist.z));
	
	return _vel * -sign(_off);
}
vec3 fsphere(vec3 _ppos, vec3 _spos, float _rad, vec2 _minmax) {
	vec3 _dpos = _spos - _ppos;
	float _dist = length(_dpos);
	return normalize(_dpos) * step(_dist, _rad) * mix(_minmax.y, _minmax.x, _dist / _rad);
}
vec3 fcylinder(vec3 _ppos, vec3 _start, vec3 _end, float _rad, vec2 _minmax) {
	vec3 _dpos = _end - _start;
	float _t = dot(_dpos, _ppos - _start) / dot(_dpos, _dpos);
	if (_t != clamp(_t, 0., 1.)) return vec3(0.0);
	float _dist = length(cross(_dpos, _start - _ppos)) / length(_dpos);
	return normalize(mix(_start, _end, _t) - _ppos) * step(_dist, _rad) * mix(_minmax.y, _minmax.x, _dist / _rad);
}
vec3 fpill(vec3 _ppos, vec3 _start, vec3 _end, float _rad, vec2 _minmax) {
	vec3 _dpos = _end - _start;
	float _t = dot(_dpos, _ppos - _start) / dot(_dpos, _dpos);
	float _dist = length(cross(_dpos, _start - _ppos)) / length(_dpos);
	if (_t < 0.0) _dist = distance(_ppos, _start);
	if (_t > 1.0) _dist = distance(_ppos, _end);
	return normalize(mix(_start, _end, clamp(_t, 0., 1.)) - _ppos) * step(_dist, _rad) * mix(_minmax.y, _minmax.x, _dist / _rad);
}
vec3 ftex2d(vec3 _ppos, vec3 _spos, vec4 _offs, vec4 _uvs, vec2 _scale, float _rot) {
	vec2 _line = (_ppos.xy - _spos.xy) * mat2(cos(_rot), -sin(_rot), sin(_rot), cos(_rot));
	vec2 _rpos = _spos.xy + _line;
	vec2 _tpos = (_rpos - (_spos.xy + _offs.xy)) / (_offs.zw - _offs.xy);
	vec2 _jump = -texture2D(ugmpShapeCTXSampler, vec2(mix(_uvs.x, _uvs.z, _tpos.x), mix(_uvs.y, _uvs.w, _tpos.y)) ).xy;
	_jump *= float( (clamp(_tpos.x, 0.0, 1.0) == _tpos.x) ) * float( (clamp(_tpos.y, 0.0, 1.0) == _tpos.y) );
	return vec3((_jump * mat2(cos(-_rot), -sin(-_rot), sin(-_rot), cos(-_rot))) * _scale, 0.0);
}

vec3 fhandle(vec3 _point, vec4 _ctx1, vec4 _ctx2, vec4 _ctx3, float _ddist) {
	if (ugmpShapeType == C_BOX) {
		return fbox(_point, _ctx1.xyz, _ctx1.xyz + _ctx2.xyz, ugmpShapeDistMult ) / mix(vec3(1.0), _ctx2.xyz * 0.5, float(_ddist <= 0.0));
	}
	else if (ugmpShapeType == C_SPHERE) {
		return fsphere(_point, _ctx1.xyz, _ctx1.w, ugmpShapeDistMult ) * mix(1.0, _ctx1.w, float(_ddist >= 1.0));
	}
	else if (ugmpShapeType == C_CYLINDER) {
		return fcylinder(_point, _ctx1.xyz, _ctx1.xyz + _ctx2.xyz, _ctx1.w, ugmpShapeDistMult ) * mix(1.0, _ctx1.w, float(_ddist >= 1.0));
	}
	else if (ugmpShapeType == C_PILL) {
		return fpill(_point, _ctx1.xyz, _ctx1.xyz + _ctx2.xyz, _ctx1.w, ugmpShapeDistMult ) * mix(1.0, _ctx1.w, float(_ddist >= 1.0));
	}
	else if (ugmpShapeType == C_TEX2D) {
		return ftex2d(_point, vec3(_ctx1.xy, 0.0), _ctx2, ugmpShapeCTXSamplerUVs, _ctx1.zw, ugmpShapeCTX3.x) / mix(vec3(1.0), vec3(ugmpShapeCTXSamplerSize * (ugmpShapeCTXSamplerUVs.zw - ugmpShapeCTXSamplerUVs.xy) * _ctx1.zw, 1.0), float(_ddist < 0.5)) * _ctx3.w;
	}
	return vec3(1.0);
}

void main() {
	vec2 position = floor(v_vTexcoord * ugmpSize.x);
	vec2 indexUVs = mod(position, ugmpSize.y) / ugmpSize.x;
	float index = position.x + position.y * ugmpSize.y;
	float slot = floor(v_vTexcoord.x * ugmpSize.z) + floor(v_vTexcoord.y * ugmpSize.z) * ugmpSize.z;
	
	vec4 pack = lookup(indexUVs, slot, gm_BaseTexture);
	
	vec4 plife = lookup(indexUVs, 0.0, gm_BaseTexture);
	vec3 ppos = lookup(indexUVs, 1.0, gm_BaseTexture).xyz;
	
	if (plife.w != clamp(plife.w, ugmpParticleTypeRange.x, ugmpParticleTypeRange.y)) {
		discard;
	}
	
	vec3 col = fhandle(ppos, ugmpShapeCTX1, ugmpShapeCTX2, ugmpShapeCTX3, 0.0);
	if (length(col) > 0.0) {
		float pmass = lookup(indexUVs, 15.0, gm_BaseTexture).x;
		float acc = ugmpForceAbsolute <= 0 ? ugmpForce/pmass : ugmpForce;
		pack.xyz += col * acc;
	}
	
    gl_FragColor = pack;
}
