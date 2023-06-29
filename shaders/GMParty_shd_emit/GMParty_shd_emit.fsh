varying float v_vSlot;				// particle setting slot (X, Y, Z, COL, ..)
varying float v_vIndex;				// relative particle index (index + offset)
varying float v_vIndexAbsolute;		// absolute particle index (index)

uniform vec2 u_uIndexOffset;		// (index offset, max)

uniform float u_uIndexCount;			// max number of indexes to fill (skip overflow)
uniform float u_uSeed;					// (seed)

uniform vec4 u_uParticleColor0;			// (cmin, cmax, amin, amax)
uniform vec4 u_uParticleColor1;			// (cmin, cmax, amin, amax)
uniform vec4 u_uParticleColor2;			// (cmin, cmax, amin, amax)
uniform vec4 u_uParticleColor3;			// (cmin, cmax, amin, amax)

uniform vec3 u_uParticlePosStart;		// (xyz min)
uniform vec3 u_uParticlePosEnd;			// (xyz max)

uniform vec4 u_uParticleSize;			// (size_min, size_max, size_delta, size_wiggle)

uniform vec4 u_uParticleOrientMin;		// (xyz min, flags [snapToDir])
uniform vec3 u_uParticleOrientMax;		// (xyz max)
uniform vec3 u_uParticleOrientDeltaMin;	// (xyz delta)
uniform vec3 u_uParticleOrientDeltaMax;	// (xyz delta)
uniform vec3 u_uParticleOrientWiggle;	// (xyz wiggle)

uniform vec3 u_uParticleRotMin;			// (xyz min)
uniform vec3 u_uParticleRotMax;			// (xyz max)
uniform vec3 u_uParticleRotWiggle;		// (xyz wiggle)

uniform vec3 u_uParticleDirMin;			// (xyz min)
uniform vec3 u_uParticleDirMax;			// (xyz max)

uniform vec4 u_uParticleSpeed;			// (min, max, delta, wiggle)

uniform vec4 u_uParticleXScale;			// (min, max, delta, wiggle)
uniform vec4 u_uParticleYScale;			// (min, max, delta, wiggle)
uniform vec4 u_uParticleZScale;			// (min, max, delta, wiggle)

uniform vec4 u_uParticleImage;			// (min, max, count, sprite_index)
uniform vec3 u_uParticleImageSpeed;		// (min, max, scaleWithLife)
uniform float u_uParticleBlendMode;		// (blend_mode)

uniform vec3 u_uParticleLife;			// (min, max, type)

uniform vec2 u_uParticleMass;			// (min, max)
uniform vec2 u_uParticleRestitution;	// (min, max)
uniform vec2 u_uParticleGravity;		// (min, max)
uniform vec3 u_uParticleGravityNormal;	// (norm xyz)

uniform int u_uParticleFlags;

uniform vec4 u_uEmitter;				// (type, distribution, colorMixing, impulse)
uniform vec2 u_uEmitterRange;			// (min, max)
uniform mat4 u_uEmitterRot;
uniform sampler2D u_uEmitterTexture;
uniform vec4 u_uEmitterTextureSize;		// (texsize, count)
uniform vec4 u_uEmitterTextureScale;

