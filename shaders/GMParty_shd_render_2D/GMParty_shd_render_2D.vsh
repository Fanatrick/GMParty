attribute vec3 in_Position;				// cx, cy, id

varying vec2 v_vTexcoord;				// uv
varying vec4 v_vColor;					// rgba
varying vec2 v_vImage;					// image_index, stage_index
varying float v_vSkip;

uniform sampler2D ugmpParticleData;		// particle data
uniform vec3 ugmpSize;					// texsize, slotsize, gridsize

uniform float ugmpIndexTell;			// buffer index position
uniform float ugmpIndexCount;			// max number of indexes to fill
uniform float ugmpIndexFTB;				// front-to-back
uniform vec3 ugmpSysTranslate;			// system xyz offset
uniform float ugmpBlendMode;			// blend_mode
uniform float ugmpTime;					// time
uniform float ugmpTimeFrequency;		// frequency (used for gm-like oscillation wiggle)

uniform float ugmpSpriteIndex;			// sprite index
uniform float ugmpTextureNum;			// number of textures staged
uniform vec3 ugmpImageNum;				// imgnum, img-per-stage, img-per-row
uniform vec4 ugmpImageOffset;			// dimensions and offsets

uniform vec4 ugmpTextureSize0;			// texwidth, texheight, imgu, imgv
uniform vec4 ugmpTextureSize1;
uniform vec4 ugmpTextureSize2;
uniform vec4 ugmpTextureSize3;

const float flagSpeedAllowNegative = 1.;
const float flagSpeedInvertDelta = 2.;
const float flagSizeAllowNegative = 4.;
const float flagWiggleAdditive = 8.;
const float flagWiggleRangeSymmetry = 16.;
const float flagWiggleOscillate = 32.;
const float flagBlendAdditive = 64.;

