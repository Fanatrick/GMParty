varying vec2 v_vTexcoord;

uniform vec3 u_uSize;					// (texsize, slotsize, gridsize)

const float flagSpeedAllowNegative = 1.;
const float flagSpeedInvertDelta = 2.;
const float flagSizeAllowNegative = 4.;
const float flagWiggleAdditive = 8.;
const float flagWiggleRangeSymmetry = 16.;
const float flagWiggleOscillate = 32.;
const float flagIs3d = 64.;
const float flagIsLookat = 128.;

float getFlag(float flags, float flag) {
    return float(mod(floor(flags / flag), 2.0) > 0.0);
}

// Gold Noise ©2015 dcerisano@standard3d.com
const float PHI = 1.61803398874989484820459;
float gold_noise(in vec2 xy, in float seed) {
	return fract(tan(distance(xy*PHI, xy)*seed)*xy.x);
}
float rand(float co) { return fract(sin(co*(1.3458)) * 453.5453); }
float rand(vec2 co) { return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 438.5453); }
float rand(vec2 co, float so) { return gold_noise(mod(co, 100.),fract(so/1780.23367)); }
float randomRange(in vec2 _range, in vec2 _index, in float _seed) {
	float _delta = _range.y - _range.x;
	return (_range.x + clamp(rand(vec2(_index.x+1., _index.y), _seed), 0.001, 0.999) * _delta);
}

vec3 floatToRGB(in float col) {
	vec3 c;
	c.b = floor(col / 65536.);
	c.g = floor((col - c.b * 65536.) / 256.);
	c.r = mod(col, 256.0);
	return c / 255.;
}
float RGBToFloat(in vec3 crgb) {
	vec3 c = crgb * 255.0;
	return c.r + c.g * 256.0 + c.b * 65536.0;
}

