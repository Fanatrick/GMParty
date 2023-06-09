uniform vec3 ugmpSize;					// (texsize, slotsize, gridsize)
uniform ivec4 ugmpOPC;
uniform vec4 ugmpREG0;
uniform vec4 ugmpREG1;
uniform vec4 ugmpREG2;
uniform vec4 ugmpREG3;
uniform vec4 ugmpREG4;
uniform vec4 ugmpREG5;

uniform int ugmpShapeType;				// passed via collider
uniform vec2 ugmpShapeDistMult;			//
uniform vec4 ugmpShapeCTX1;				//
uniform vec4 ugmpShapeCTX2;				//
uniform vec4 ugmpShapeCTX3;				//
uniform vec4 ugmpShapeCTX4;				//
uniform sampler2D ugmpShapeCTXSampler;	//
uniform vec2 ugmpShapeCTXSamplerSize;	//
uniform vec4 ugmpShapeCTXSamplerUVs;	//

uniform vec2 ugmpParticleTypeRange;		//

varying vec2 v_vTexcoord;

vec4 lookup(in vec2 _uvs, in float _slot, in sampler2D _tex) {
	vec2 _offset = vec2(mod(_slot, ugmpSize.z), floor(_slot / ugmpSize.z)) * (1.0 / ugmpSize.z);
	return texture2D(_tex, _uvs + _offset);
}

vec4 sdf3dSample(vec3 pos, vec2 _tsize, vec3 _volume) {
	if(	(clamp(pos.x, 0.0, _volume.x) != pos.x)
	||	(clamp(pos.y, 0.0, _volume.y) != pos.y)
	||	(clamp(pos.z, 0.0, _volume.z) != pos.z)) {
		return vec4(0.0);
	}
	float size = _tsize.x;
	float index = pos.x + pos.y * (_volume.x) + pos.z * (_volume.y*_volume.x);
	vec2 uvs = vec2(mod(index, (size) ), floor(index / (size) )) / size;
	return texture2D(ugmpShapeCTXSampler, uvs);
}

vec3 rotQuat(vec3 vector, vec4 quat) {
	vec3 t = 2.0 * cross(quat.xyz, vector);
	return (vector + quat.w * t + cross(quat.xyz, t));
}
vec4 mulQuat(vec4 a, vec4 b) {
	return vec4(
		a.w * b.xyz + b.w * a.xyz + cross(a.xyz, b.xyz),
		a.w * b.w - dot(a.xyz, b.xyz)
	);
}
vec4 getRotQuat(float angle, vec3 axis) {
	float halff = radians(angle) * .5;
	return vec4(normalize(axis) * sin(halff), cos(halff));
}
vec4 getRotQuatXYZ(float pitch, float yaw, float roll) {
	vec4 pitchQuaternion = getRotQuat(pitch, vec3(1.0, 0.0, 0.0) );
	vec4 yawQuaternion = getRotQuat(yaw, vec3(0.0, 1.0, 0.0) );
	vec4 rollQuaternion = getRotQuat(roll, vec3(0.0, 0.0, 1.0) );
	return mulQuat(pitchQuaternion, mulQuat(rollQuaternion, yawQuaternion));
}
vec3 rotateXYZ(vec3 point, vec3 thetas) {
	return rotQuat(point, getRotQuatXYZ(thetas.x, thetas.y, thetas.z));
}
vec3 rotateXYZConjugate(vec3 point, vec3 thetas) {
	vec4 q = getRotQuatXYZ(thetas.x, thetas.y, thetas.z);
	return rotQuat(point, vec4(-q.xyz, q.w));
}

//------------------------------------------------------------//
// Colliders
#define C_BOX			0
#define C_SPHERE		1
#define C_CYLINDER		2
#define C_PILL			3
#define C_TEX2D			4
#define C_FAUX_TEX3D	5

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
vec3 ftexf3d(vec3 _ppos, vec3 _spos, vec3 _start, vec3 _end, vec2 _tsize, vec3 _volume, vec3 _rot, vec3 _mult) {
	vec3 _line = rotateXYZ(_ppos - _spos, -_rot);
	vec3 _rpos = _spos + _line;
	vec3 _tpos = (_rpos - (_spos + _start)) / abs(_end - _start);
	vec3 _tp = _tpos*_volume;
	vec3 _jump = -sdf3dSample(floor(_tp+0.5), _tsize, _volume).xyz / _mult;
	return rotateXYZConjugate(_jump, -_rot);
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
	else if (ugmpShapeType == C_FAUX_TEX3D) {
		vec3 _scale = vec3(ugmpShapeCTX3.xyz - ugmpShapeCTX2.xyz);
		return ftexf3d(_point, _ctx1.xyz, _ctx2.xyz, _ctx3.xyz, ugmpShapeCTXSamplerSize.xy, ugmpShapeCTXSamplerUVs.xyz, ugmpShapeCTX4.xyz, vec3(ugmpShapeCTX1.w, ugmpShapeCTX2.w, ugmpShapeCTX3.w)) / mix(vec3(1.0), _scale, float(_ddist < 0.5));//mix(vec3(1.0), vec3(ugmpShapeCTXSamplerUVs.xyz) * _scale * .5, float(_ddist < 0.5));
	}
	return vec3(1.0);
}