const float PI = 3.14159265359;
const float PHI = 1.61803398874989484820459;
float gold_noise(in vec2 xy, in float seed) {
	return fract(tan(distance(xy*PHI, xy)*seed)*xy.x);
}
float rand(float co) { return fract(sin(co*(1.3458)) * 453.5453); }
float rand(vec2 co) { return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 438.5453); }
float rand(vec2 co, float so) { return gold_noise(vec2(1.0)+mod(co, 256.),fract(so/1780.23367)); }
float randomRange(in vec2 _range) {
	float _delta = _range.y - _range.x;
	return (_range.x + rand(vec2(v_vIndex+1., v_vSlot), u_uSeed+v_vIndexAbsolute+1.) * _delta);
}
float randomRangeSlot(in vec2 _range, in float _slot) {
	float _delta = _range.y - _range.x;
	return (_range.x + clamp(rand(vec2(v_vIndex+1., _slot), u_uSeed+v_vIndexAbsolute+1.), 0.001, 0.999) * _delta);
}
vec3 randomDirection(vec2 _rand) {
    float _cost = 1.0 - 2.0 * _rand.x;
    float _sint = sqrt(1.0 - _cost * _cost);
    float _phi = 2.0 * PI * _rand.y;
    return vec3(cos(_phi) * _sint, sin(_phi) * _sint, _cost);
}
vec3 floatToRGB(in float col) {
	vec3 c;
	col = floor(col);
	c.b = floor(col / 65536.);
	c.g = floor((col - c.b * 65536.) / 256.);
	c.r = mod(col, 256.0);
	return c / 255.;
}
float RGBToFloat(in vec3 crgb) {
	vec3 c = floor(crgb * 255.0);
	return c.r + c.g * 256.0 + c.b * 65536.0;
}
vec3 RGB2HSV(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 HSV2RGB(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

const float QUANTIZATION_STEP = 2.0 / 255.0; // Quantization step size
float encodeNormal(vec3 normal) {
	ivec3 quantized = ivec3((normal + 1.0) / QUANTIZATION_STEP + 0.5);
    float encoded = float(quantized.x) * 65536.0 + float(quantized.y) * 256.0 + float(quantized.z);
    return encoded;
}
vec3 normalizeSafe(vec3 invec) {
	return (length(invec) > 0.0) ? normalize(invec) : vec3(1.,0.,0.);
}

mat3 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3( vec3(1, 0, 0), vec3(0, c, -s), vec3(0, s, c) );
}
mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3( vec3(c, 0, s), vec3(0, 1, 0), vec3(-s, 0, c) );
}
mat3 rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3( vec3(c, -s, 0), vec3(s, c, 0), vec3(0, 0, 1) );
}
vec3 rotateXYZ(vec3 point, vec3 thetas) {
	return point * rotateX(thetas.x) * rotateY(thetas.y) * rotateZ(thetas.z);
}