const float QUANTIZATION_STEP = 2.0 / 255.0; // Quantization step size
vec3 decodeNormal(float encoded) {
	ivec3 quantized;
    quantized.x = int(encoded / 65536.0);
    quantized.y = int((encoded - float(quantized.x) * 65536.0) / 256.0);
    quantized.z = int(encoded - float(quantized.x) * 65536.0 - float(quantized.y) * 256.0);
	return normalize(vec3(quantized) * QUANTIZATION_STEP - 1.0);
}
vec3 normalizeSafe(vec3 invec) {
	return (length(invec) > 0.0) ? normalize(invec) : vec3(1.,0.,0.);
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

const float PI = 3.14159265359;
const float TAU = 6.28318530718;

vec4 lookup(in vec2 _uvs, in float _slot, in sampler2D _tex) {
	vec2 _offset = vec2(mod(_slot, u_uSize.z), floor(_slot / u_uSize.z)) * (1.0 / u_uSize.z);
	return texture2D(_tex, _uvs + _offset);
}

vec4 calcSpeed(in float ind, in vec2 uvs, in float seed, in float flags) {
	vec3 spd = lookup(uvs, 2.0, gm_BaseTexture).xyz;
	vec2 pgrav = lookup(uvs, 15.0, gm_BaseTexture).zw;
	spd += pgrav.x * decodeNormal(pgrav.y);
	vec2 acc = lookup(uvs, 3.0, gm_BaseTexture).xy;	
	float spd_len = length(spd);
	float spd_wiggle = randomRange(
		vec2(-acc.y * getFlag(flags, flagWiggleRangeSymmetry), acc.y),
		vec2(ind, 3.0), 
		seed
	) * float(getFlag(flags, flagWiggleAdditive));
	float spd_d = spd_len + acc.x + spd_wiggle;
	spd_d = (getFlag(flags, flagSpeedAllowNegative) > 0. ) ? spd_d : max(spd_d, 0.0);
	vec3 spd_normal = normalizeSafe(spd);
	vec3 rot = lookup(uvs, 10., gm_BaseTexture).xyz;
	vec3 rot_wiggle = lookup(uvs, 11., gm_BaseTexture).xyz;
	float rot_lower_limit = getFlag(flags, flagWiggleRangeSymmetry);
	vec3 rot_total = vec3(
		randomRange(vec2(-rot_wiggle.x * rot_lower_limit, rot_wiggle.x), vec2(ind, 11.1), seed),
		randomRange(vec2(-rot_wiggle.y * rot_lower_limit, rot_wiggle.y), vec2(ind, 11.2), seed),
		randomRange(vec2(-rot_wiggle.z * rot_lower_limit, rot_wiggle.z), vec2(ind, 11.3), seed)
	) * float(getFlag(flags, flagWiggleAdditive)) + rot;
	
	spd_normal = rotateXYZ(spd_normal, (rot_total) );
	
	return vec4(spd_normal * spd_d, spd_d);
}

void main() {
	vec2 position = floor(v_vTexcoord * u_uSize.x);
	vec2 indexUVs = mod(position, u_uSize.y) / u_uSize.x;
	float index = position.x + position.y * u_uSize.y;
	float slot = floor(v_vTexcoord.x * u_uSize.z) + floor(v_vTexcoord.y * u_uSize.z) * u_uSize.z;
	//vec2 rng = vec2(index, slot);
	
	vec4 pack = lookup(indexUVs, slot, gm_BaseTexture);
	float seed = lookup(indexUVs, 0.0, gm_BaseTexture).z;
	highp float pflags = floor(lookup(indexUVs, 1.0, gm_BaseTexture).w);
	
	//vec2 life = lookup(indexUVs, 0.0, gm_BaseTexture).xy;
	//if (life.x < 1.) discard;
	
	// LIFE
	if (slot == 0.0) {
		pack.x = max(pack.x - 1.0, 0.0);
		pack.z = randomRange(vec2(1.0, 1000.0), vec2(index, 0.1), seed);
	}
	// POSITION
	else if (slot == 1.0) {
		vec3 spd = lookup(indexUVs, 2.0, gm_BaseTexture).xyz;
		pack.xyz += spd;
	}
	// SPEED
	else if (slot == 2.0) {
		pack.xyz = calcSpeed(index, indexUVs, seed, pflags).xyz;
	}
	// ACCELERATION
	//else if (slot == 3.0) {
		// invert delta when crossing signs
		//float spd = length(lookup(indexUVs, 2.0, gm_BaseTexture).xyz);
		//float spd_d = calcSpeed(index, indexUVs, seed, pflags).w;
		//if (spd_d < 0.0) {
			//pack.x = (getFlag(pflags, flagSpeedInvertDelta) > 0.) ? -pack.x : pack.x;
		//}
	//}
	// SCALE
	else if (slot == 4.0) {
		vec4 sc_delta = lookup(indexUVs, 5.0, gm_BaseTexture); // read scale delta
		vec4 sc_wiggle = lookup(indexUVs, 6.0, gm_BaseTexture); // read scale wiggle
		float sc_lower_limit = float(getFlag(pflags, flagWiggleRangeSymmetry));
		pack += sc_delta + vec4(
			randomRange(vec2(-sc_wiggle.x * sc_lower_limit, sc_wiggle.x), vec2(index, 6.1), seed),
			randomRange(vec2(-sc_wiggle.y * sc_lower_limit, sc_wiggle.y), vec2(index, 6.2), seed),
			randomRange(vec2(-sc_wiggle.z * sc_lower_limit, sc_wiggle.z), vec2(index, 6.3), seed),
			randomRange(vec2(-sc_wiggle.w * sc_lower_limit, sc_wiggle.w), vec2(index, 6.4), seed)
		) * getFlag(pflags, flagWiggleAdditive);
		pack.w = (getFlag(pflags, flagSizeAllowNegative) > 0.) ? pack.w : max(pack.w, 0.0);
	}
	// ORIENTATION
	else if (slot == 7.0) {
		vec3 val_spd = lookup(indexUVs, 2.0, gm_BaseTexture).xyz;
		vec3 val_delta = lookup(indexUVs, 8.0, gm_BaseTexture).xyz; // read orientation delta
		vec3 val_wiggle = lookup(indexUVs, 9.0, gm_BaseTexture).xyz; // read orientation wiggle
		
		vec3 val_ns = normalize(val_spd);
		float pitch = -degrees(asin(dot(normalize(val_spd), vec3(0.0, 0.0, 1.0))));
		float yaw = degrees(atan(val_spd.y, val_spd.x));
		
		pack.xyz = mix(
			pack.xyz,
			vec3(pitch, yaw, pack.z),
			(lookup(indexUVs, 7.0, gm_BaseTexture).w) * float(length(val_spd) > 1.0)
		);
		
		float val_lower_limit = float(getFlag(pflags, flagWiggleRangeSymmetry));
		pack.xyz += val_delta + vec3(
			randomRange(vec2(-val_wiggle.x * val_lower_limit, val_wiggle.x), vec2(index, 9.1), seed),
			randomRange(vec2(-val_wiggle.y * val_lower_limit, val_wiggle.y), vec2(index, 9.2), seed),
			randomRange(vec2(-val_wiggle.z * val_lower_limit, val_wiggle.z), vec2(index, 9.3), seed)
		) * float(getFlag(pflags, flagWiggleAdditive));
		
	}
	// IMAGE
	else if (slot == 12.0) {
		pack.x = mod(pack.x + pack.z, pack.y + 1.0);
	}
	
	gl_FragColor = pack;
}