float getFlag(float flags, float flag) {
    float result = float(mod(floor(flags / flag), 2.0) > 0.0);
	//int(mod(float(flags / int(pow(2.0, float(flagIndex)))), 2.));
    return result;
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
vec3 colMix(in vec4 cols, in float ls) {
	vec3 c1 = floatToRGB(cols.x);
	vec3 c2 = floatToRGB(cols.y);
	vec3 c3 = floatToRGB(cols.z);
	vec3 c4 = floatToRGB(cols.w);
	float lim = 3.0 - float(cols.y < 0.0) - float(cols.z < 0.0) - float(cols.w < 0.0);
	vec3 fcol = mix(c1, c2, clamp(ls * lim, 0.0, 1.0));
	fcol = mix(fcol, c3, clamp(ls * lim - 1.0, 0.0, 1.0));
	fcol = mix(fcol, c4, clamp(ls * lim - 2.0, 0.0, 1.0));
	return fcol;
}
vec3 normalizeSafe(vec3 invec) {
	return (length(invec) > 0.0) ? normalize(invec) : vec3(1.,0.,0.);
}

vec4 lookup(in vec2 _uvs, in float _slot) {
	vec2 _offset = vec2(mod(_slot, ugmpSize.z), floor(_slot / ugmpSize.z)) * (1.0 / ugmpSize.z);
	return texture2D(ugmpParticleData, _uvs + _offset);
}

void main() {
	// get id from range of currently awake particles
	float pmax = ugmpSize.y * ugmpSize.y;
	float pid = floor(mod(pmax + ugmpIndexTell - ugmpIndexCount + in_Position.z, pmax));
	if (ugmpIndexFTB > 0.0) {
		pid = floor(mod(pmax + ugmpIndexTell - in_Position.z, pmax));
	}
	
	// get slot uvs
	vec2 puv = vec2(mod(pid, ugmpSize.y)+0.5, floor(pid / ugmpSize.y)+0.5) / ugmpSize.x;
	float pflags = lookup(puv, 1.0).w;
	
	float seed = lookup(puv, 0.0).z;
	
	//------------------------------------------------------------//
	// read particle data from sampler
	// life
	vec4 p_life = lookup(puv, 0.0);
	float lifespan = 1.0 - (p_life.x / p_life.y);//(p_life.y - p_life.x) / p_life.y;
	v_vSkip = (p_life.x < 1.0 ? 1.0 : 0.0);
	// position, scale, rotation
	vec3 p_pos = lookup(puv, 1.0).xyz + ugmpSysTranslate;
	float p_wiggle_lower_limit = getFlag(flagWiggleRangeSymmetry, pflags);
	vec4 p_pos_speed = lookup(puv, 2.0);
	float p_pos_wiggle = lookup(puv, 3.0).y;
	if (getFlag(pflags, flagWiggleOscillate) > 0.0) {
		p_pos += normalizeSafe(p_pos_speed.xyz) * (
			sin(ugmpTimeFrequency * ugmpTime + pid) * p_pos_wiggle
		) * (1.0 - getFlag(pflags, flagWiggleAdditive));
	} else {
		p_pos += normalizeSafe(p_pos_speed.xyz) * (
			randomRange(vec2(-p_pos_wiggle * p_wiggle_lower_limit, p_pos_wiggle), vec2(pid, 3.1), seed)
		) * (1.0 - getFlag(pflags, flagWiggleAdditive));
	}
	
	vec4 p_scale = lookup(puv, 4.0);
	vec4 p_scale_wiggle = lookup(puv, 6.0);
	if (getFlag(pflags, flagWiggleOscillate) > 0.0) {
		p_scale.w += (
			sin(45. + ugmpTimeFrequency * ugmpTime + pid) * p_scale_wiggle.w
		) * (1.0 - getFlag(pflags, flagWiggleAdditive));
		p_scale.w = max(p_scale.w, 0.0);
	} else {
		p_scale += vec4(
			randomRange(vec2(-p_scale_wiggle.x * p_wiggle_lower_limit, p_scale_wiggle.x), vec2(pid, 6.1), seed),
			randomRange(vec2(-p_scale_wiggle.y * p_wiggle_lower_limit, p_scale_wiggle.y), vec2(pid, 6.2), seed),
			randomRange(vec2(-p_scale_wiggle.z * p_wiggle_lower_limit, p_scale_wiggle.z), vec2(pid, 6.3), seed),
			randomRange(vec2(-p_scale_wiggle.w * p_wiggle_lower_limit, p_scale_wiggle.w), vec2(pid, 6.4), seed)
		) * (1.0 - getFlag(pflags, flagWiggleAdditive));
	}
	
	vec3 p_rot = radians(lookup(puv, 7.0).xyz);
	vec3 p_rot_wiggle = lookup(puv, 9.0).xyz;
	if (getFlag(pflags, flagWiggleOscillate) > 0.0) {
		p_rot.x += (
			sin(57. + ugmpTimeFrequency * ugmpTime + pid) * p_rot_wiggle.x
		) * (1.0 - getFlag(pflags, flagWiggleAdditive));
	} else {
		p_rot += vec3(
			randomRange(vec2(-p_rot_wiggle.x * p_wiggle_lower_limit, p_scale_wiggle.x), vec2(pid, 9.1), seed),
			randomRange(vec2(-p_rot_wiggle.y * p_wiggle_lower_limit, p_scale_wiggle.y), vec2(pid, 9.2), seed),
			randomRange(vec2(-p_rot_wiggle.z * p_wiggle_lower_limit, p_scale_wiggle.z), vec2(pid, 9.3), seed)
		) * (1.0 - getFlag(pflags, flagWiggleAdditive));
	}
	
	vec4 offset = ugmpImageOffset * vec4(p_scale.xy, p_scale.xy) * p_scale.w;
	vec2 corner = vec2(mix(offset.x, offset.z, in_Position.x), mix(offset.y, offset.w, in_Position.y));
	corner = vec2(cos(p_rot.x) * corner.x - sin(p_rot.x) * corner.y, sin(p_rot.x) * corner.x + cos(p_rot.x) * corner.y);
	vec4 translate = vec4(corner, 0.0, 1.0);
	gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * vec4( p_pos + translate.xyz, 1.0);
	// image, texture
	vec4 p_img = lookup(puv, 12.0);
	v_vSkip = max(v_vSkip, (floor(p_img.w) != ugmpSpriteIndex) ? 1.0 : 0.0);
	v_vImage = vec2(mod(floor(p_img.x), ugmpImageNum.y), floor(p_img.x / ugmpImageNum.y));
	vec2 tuvs = ugmpTextureSize0.zw;
	if (v_vImage.y == 1.0) {
		tuvs = ugmpTextureSize1.zw;
	}
	else if (v_vImage.y == 2.0) {
		tuvs = ugmpTextureSize2.zw;
	}
	else if (v_vImage.y == 3.0) {
		tuvs = ugmpTextureSize3.zw;
	}
	vec4 imguvs;
	imguvs.xy = vec2(mod(v_vImage.x, ugmpImageNum.z), floor(v_vImage.x / ugmpImageNum.z)) * tuvs;
	imguvs.zw = imguvs.xy + tuvs;
	// color
	vec4 p_col = lookup(puv, 13.0);
	vec4 p_alp = lookup(puv, 14.0);
	vec3 fcol = colMix(p_col, lifespan);
	float lim = 3.0 - float(p_alp.y < 0.0) - float(p_alp.z < 0.0) - float(p_alp.w < 0.0);
	float falp = mix(p_alp.x, p_alp.y, clamp(lifespan * lim, 0.0, 1.0));
	falp = mix(falp, p_alp.z, clamp(lifespan * lim - 1.0, 0.0, 1.0));
	falp = mix(falp, p_alp.w, clamp(lifespan * lim - 2.0, 0.0, 1.0));
	v_vColor = vec4(fcol, falp);
	v_vTexcoord = vec2(mix(imguvs.x, imguvs.z, in_Position.x), mix(imguvs.y, imguvs.w, in_Position.y));
	vec2 pindex = vec2(in_Position.z, ugmpIndexCount);
	v_vSkip = max(v_vSkip, (pindex.x > pindex.y ? 1.0 : 0.0));
	
	// skip on blendmode mismatch
	float p_bm = p_pos_speed.w;
	v_vSkip = max(v_vSkip, float(ugmpBlendMode != p_bm));
	//if (getFlag(flagWiggleRangeSymmetry, pflags) > 0.0) {
	//	v_vColor = vec4(vec3(0.0), 1.0);
	//}
}