vec3 emitPosition() {
	if (u_uEmitter.r <= 0.0) {
		vec3 _center = mix(u_uParticlePosStart, u_uParticlePosEnd, 0.5);
		vec3 _delta = vec3( abs(u_uParticlePosStart - u_uParticlePosEnd) ) * .5;
		
		vec3 _normv = vec3(	
			randomRangeSlot(u_uEmitterRange, 64.),
			randomRangeSlot(u_uEmitterRange, 65.),
			randomRangeSlot(u_uEmitterRange, 66.)
		);
		_normv *= vec3(
			( (abs(u_uParticlePosStart.x - u_uParticlePosEnd.x) < 0.1) ? 0.0 : 1.0),
			( (abs(u_uParticlePosStart.y - u_uParticlePosEnd.y) < 0.1) ? 0.0 : 1.0),
			( (abs(u_uParticlePosStart.z - u_uParticlePosEnd.z) < 0.1) ? 0.0 : 1.0)
		);
		if (u_uEmitter.g > 0.0) {
			_normv *= _normv;
		}
		if (u_uEmitter.g == 2.0) {
			_normv = 1.0 - _normv * _normv;
		}
		vec3 _sign = vec3(
			 (randomRangeSlot(vec2(0.0, 1.0), 67.) > 0.5) ? 1.0 : -1.0,
			 (randomRangeSlot(vec2(0.0, 1.0), 68.) > 0.5) ? 1.0 : -1.0,
			 (randomRangeSlot(vec2(0.0, 1.0), 69.) > 0.5) ? 1.0 : -1.0
		);
		return _center + (vec4((_normv * _delta) * _sign, 1.0) * u_uEmitterRot).xyz;
	}
	else if (u_uEmitter.r <= 1.0) {
		vec3 _center = mix(u_uParticlePosStart, u_uParticlePosEnd, 0.5);
		vec3 _delta = vec3( abs(u_uParticlePosStart - u_uParticlePosEnd) ) * .5;
		vec3 _normv = randomDirection(vec2(randomRangeSlot(vec2(0.0, 1.0), 64.), randomRangeSlot(vec2(0.0, 1.0), 65.)));
		_normv = normalizeSafe(_normv * vec3(
			( (abs(u_uParticlePosStart.x - u_uParticlePosEnd.x) < 0.1) ? 0.0 : 1.0),
			( (abs(u_uParticlePosStart.y - u_uParticlePosEnd.y) < 0.1) ? 0.0 : 1.0),
			( (abs(u_uParticlePosStart.z - u_uParticlePosEnd.z) < 0.1) ? 0.0 : 1.0)
		));
		float _len = randomRangeSlot(u_uEmitterRange, 66.);
		if (u_uEmitter.g > 0.0) {
			_len = _len * randomRangeSlot(vec2(0.0, 1.0), 67.);
		}
		if (u_uEmitter.g == 2.0) {
			_len = 1.0 - pow(_len, 1.5);
		}
		return _center + (vec4(_normv * _len * _delta, 1.0) * u_uEmitterRot).xyz;
	}
	else if (u_uEmitter.r <= 2.0) {
		float _len = randomRangeSlot(u_uEmitterRange, 64.);
		if (u_uEmitter.g > 0.0) {
			_len = _len * randomRangeSlot(u_uEmitterRange * .5, 65.) * .5;
		}
		return mix(
			u_uParticlePosStart,
			u_uParticlePosEnd,
			_len
		);
	}
	else if (u_uEmitter.r <= 3.0) {
		float _ind = floor(randomRangeSlot(vec2(0.0, u_uEmitterTextureSize.y), 64.));
		float _trid = _ind*4.;
		vec2 _uv0 = vec2(mod(_trid, u_uEmitterTextureSize.x), floor(_trid / u_uEmitterTextureSize.x)) / u_uEmitterTextureSize.x;
		_trid += 1.0;
		vec2 _uv1 = vec2(mod(_trid, u_uEmitterTextureSize.x), floor(_trid / u_uEmitterTextureSize.x)) / u_uEmitterTextureSize.x;
		_trid += 1.0;
		vec2 _uv2 = vec2(mod(_trid, u_uEmitterTextureSize.x), floor(_trid / u_uEmitterTextureSize.x)) / u_uEmitterTextureSize.x;
		
		vec4 _s0 = texture2D(u_uEmitterTexture, _uv0);
		vec4 _s1 = texture2D(u_uEmitterTexture, _uv1);
		vec4 _s2 = texture2D(u_uEmitterTexture, _uv2);
		
		vec2 _bar = vec2(
			randomRangeSlot(vec2(0.0, 1.0), 65.),
			randomRangeSlot(vec2(0.0, 1.0), 66.)
		);
		
		vec3 _pos = mix(_s0.xyz, mix(_s1.xyz, _s2.xyz, _bar.y), _bar.x) * u_uEmitterTextureScale.xyz;
		
		return u_uParticlePosStart + (vec4(_pos, 1.0) * u_uEmitterRot).xyz;
	}
	else return u_uParticlePosStart;
}
vec3 emitDirection() {
	if (u_uEmitter.a <= 0.0) {
		vec3 rotdeg = vec3(
			radians(mix(u_uParticleDirMin.x, u_uParticleDirMax.x, randomRangeSlot(vec2(0., 1.), 91.) ) ),
			radians(mix(u_uParticleDirMin.y, u_uParticleDirMax.y, randomRangeSlot(vec2(0., 1.), 92.) ) ),
			radians(-mix(u_uParticleDirMin.z, u_uParticleDirMax.z, randomRangeSlot(vec2(0., 1.), 93.) ) )
		);
		return rotateXYZ(vec3(1.0, 0.0, 0.0), rotdeg);
	}
	else if (u_uEmitter.a <= 1.0)	{
		vec3 center = mix(u_uParticlePosStart, u_uParticlePosEnd, 0.5);
		return normalizeSafe(emitPosition() - center);
	}
	else if (u_uEmitter.a <= 2.0)	{
		vec3 rotdeg = vec3(
			radians(mix(u_uParticleDirMin.x, u_uParticleDirMax.x, randomRangeSlot(vec2(0., 1.), 91.) ) ),
			radians(mix(u_uParticleDirMin.y, u_uParticleDirMax.y, randomRangeSlot(vec2(0., 1.), 92.) ) ),
			radians(-mix(u_uParticleDirMin.z, u_uParticleDirMax.z, randomRangeSlot(vec2(0., 1.), 93.) ) )
		);
		vec3 weighted = rotateXYZ(vec3(1.0, 0.0, 0.0), rotdeg);
		vec3 center = mix(u_uParticlePosStart, u_uParticlePosEnd, 0.5);
		return mix(weighted, normalize(emitPosition() - center), 0.5);
	}
	else return vec3(0.0);
}