#define OP_NOP			0
#define OP_SET			1
#define OP_SET_CMP		2

#define OP_ADD			3
#define OP_ADD_CMP		4

#define OP_SUB			5
#define OP_SUB_CMP		6

#define OP_DIV			7
#define OP_DIV_CMP		8

#define OP_MUL			9
#define OP_MUL_CMP		10

#define OP_CLAMP		11
#define OP_CLAMP_CMP	12


#define CMP_NOP				0
#define CMP_LESS			1
#define CMP_LESS_EQUAL		2
#define CMP_EQUAL			3
#define CMP_UNEQUAL			4
#define CMP_GREATER_EQUAL	5
#define CMP_GREATER			6

float getComponent(vec4 v, float c) {
	return v[int(c)];
}
bool compare(int opc, float lhs, float rhs) {
	if (opc == CMP_NOP) {
		return true;
	}
	else if (opc == CMP_LESS) {
		return (lhs < rhs);
	}
	else if (opc == CMP_LESS_EQUAL) {
		return (lhs <= rhs);
	}
	else if (opc == CMP_EQUAL) {
		return (lhs == rhs);
	}
	else if (opc == CMP_UNEQUAL) {
		return (lhs != rhs);
	}
	else if (opc == CMP_GREATER_EQUAL) {
		return (lhs >= rhs);
	}
	else if (opc == CMP_GREATER) {
		return (lhs > rhs);
	}
	return false;
}
float proc(vec2 uvs, float val, int opc, float reg0, float reg1, float reg2, float reg3, float reg4) {
	if (opc <= OP_NOP) {
		return val;
	}
	// SET
	else if (opc <= OP_SET) {
		return reg0;
	}
	else if (opc <= OP_SET_CMP) {
		float peek = lookup(uvs, reg2, gm_BaseTexture)[int(reg3)];
		if (compare(int(reg1), peek, reg4)) {
			return reg0;
		} else {
			return val;
		}
	}
	// ADD
	else if (opc <= OP_ADD) {
		return val + reg0;
	}
	else if (opc <= OP_ADD_CMP) {
		float peek = lookup(uvs, reg2, gm_BaseTexture)[int(reg3)];
		if (compare(int(reg1), peek, reg4)) {
			return val + reg0;
		} else {
			return val;
		}
	}
	// SUBTRACT
	else if (opc <= OP_SUB) {
		return val - reg0;
	}
	else if (opc <= OP_SUB_CMP) {
		float peek = lookup(uvs, reg2, gm_BaseTexture)[int(reg3)];
		if (compare(int(reg1), peek, reg4)) {
			return val - reg0;
		} else {
			return val;
		}
	}
	// DIVIDE
	else if (opc <= OP_DIV) {
		return val / reg0;
	}
	else if (opc <= OP_DIV_CMP) {
		float peek = lookup(uvs, reg2, gm_BaseTexture)[int(reg3)];
		if (compare(int(reg1), peek, reg4)) {
			return val / reg0;
		} else {
			return val;
		}
	}
	// MULTIPLY
	else if (opc <= OP_MUL) {
		return val * reg0;
	}
	else if (opc <= OP_MUL_CMP) {
		float peek = lookup(uvs, reg2, gm_BaseTexture)[int(reg3)];
		if (compare(int(reg1), peek, reg4)) {
			return val * reg0;
		} else {
			return val;
		}
	}
	// CLAMP
	else if (opc <= OP_CLAMP) {
		return clamp(val, reg0, reg1);
	}
	else if (opc <= OP_CLAMP_CMP) {
		float peek = lookup(uvs, reg2, gm_BaseTexture)[int(reg3)];
		if (compare(int(reg1), peek, reg4)) {
			return clamp(val, reg0, reg1);
		} else {
			return val;
		}
	}
	return val;
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
	float len = length(col);
	if (len > 0.0) {
		pack = vec4(
			proc(indexUVs, pack.x, ugmpOPC.x, ugmpREG0.x, ugmpREG1.x, ugmpREG2.x, ugmpREG3.x, ugmpREG4.x),
			proc(indexUVs, pack.y, ugmpOPC.y, ugmpREG0.y, ugmpREG1.y, ugmpREG2.y, ugmpREG3.y, ugmpREG4.y),
			proc(indexUVs, pack.z, ugmpOPC.z, ugmpREG0.z, ugmpREG1.z, ugmpREG2.z, ugmpREG3.z, ugmpREG4.z),
			proc(indexUVs, pack.w, ugmpOPC.w, ugmpREG0.w, ugmpREG1.w, ugmpREG2.w, ugmpREG3.w, ugmpREG4.w)
		);
	}
	
    gl_FragColor = pack;
}