void main() {
	if (v_vIndexAbsolute >= u_uIndexCount) discard;
	vec4 pack = vec4(0.0);
	
	// LIFE
	if (v_vSlot <= 0.0) {
		pack.xy = vec2(randomRangeSlot(u_uParticleLife.xy, 0.));
		pack.z = randomRangeSlot(vec2(1.0, 1000.0), 0.1);
		pack.w = u_uParticleLife.z;
	}
	// POSITION
	else if (v_vSlot <= 1.0) {
		pack.xyz = emitPosition();
		// POSITION also packs flags
		pack.w = float(u_uParticleFlags);
	}
	// SPEED
	else if (v_vSlot <= 2.0) {
		pack.xyz = emitDirection() * randomRangeSlot(u_uParticleSpeed.xy, 2.);
		pack.w = u_uParticleBlendMode;
	}
	// ACCELERATION
	else if (v_vSlot <= 3.0) {
		pack.xy = u_uParticleSpeed.zw;
	}
	// SCALE
	else if (v_vSlot <= 4.0) {
		pack = vec4(
			randomRangeSlot(u_uParticleXScale.xy, 4.1),
			randomRangeSlot(u_uParticleYScale.xy, 4.2),
			randomRangeSlot(u_uParticleZScale.xy, 4.3),
			randomRangeSlot(u_uParticleSize.xy, 4.4)
		);
	}
	// SCALE_DELTA
	else if (v_vSlot <= 5.0) {
		pack = vec4(
			u_uParticleXScale.z,
			u_uParticleYScale.z,
			u_uParticleZScale.z,
			u_uParticleSize.z
		);
	}
	// SCALE_WIGGLE
	else if (v_vSlot <= 6.0) {
		pack = vec4(
			u_uParticleXScale.w,
			u_uParticleYScale.w,
			u_uParticleZScale.w,
			u_uParticleSize.w
		);
	}
	// ORIENTATION
	else if (v_vSlot <= 7.0) {
		pack = vec4(
			randomRangeSlot(vec2(u_uParticleOrientMin.x, u_uParticleOrientMax.x), 7.1),
			randomRangeSlot(vec2(u_uParticleOrientMin.y, u_uParticleOrientMax.y), 7.2),
			randomRangeSlot(vec2(u_uParticleOrientMin.z, u_uParticleOrientMax.z), 7.3),
			u_uParticleOrientMin.w
		);
	}
	// ORIENTATION_DELTA
	else if (v_vSlot <= 8.0) {
		pack.xyz = vec3(
			randomRangeSlot(vec2(u_uParticleOrientDeltaMin.x, u_uParticleOrientDeltaMax.x), 8.1),
			randomRangeSlot(vec2(u_uParticleOrientDeltaMin.y, u_uParticleOrientDeltaMax.y), 8.2),
			randomRangeSlot(vec2(u_uParticleOrientDeltaMin.z, u_uParticleOrientDeltaMax.z), 8.3)
		);
	}
	// ORIENTATION_WIGGLE
	else if (v_vSlot <= 9.0) {
		pack.xyz = u_uParticleOrientWiggle;
	}
	// DIRECTION_DELTA
	else if (v_vSlot <= 10.0) {
		pack.xyz = vec3(
			randomRangeSlot(vec2(u_uParticleRotMin.x, u_uParticleRotMax.x), 10.1),
			randomRangeSlot(vec2(u_uParticleRotMin.y, u_uParticleRotMax.y), 10.2),
			randomRangeSlot(vec2(u_uParticleRotMin.z, u_uParticleRotMax.z), 10.3)
		);
	}
	// DIRECTION_WIGGLE
	else if (v_vSlot <= 11.0) {
		pack.xyz = u_uParticleRotWiggle;
	}
	// IMAGE
	else if (v_vSlot <= 12.0) {
		float img = randomRangeSlot(vec2(u_uParticleImage.x, u_uParticleImage.y), 12.2);
		float ispd = (u_uParticleImageSpeed.z > 0.5) ? 
			(abs(u_uParticleImage.z - img) / randomRangeSlot(u_uParticleLife.xy, 0.)) :
			(randomRangeSlot(vec2(u_uParticleImageSpeed.x, u_uParticleImageSpeed.y), 12.1));
		pack = vec4(
			img,
			u_uParticleImage.z,
			ispd,
			u_uParticleImage.w
		);
	}
	// COLOR
	else if (v_vSlot <= 13.0) {
		if (u_uEmitter.b <= 0.0) {
			vec4 unpack = floor(vec4(
				RGBToFloat(mix(floatToRGB(u_uParticleColor0.x), floatToRGB(u_uParticleColor0.y), randomRangeSlot(vec2(0., 1.), 13.1))),
				RGBToFloat(mix(floatToRGB(u_uParticleColor1.x), floatToRGB(u_uParticleColor1.y), randomRangeSlot(vec2(0., 1.), 13.2))),
				RGBToFloat(mix(floatToRGB(u_uParticleColor2.x), floatToRGB(u_uParticleColor2.y), randomRangeSlot(vec2(0., 1.), 13.3))),
				RGBToFloat(mix(floatToRGB(u_uParticleColor3.x), floatToRGB(u_uParticleColor3.y), randomRangeSlot(vec2(0., 1.), 13.4)))
			));
			pack = unpack;
		}
		else {
			vec3 a1, a2, a3, a4;
			vec3 b1, b2, b3, b4;
			a1 = floatToRGB(u_uParticleColor0.x);
			b1 = floatToRGB(u_uParticleColor0.y);
			a2 = floatToRGB(u_uParticleColor1.x);
			b2 = floatToRGB(u_uParticleColor1.y);
			a3 = floatToRGB(u_uParticleColor2.x);
			b3 = floatToRGB(u_uParticleColor2.y);
			a4 = floatToRGB(u_uParticleColor3.x);
			b4 = floatToRGB(u_uParticleColor3.y);
			if (u_uEmitter.b <= 1.0) {
				pack = floor(vec4(
					RGBToFloat(vec3(
						randomRangeSlot(vec2(a1.r, b1.r), 13.1),
						randomRangeSlot(vec2(a1.g, b1.g), 13.2),
						randomRangeSlot(vec2(a1.b, b1.b), 13.3)
					)),
					RGBToFloat(vec3(
						randomRangeSlot(vec2(a2.r, b2.r), 13.4),
						randomRangeSlot(vec2(a2.g, b2.g), 13.5),
						randomRangeSlot(vec2(a2.b, b2.b), 13.6)
					)),
					RGBToFloat(vec3(
						randomRangeSlot(vec2(a3.r, b3.r), 13.7),
						randomRangeSlot(vec2(a3.g, b3.g), 13.8),
						randomRangeSlot(vec2(a3.b, b3.b), 13.9)
					)),
					RGBToFloat(vec3(
						randomRangeSlot(vec2(a4.r, b4.r), 13.11),
						randomRangeSlot(vec2(a4.g, b4.g), 13.22),
						randomRangeSlot(vec2(a4.b, b4.b), 13.33)
					))
				));
			}
			else {
				pack = floor(vec4(
					RGBToFloat(HSV2RGB(vec3(
						randomRangeSlot(vec2(a1.r, b1.r), 13.1),
						randomRangeSlot(vec2(a1.g, b1.g), 13.2),
						randomRangeSlot(vec2(a1.b, b1.b), 13.3)
					))),
					RGBToFloat(HSV2RGB(vec3(
						randomRangeSlot(vec2(a2.r, b2.r), 13.4),
						randomRangeSlot(vec2(a2.g, b2.g), 13.5),
						randomRangeSlot(vec2(a2.b, b2.b), 13.6)
					))),
					RGBToFloat(HSV2RGB(vec3(
						randomRangeSlot(vec2(a3.r, b3.r), 13.7),
						randomRangeSlot(vec2(a3.g, b3.g), 13.8),
						randomRangeSlot(vec2(a3.b, b3.b), 13.9)
					))),
					RGBToFloat(HSV2RGB(vec3(
						randomRangeSlot(vec2(a4.r, b4.r), 13.11),
						randomRangeSlot(vec2(a4.g, b4.g), 13.22),
						randomRangeSlot(vec2(a4.b, b4.b), 13.33)
					)))
				));
			}
		}
	}
	// ALPHA
	else if (v_vSlot <= 14.0) {
		pack = vec4(
			randomRangeSlot(u_uParticleColor0.zw, 14.1),
			randomRangeSlot(u_uParticleColor1.zw, 14.2),
			randomRangeSlot(u_uParticleColor2.zw, 14.3),
			randomRangeSlot(u_uParticleColor3.zw, 14.4)
		);
	}
	// PHYSICS
	else if (v_vSlot <= 15.0) {
		pack.xy = vec2(
			randomRangeSlot(u_uParticleMass.xy, 15.1),
			randomRangeSlot(u_uParticleRestitution.xy, 15.2)
		);
		pack.z = randomRangeSlot(u_uParticleGravity.xy, 15.3);
		pack.w = encodeNormal(u_uParticleGravityNormal);
	}
	
    gl_FragColor = pack;
}
