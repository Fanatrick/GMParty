/// Feather disable all
enum e_gmpartyComponent {
/* 0*/	Life,				// life, life_max, seed, type
/* 1*/	Position,			// x, y, z, !FLAGS (e_gmpartyPartFlag.*)
/* 2*/	Speed,				// xs, ys, zs, !BLEND_MODE
/* 3*/	Acceleration,		// delta_speed, wiggle_speed
/* 4*/	Scale,				// xscale, yscale, zscale, size
/* 5*/	ScaleDelta,			// delta_xscale, delta_yscale, delta_zscale, delta_size
/* 6*/	ScaleWiggle,		// wiggle_xscale, wiggle_yscale, wiggle_zscale, wiggle_size
/* 7*/	Orientation,		// xangle, yangle, zangle, snap_to_direction
/* 8*/	OrientationDelta,	// xrot, yrot, zrot
/* 9*/	OrientationWiggle,	// wiggle_xrot, wiggle_yrot, wiggle_zrot
/*10*/	DirectionDelta,		// xdir_delta, ydir_delta, zdir_delta
/*11*/	DirectionWiggle,	// xdir_wiggle, ydir_wiggle, zdir_wiggle
/*12*/	Image,				// image, image_max, image_speed, sprite_index
/*13*/	Color,				// color, color1, color2, color3
/*14*/	Alpha,				// alpha, alpha1, alpha2, alpha3
/*15*/	Physics,			// mass, restitution, gravity_strength, gravity_octahedral
	
	LEN
}

enum e_gmpartyOverflow {	// @TODO particle buffer overflow setting
	Strict,			// given strict maximum (ie. 200 particles) (overwrite)
	Optimal,		// effective maximum (ie. 256 allowed from 200 allocated) (overwrite)
	Upscale			// upscale (upscale from 256 to 512 buffer) (no overwrite)
}

enum e_gmpartyPartFlag {
	None = 0,
	SpeedAllowNegative = 1,
	SpeedInvertDelta = 2,
	SizeAllowNegative = 4,
	WiggleAdditive = 8,
	WiggleRangeSymmetry = 16,
	WiggleOscillate = 32,
	
	Is3d = 64,			// these two are mutually exclusive
	IsLookat = 128,
}

enum e_gmpartyMixing {
	Vector,				// mix between vectors
	ComponentRGB,		// mix between components
	ComponentHSV,		// @TODO
}
enum e_gmpartyEmitDistribution { // @TODO - fix distribution
	Linear,
	Gaussian,
	InvGaussian
}
enum e_gmpartyEmitShape {
	Box,
	Sphere,
	Line,
	Model,
	Sprite
}
enum e_gmpartyEmitFire {
	Absolute,
	Relative,
	Mix
}

/// Creates a new solver allocating {_num} particles in total.
/// @arg {real} [_num]=(GMPARTY_DEFAULT_SOLVER_SIZE) Description
function GMPartySolver(_num=GMPARTY_DEFAULT_SOLVER_SIZE) constructor {
	static utils = gmpartyUtils();
	static glConfig = utils.glConfigGet();
	static __getAllocSize = function(_alloc) {
		return power(2, ceil(log2(sqrt(_alloc))));
	}
	static __vformatWrite = utils.vformatCache([e_vertexComponent.Position2d]);
	static __vbufferWriteBake = function(_count) {
		var _vb = vertex_create_buffer(),
			_nc = e_gmpartyComponent.LEN;
		vertex_begin(_vb, __vformatWrite);
		for(var i = 0; i < _count; i++) {	// for each partycle
			for(var j = 0; j < _nc; j++) {	// for each component
				// define writing format
				vertex_position(_vb, i, j);
			}
		}
		vertex_end(_vb);
		vertex_freeze(_vb);
		return _vb;
	}
	static __vbufferWriteBakeList = function() {
		var _arr = [],
			_p = 1;
		for(var i = 0; i < GMPARTY_EMIT_BUFFERS; i++) {
			array_push(_arr, __vbufferWriteBake(_p) );
			_p *= 2;
		}
		return _arr;
	}
	static __vformatRender = utils.vformatCache([e_vertexComponent.Position3d]);
	static __vbufferRenderBake = function(_count) {
		var _vb = vertex_create_buffer();
		vertex_begin(_vb, __vformatRender);
		for(var i = 0; i < _count; i++) {
			// 2-triangle-quad
			vertex_position_3d(_vb, 0, 0, i);		// position 3d
			vertex_position_3d(_vb, 1, 0, i);		// position 3d
			vertex_position_3d(_vb, 0, 1, i);		// position 3d
			vertex_position_3d(_vb, 1, 0, i);		// position 3d
			vertex_position_3d(_vb, 0, 1, i);		// position 3d
			vertex_position_3d(_vb, 1, 1, i);		// position 3d
		}
		vertex_end(_vb);
		vertex_freeze(_vb);
		return _vb;
	}
	static __vbufferRenderBakeList = function() {
		var _arr = [],
			_p = GMPARTY_RENDER_MIN;
		for(var i = 0; i < GMPARTY_RENDER_BUFFERS; i++) {
			array_push(_arr, __vbufferRenderBake(_p) );
			_p *= 2;
		}
		return _arr;
	}
	
	static __vbufferWriteList	= __vbufferWriteBakeList();
	static __vbufferRenderList	= __vbufferRenderBakeList();
	static __surfaceFormat = surface_rgba32float;	// 16bit currently has color encoding errors
	static __CamX = 0;
	static __CamY = 0;
	static __CamZ = -1;
	
	surfaceSlotSize	= __getAllocSize(_num);	// calculate power of 2 slotsize
	surfaceTexSize	= surfaceSlotSize * GMPARTY_TEXTURE_GRID_SIZE;
	
	surfaceParticleIndex	= -1;	// particle data surface id
	surfacePongIndex		= -1;
	surfaceSnapshotBuffer	= -1;
	
	snapshotData = undefined;
	
	count = 0;			// number of particles in memory
	countAlive = 0;		// number of particles alive
	countTimer = 0;		// number of iterations processed
	countTell = 0;		// current vertex position
	countOverflowSetting = e_gmpartyOverflow.Upscale;		// upscale if out of texture space
	countUnderflowCorrection = true;
	countUnderflowAllocMin = GMPARTY_DEFAULT_SOLVER_SIZE;	// minimum amount of indices that can be allocated
	countMax = _num;	// allowed maximum n of particles
	countMaxEffective = surfaceSlotSize * surfaceSlotSize;	// effective maximum
	
	countPriority = ds_priority_create();	// priority list of emission events, used in tracking alive particles
	countStack = [];						// stack of emission events, used in tracking active particles
	countMap = {};
	spriteMap = {};
	blendingMap = {};
	
	texBindings = undefined;
	texBindingsObsolete = true;
	
	translateX = 0;
	translateY = 0;
	translateZ = 0;
	
	drawFTBParticles = 0;
	drawFTBBuffers = 0;
	
	/// Returns a valid and existing surface to be used for particle data.
	/// @return {Id.Surface}
	static getSurfaceParticle = function() {
		surfaceParticleIndex = utils.surfPrep(surfaceParticleIndex, surfaceTexSize, surfaceTexSize, __surfaceFormat);
		return surfaceParticleIndex;
	}
	/// Returns a valid and existing surface to be used as a ping-pong framebuffer.
	/// @return {Id.Surface}
	static getSurfacePong = function() {
		surfacePongIndex = utils.surfPrep(surfacePongIndex, surfaceTexSize, surfaceTexSize, __surfaceFormat);
		return surfacePongIndex;
	}
	/// Executes a ping-pong framebuffer swap.
	static swap = function() {
		var _surf = surfaceParticleIndex;
		surfaceParticleIndex = surfacePongIndex;
		surfacePongIndex = _surf;
	}
	/// Syncs ping-pong framebuffers so they hold the same data.
	static sync = function() {
		gpu_push_state();
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
		surface_set_target(getSurfacePong());
		draw_surface(getSurfaceParticle(), 0, 0);
		surface_reset_target();
		gpu_pop_state();
	}
	/// Returns an array with UVs of specific cell/slot.
	/// @arg {Real} _cell
	/// @return {Array<Real>}
	static getCellUVs = function(_cell) {
		var _x = (_cell % GMPARTY_TEXTURE_GRID_SIZE) / GMPARTY_TEXTURE_GRID_SIZE,
			_y = (_cell div GMPARTY_TEXTURE_GRID_SIZE) / GMPARTY_TEXTURE_GRID_SIZE,
			_d = 1.0 / GMPARTY_TEXTURE_GRID_SIZE;
		return [_x, _y, _x + _d, _y + _d];
	}
	/// Returns maximum number of particles this solver can hold.
	/// @return {real}
	static getCountMax = function() {
		return (countOverflowSetting == e_gmpartyOverflow.Strict) ? countMax : countMaxEffective;
	}
	/// Returns a render vbuffer that can render current amount of data.
	/// @return {Id.VertexBuffer}
	static getRenderBuffer = function() {
		var _num	= count,
			_bid	= clamp(ceil(log2(_num)) - ceil(log2(GMPARTY_RENDER_MIN)), 0, GMPARTY_RENDER_BUFFERS-1);	// clamp to __vbufferRenderList indices
		return __vbufferRenderList[_bid];
	}
	/// Returns true if this solver has a viable non-volatile particle data snapshot
	/// @return {Bool}
	static snapshotExists = function() {
		if is_undefined(utils.surfSnapGet(surfaceParticleIndex)) {
			return false;
		}
		return true;
	}
	/// Saves the current state of the solver to non-volatile memory.
	/// @return {Bool}
	static snapshotWrite = function() {
		if utils.surfSnapWrite(surfaceParticleIndex) {
			var ctx = self;
			snapshotData = {
				snapCount : ctx.count,
				snapCountTell : ctx.countTell,
				snapCountTimer : ctx.countTimer,
				snapCountMap : json_stringify(ctx.countMap),
				snapSpriteMap : json_stringify(ctx.spriteMap),
				snapCountPrio : gmpartyUtils().pqWrite(ctx.countPriority)
			}
			return true;
		}
		return false;
	}
	/// Reads the last state snapshot if it exists.
	/// @return {Bool}
	static snapshotRead = function() {
		if utils.surfSnapRead(surfaceParticleIndex) {
			if !is_undefined(snapshotData) {
				count = snapshotData.snapCount;
				countTell = snapshotData.snapCountTell;
				countTimer = snapshotData.snapCountTimer;
				countMap = json_parse(snapshotData.snapCountMap);
				spriteMap = json_parse(snapshotData.snapSpriteMap);
				countPriority = gmpartyUtils().pqRead(snapshotData.snapCountPrio);
				texBindingsObsolete = true;
				return true;
			}
		}
		return false;
	}
	static snapshotFree = function() {
		return utils.surfSnapFree(surfaceParticleIndex);
	}
	/// Adds a {_num} amount of {_pindex} particles indices to the solver.
	/// @arg {Real} _pindex
	/// @arg {Real} _num
	static addIndices = function(_pindex, _num) {
		var _lookup = countMap[$ _pindex];
		if is_undefined(_lookup) {
			countMap[$ _pindex] = _num;
			texBindingsObsolete = true;
		}	else	{
			countMap[$ _pindex] += _num;
		}
		return true;
	}
	/// Removes a {_num} amount of {_pindex} particles indices from the solver.
	/// @arg {Real} _pindex
	/// @arg {Real} _num
	static removeIndices = function(_pindex, _num) {
		var _lookup = countMap[$ _pindex];
		if is_undefined(_lookup) return false;
		var _total = _lookup - _num;
		if _total <= 0 {
			variable_struct_remove(countMap, _pindex);
			texBindingsObsolete = true;
		}	else	{
			countMap[$ _pindex] = _total;
		}
		return true;
	}
	/// Adds a {_num} amount of {_spr} Asset.GMSprite bindings to the solver.
	/// @arg {Asset.GMSprite} _spr
	/// @arg {Real} _num
	static addSpriteBinding = function(_spr, _num) {
		_spr = sprite_get_name(_spr);
		var _lookup = spriteMap[$ _spr];
		if is_undefined(_lookup) {
			spriteMap[$ _spr] = _num;
			texBindingsObsolete = true;
		}	else	{
			spriteMap[$ _spr] += _num;
		}
		return true;
	}
	/// Removes a {_num} amount of {_spr} Asset.GMSprite bindings from the solver.
	/// @arg {Asset.GMSprite} _spr
	/// @arg {Real} _num
	static removeSpriteBinding = function(_spr, _num) {
		_spr = sprite_get_name(_spr);
		var _lookup = spriteMap[$ _spr];
		if is_undefined(_lookup) return false;
		var _total = _lookup - _num;
		if _total <= 0 {
			variable_struct_remove(spriteMap, _spr);
			texBindingsObsolete = true;
		}	else	{
			spriteMap[$ _spr] = _total;
		}
		return true;
	}
	/// Adds a {_num} amount of {_bmode} Constant.BlendMode bindings to the solver.
	/// @arg {Constant.BlendMode} _bmode
	/// @arg {Real} _num
	static addBlendBinding = function(_bmode, _num) {
		if (_bmode == bm_normal) return false;
		var _lookup = blendingMap[$ _bmode];
		if is_undefined(_lookup) {
			blendingMap[$ _bmode] = _num;
		}	else	{
			blendingMap[$ _bmode] += _num;
		}
		return true;
	}
	/// Removes a {_num} amount of {_bmode} Constant.BlendMode bindings from the solver.
	/// @arg {Constant.BlendMode} _bmode
	/// @arg {Real} _num
	static removeBlendBinding = function(_bmode, _num) {
		if (_bmode == bm_normal) return false;
		var _lookup = blendingMap[$ _bmode];
		if is_undefined(_lookup) return false;
		var _total = _lookup - _num;
		if _total <= 0 {
			variable_struct_remove(blendingMap, _bmode);
		}	else	{
			blendingMap[$ _bmode] = _total;
		}
		return true;
	}
	/// Reallocate particle framebuffer memory, mainly to upscale/downscale it while preserving data.
	/// @arg {Real} _alloc
	/// @arg {Real} _offset
	static realloc = function(_alloc) {
		var _ctexsize = surfaceTexSize,
			_cslotsize = surfaceSlotSize,
			_cgridsize = GMPARTY_TEXTURE_GRID_SIZE;
		var _src = getSurfaceParticle(),
			_dest = getSurfacePong();
		_alloc = min(_alloc, GMPARTY_TEXTURE_INDEX_COUNT);
		surfaceSlotSize	= __getAllocSize(_alloc);
		surfaceTexSize = surfaceSlotSize * GMPARTY_TEXTURE_GRID_SIZE;
		utils.surfSnapFree(_src);
		utils.surfFree(_dest);
		gpu_push_state();
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
		var _shader = GMParty_shd_rescale;
		utils.shaderPush(_shader);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpSrcSize"), _ctexsize, _cslotsize, _cgridsize );
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpDestSize"), surfaceTexSize, surfaceSlotSize, GMPARTY_TEXTURE_GRID_SIZE );
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpOffset"), countTell, count);
		gpu_set_tex_filter_ext(shader_get_sampler_index(_shader, "gm_BaseTexture"), false);
		surface_set_target(getSurfacePong());
		draw_surface_stretched(_src, 0, 0, surfaceTexSize, surfaceTexSize);
		utils.shaderPop();
		surface_reset_target();
		gpu_pop_state();
		swap();
		countTell = count;
		countMax = _alloc;
		countMaxEffective = surfaceSlotSize * surfaceSlotSize;
	}
	/// Emits a {_num} number of {_part} particles to this solver, while optionally passing a {_emitter} wrapper
	/// @arg {Struct} _part
	/// @arg {Real} _num
	/// @arg {Struct} _emitter
	static emit = function(_part, _num, _emitter = {}) {
		// Shader uniforms
		var _shader	= GMParty_shd_emit;
		static uIndexOffset = shader_get_uniform(GMParty_shd_emit, "u_uIndexOffset");
		static uIndexOffset = shader_get_uniform(GMParty_shd_emit, "u_uIndexOffset");
		static uSize = shader_get_uniform(GMParty_shd_emit, "u_uSize");
		static uIndexCount = shader_get_uniform(GMParty_shd_emit, "u_uIndexCount");
		static uSeed = shader_get_uniform(GMParty_shd_emit, "u_uSeed");
		static uParticleColor0 = shader_get_uniform(GMParty_shd_emit, "u_uParticleColor0");
		static uParticleColor1 = shader_get_uniform(GMParty_shd_emit, "u_uParticleColor1");
		static uParticleColor2 = shader_get_uniform(GMParty_shd_emit, "u_uParticleColor2");
		static uParticleColor3 = shader_get_uniform(GMParty_shd_emit, "u_uParticleColor3");
		static uParticlePosStart = shader_get_uniform(GMParty_shd_emit, "u_uParticlePosStart");
		static uParticlePosEnd = shader_get_uniform(GMParty_shd_emit, "u_uParticlePosEnd");
		static uParticleSize = shader_get_uniform(GMParty_shd_emit, "u_uParticleSize");
		static uParticleOrientMin = shader_get_uniform(GMParty_shd_emit, "u_uParticleOrientMin");
		static uParticleOrientMax = shader_get_uniform(GMParty_shd_emit, "u_uParticleOrientMax");
		static uParticleOrientDeltaMin = shader_get_uniform(GMParty_shd_emit, "u_uParticleOrientDeltaMin");
		static uParticleOrientDeltaMax = shader_get_uniform(GMParty_shd_emit, "u_uParticleOrientDeltaMax");
		static uParticleOrientWiggle = shader_get_uniform(GMParty_shd_emit, "u_uParticleOrientWiggle");
		static uParticleRotMin = shader_get_uniform(GMParty_shd_emit, "u_uParticleRotMin");
		static uParticleRotMax = shader_get_uniform(GMParty_shd_emit, "u_uParticleRotMax");
		static uParticleRotWiggle = shader_get_uniform(GMParty_shd_emit, "u_uParticleRotWiggle");
		static uParticleDirMin = shader_get_uniform(GMParty_shd_emit, "u_uParticleDirMin");
		static uParticleDirMax = shader_get_uniform(GMParty_shd_emit, "u_uParticleDirMax");
		static uParticleSpeed = shader_get_uniform(GMParty_shd_emit, "u_uParticleSpeed");
		static uParticleXScale = shader_get_uniform(GMParty_shd_emit, "u_uParticleXScale");
		static uParticleYScale = shader_get_uniform(GMParty_shd_emit, "u_uParticleYScale");
		static uParticleZScale = shader_get_uniform(GMParty_shd_emit, "u_uParticleZScale");
		static uParticleImage = shader_get_uniform(GMParty_shd_emit, "u_uParticleImage");
		static uParticleImageSpeed = shader_get_uniform(GMParty_shd_emit, "u_uParticleImageSpeed");
		static uParticleBlendMode = shader_get_uniform(GMParty_shd_emit, "u_uParticleBlendMode");
		static uParticleLife = shader_get_uniform(GMParty_shd_emit, "u_uParticleLife");
		static uParticleMass = shader_get_uniform(GMParty_shd_emit, "u_uParticleMass");
		static uParticleRestitution = shader_get_uniform(GMParty_shd_emit, "u_uParticleRestitution");
		static uParticleGravity = shader_get_uniform(GMParty_shd_emit, "u_uParticleGravity");
		static uParticleGravityNormal = shader_get_uniform(GMParty_shd_emit, "u_uParticleGravityNormal");
		static uParticleFlags = shader_get_uniform(GMParty_shd_emit, "u_uParticleFlags");
		static uEmitter = shader_get_uniform(GMParty_shd_emit, "u_uEmitter");
		static uEmitterRange = shader_get_uniform(GMParty_shd_emit, "u_uEmitterRange");
		static uEmitterTexture = shader_get_uniform(GMParty_shd_emit, "u_uEmitterTexture");
		static uEmitterTextureSize = shader_get_uniform(GMParty_shd_emit, "u_uEmitterTextureSize");
		static uEmitterTextureScale = shader_get_uniform(GMParty_shd_emit, "u_uEmitterTextureScale");
		static uEmitterTextureOffset = shader_get_uniform(GMParty_shd_emit, "u_uEmitterTextureOffset");
		static uEmitterRot = shader_get_uniform(GMParty_shd_emit, "u_uEmitterRot");
		
		
		if (countOverflowSetting == e_gmpartyOverflow.Upscale) {
			var _newcount = count + _num;
			if (_newcount > getCountMax()) && (_newcount < GMPARTY_TEXTURE_INDEX_COUNT) {
				realloc(_newcount);
			}
			else if (countUnderflowCorrection) {
				var _amin = max(_newcount, countUnderflowAllocMin);
				if (__getAllocSize(_amin*1.25) < surfaceSlotSize) {
					realloc(_amin);
				}
			}
		}
		
		gpu_push_state();
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
		gpu_set_tex_filter(false);
		var _bid	= clamp(ceil(log2(_num)), 0, GMPARTY_EMIT_BUFFERS - 1),
			_buff	= __vbufferWriteList[_bid];
		shader_set(_shader);
		shader_set_uniform_f(uIndexOffset, countTell, getCountMax());
		shader_set_uniform_f(uSize, surfaceTexSize, surfaceSlotSize, GMPARTY_TEXTURE_GRID_SIZE);
		shader_set_uniform_f(uIndexCount, _num);
		shader_set_uniform_f(uSeed, _emitter[$"seed"] ?? _part.seed);
		var _ctx1, _ctx2, _ctx3, _ctx4;
		_ctx1 = is_undefined(_emitter[$"color0"]) ? _part : _emitter;
		_ctx2 = is_undefined(_emitter[$"alpha0"]) ? _part : _emitter;
		shader_set_uniform_f(uParticleColor0, _ctx1.color0.min, _ctx1.color0.max, _ctx2.alpha0.min, _ctx2.alpha0.max);
		_ctx1 = is_undefined(_emitter[$"color1"]) ? _part : _emitter;
		_ctx2 = is_undefined(_emitter[$"alpha1"]) ? _part : _emitter;
		shader_set_uniform_f(uParticleColor1, _ctx1.color1.min, _ctx1.color1.max, _ctx2.alpha1.min, _ctx2.alpha1.max);
		_ctx1 = is_undefined(_emitter[$"color2"]) ? _part : _emitter;
		_ctx2 = is_undefined(_emitter[$"alpha2"]) ? _part : _emitter;
		shader_set_uniform_f(uParticleColor2, _ctx1.color2.min, _ctx1.color2.max, _ctx2.alpha2.min, _ctx2.alpha2.max);
		_ctx1 = is_undefined(_emitter[$"color3"]) ? _part : _emitter;
		_ctx2 = is_undefined(_emitter[$"alpha3"]) ? _part : _emitter;
		shader_set_uniform_f(uParticleColor3, _ctx1.color3.min, _ctx1.color3.max, _ctx2.alpha3.min, _ctx2.alpha3.max);
		_ctx1 = is_undefined(_emitter[$"xpos"]) ? _part : _emitter;
		_ctx2 = is_undefined(_emitter[$"ypos"]) ? _part : _emitter;
		_ctx3 = is_undefined(_emitter[$"zpos"]) ? _part : _emitter;
		shader_set_uniform_f(uParticlePosStart, _ctx1.xpos.min, _ctx2.ypos.min, _ctx3.zpos.min);
		shader_set_uniform_f(uParticlePosEnd, _ctx1.xpos.max, _ctx2.ypos.max, _ctx3.zpos.max);
		_ctx1 = is_undefined(_emitter[$"size"]) ? _part : _emitter;
		shader_set_uniform_f(uParticleSize, _ctx1.size.min, _ctx1.size.max, _ctx1.size.delta, _ctx1.size.wiggle);
		_ctx1 = is_undefined(_emitter[$"xorient"]) ? _part : _emitter;
		_ctx2 = is_undefined(_emitter[$"yorient"]) ? _part : _emitter;
		_ctx3 = is_undefined(_emitter[$"zorient"]) ? _part : _emitter;
		_ctx4 = is_undefined(_emitter[$"snapToDirection"]) ? _part : _emitter;
		shader_set_uniform_f(uParticleOrientMin, _ctx1.xorient.min, _ctx2.yorient.min, _ctx3.zorient.min, _ctx4.snapToDirection);
		shader_set_uniform_f(uParticleOrientMax, _ctx1.xorient.max, _ctx2.yorient.max, _ctx3.zorient.max);
		shader_set_uniform_f(uParticleOrientDeltaMin, _ctx1.xorient.deltaMin, _ctx2.yorient.deltaMin, _ctx3.zorient.deltaMin);
		shader_set_uniform_f(uParticleOrientDeltaMax, _ctx1.xorient.deltaMax, _ctx2.yorient.deltaMax, _ctx3.zorient.deltaMax);
		shader_set_uniform_f(uParticleOrientWiggle, _ctx1.xorient.wiggle, _ctx2.yorient.wiggle, _ctx3.zorient.wiggle);
		_ctx1 = is_undefined(_emitter[$"xrot"]) ? _part : _emitter;
		_ctx2 = is_undefined(_emitter[$"yrot"]) ? _part : _emitter;
		_ctx3 = is_undefined(_emitter[$"zrot"]) ? _part : _emitter;
		shader_set_uniform_f(uParticleRotMin, _ctx1.xrot.min, _ctx2.yrot.min, _ctx3.zrot.min);
		shader_set_uniform_f(uParticleRotMax, _ctx1.xrot.max, _ctx2.yrot.max, _ctx3.zrot.max);
		shader_set_uniform_f(uParticleRotWiggle, _ctx1.xrot.wiggle, _ctx2.yrot.wiggle, _ctx3.zrot.wiggle);
		_ctx1 = is_undefined(_emitter[$"xdir"]) ? _part : _emitter;
		_ctx2 = is_undefined(_emitter[$"ydir"]) ? _part : _emitter;
		_ctx3 = is_undefined(_emitter[$"zdir"]) ? _part : _emitter;
		shader_set_uniform_f(uParticleDirMin, _ctx1.xdir.min, _ctx2.ydir.min, _ctx3.zdir.min);
		shader_set_uniform_f(uParticleDirMax, _ctx1.xdir.max, _ctx2.ydir.max, _ctx3.zdir.max);
		_ctx1 = is_undefined(_emitter[$"speed"]) ? _part : _emitter;
		shader_set_uniform_f(uParticleSpeed, _ctx1.speed.min, _ctx1.speed.max, _ctx1.speed.delta, _ctx1.speed.wiggle);
		_ctx1 = is_undefined(_emitter[$"xscale"]) ? _part : _emitter;
		shader_set_uniform_f(uParticleXScale, _ctx1.xscale.min, _ctx1.xscale.max, _ctx1.xscale.delta, _ctx1.xscale.wiggle);
		_ctx1 = is_undefined(_emitter[$"yscale"]) ? _part : _emitter;
		shader_set_uniform_f(uParticleYScale, _ctx1.yscale.min, _ctx1.yscale.max, _ctx1.yscale.delta, _ctx1.yscale.wiggle);
		_ctx1 = is_undefined(_emitter[$"zscale"]) ? _part : _emitter;
		shader_set_uniform_f(uParticleZScale, _ctx1.zscale.min, _ctx1.zscale.max, _ctx1.zscale.delta, _ctx1.zscale.wiggle);
		_ctx1 = is_undefined(_emitter[$"image"]) ? _part : _emitter;
		_ctx2 = is_undefined(_emitter[$"sprite"]) ? _part : _emitter;
		shader_set_uniform_f(uParticleImage, _ctx1.image.min, _ctx1.image.max, _ctx1.image.count, _ctx2.sprite);
		_ctx1 = is_undefined(_emitter[$"imageSpeed"]) ? _part : _emitter;
		shader_set_uniform_f(uParticleImageSpeed, _ctx1.imageSpeed.min, _ctx1.imageSpeed.max, _ctx1.imageSpeed.lifetimeScale);
		_ctx1 = is_undefined(_emitter[$"blendMode"]) ? _part : _emitter;
		shader_set_uniform_f(uParticleBlendMode, _ctx1.blendMode);
		
		_ctx1 = is_undefined(_emitter[$"life"]) ? _part : _emitter;
		shader_set_uniform_f(uParticleLife, _ctx1.life.min, _ctx1.life.max, _part.index);
		_ctx1 = is_undefined(_emitter[$"mass"]) ? _part : _emitter;
		shader_set_uniform_f(uParticleMass, _ctx1.mass.min, _ctx1.mass.max);
		_ctx1 = is_undefined(_emitter[$"restitution"]) ? _part : _emitter;
		shader_set_uniform_f(uParticleRestitution, _ctx1.restitution.min, _ctx1.restitution.max);
		_ctx1 = is_undefined(_emitter[$"gravityIntensity"]) ? _part : _emitter;
		shader_set_uniform_f(uParticleGravity, _ctx1.gravityIntensity.min, _ctx1.gravityIntensity.max);
		_ctx1 = is_undefined(_emitter[$"gravityDirection"]) ? _part : _emitter;
		shader_set_uniform_f(uParticleGravityNormal, _ctx1.gravityDirection.x, _ctx1.gravityDirection.y, _ctx1.gravityDirection.z);
		
		_ctx1 = is_undefined(_emitter[$"flags"]) ? _part : _emitter;
		shader_set_uniform_i(uParticleFlags, _ctx1.flags);
		_ctx1 = is_undefined(_emitter[$"emitType"]) ? _part : _emitter;
		_ctx2 = is_undefined(_emitter[$"emitDistribution"]) ? _part : _emitter;
		_ctx3 = is_undefined(_emitter[$"emitColorMixing"]) ? _part : _emitter;
		_ctx4 = is_undefined(_emitter[$"emitFire"]) ? _part : _emitter;
		shader_set_uniform_f(uEmitter, _ctx1.emitType, _ctx2.emitDistribution, _ctx3.emitColorMixing, _ctx4.emitFire);
		_ctx1 = is_undefined(_emitter[$"emitRange"]) ? _part : _emitter;
		shader_set_uniform_f(uEmitterRange, _ctx1.emitRange.min, _ctx1.emitRange.max);
		_ctx1 = is_undefined(_emitter[$"emitTarget"]) ? _part : _emitter;
		_ctx2 = is_undefined(_emitter[$"emitScale"]) ? _part : _emitter;
		_ctx3 = is_undefined(_emitter[$"emitOffset"]) ? _part : _emitter;
		if !is_undefined(_ctx1[$"emitTarget"]) {
			texture_set_stage(shader_get_sampler_index(_shader, "u_uEmitterTexture"), surface_get_texture(_ctx1.emitTarget.getEmitter()) );
			shader_set_uniform_f(uEmitterTextureSize, _ctx1.emitTarget.emitter.width, _ctx1.emitTarget.emitter.height, _ctx1.emitTarget.emitter.emitters, 0);
			shader_set_uniform_f_array(uEmitterTextureScale, _ctx2.emitScale);
			shader_set_uniform_f_array(uEmitterTextureOffset, _ctx3.emitOffset);
		}
		_ctx1 = is_undefined(_emitter[$"emitRot"]) ? _part : _emitter;
		var _sy = dsin(-_ctx1.emitRot.yaw),
			_cy = dcos(-_ctx1.emitRot.yaw),
			_sp = dsin(-_ctx1.emitRot.pitch),
			_cp = dcos(-_ctx1.emitRot.pitch),
			_sr = dsin(-_ctx1.emitRot.roll),
			_cr = dcos(-_ctx1.emitRot.roll);
		var _mat = [
		    _cr * _cy + _sr * _sp * _sy, _sr * _cp, -_cr * _sy + _sr * _sp * _cy, 0,
		    -_sr * _cy + _cr * _sp * _sy, _cr * _cp, _sr * _sy + _cr * _sp * _cy, 0,
		    _cp * _sy, -_sp, _cp * _cy, 0,
		    0, 0, 0, 1
		];
		matrix_stack_push(_mat);
		matrix_set(matrix_world, matrix_stack_top());
		shader_set_uniform_matrix(uEmitterRot);
		matrix_stack_pop();
		matrix_set(matrix_world, matrix_stack_top());
		
		surface_set_target(getSurfaceParticle());
		vertex_submit(_buff, pr_pointlist, -1);
		shader_reset();
		surface_reset_target();
		
		gpu_pop_state();
		
		_ctx1 = is_undefined(_emitter[$"seed"]) ? _part : _emitter;
		utils.lcgPush(_ctx1.seed);
		_ctx1.seed = utils.lcgRandomInt() % 65536;
		utils.lcgPop();
		
		_ctx1 = is_undefined(_emitter[$"life"]) ? _part : _emitter;
		_ctx2 = is_undefined(_emitter[$"sprite"]) ? _part : _emitter;
		_ctx3 = is_undefined(_emitter[$"blendMode"]) ? _part : _emitter;
		var _ttl = countTimer + _ctx1.life.max;
		var _entry = {
				ttl : _ttl,
				index : _ctx1.index,
				sprite : _ctx2.sprite,
				blendMode : _ctx3.blendMode,
				count : _num
			};
		ds_priority_add(countPriority, _entry, _ttl);
		array_push(countStack, _entry);
		addIndices(_ctx1.index, _num);
		addSpriteBinding(_ctx2.sprite, _num);
		addBlendBinding(_ctx3.blendMode, _num);
		
		count += _num;
		countAlive += _num;
		countTell = (countTell + _num) % getCountMax();
	}
	/// Process an effector+collider shader programs, optionally targeting a single particle type.
	/// @arg {Struct} _effector
	/// @arg {Struct} _collider
	/// @arg {Real} _pid
	static processEffector = function(_effector, _collider, _pid=undefined) {
		var _pmin = _pid ?? 0,
			_pmax = _pid ?? 0xFFFFFFFF;
		sync();
		_effector.ping(self);
		shader_set_uniform_f(shader_get_uniform(shader_current(), "ugmpParticleTypeRange"), _pmin, _pmax);
		_collider.bindColliderType();
		_collider.bindColliderUniforms();
		_effector.submit(self);
		_effector.pong(self);
	}
	/// Process every component of every particle bound to this solver.
	static processComponentParticles = function() {
		var _ids = variable_struct_get_names(countMap),
			_len = array_length(_ids);
		var _proc = false;
		for(var i = 0; i < _len; i ++) {
			var _pid = real(_ids[i]),
				_part = utils.particleFromId(_pid);
			if is_undefined(_part) {
				continue;
			}
			var _cids = variable_struct_get_names(_part.effectorComponents),
				_clen = array_length(_cids);
			for(var j = 0; j < _clen; j ++) {
				var _comp = _part.componentGet(_cids[j]);
				if is_undefined(_comp) {
					continue;
				}
				processEffector(_comp.effectorRef, _comp.colliderRef, _pid);
				_proc = true;
			}
		}
		if (_proc) {
			sync();
		}
	}
	/// Process a single step of particle simulation.
	static process = function() {
		if (count <= 0) {
			countTimer = 0;
			exit;
		}
		
		processComponentParticles();
		
		gpu_push_state();
		gpu_set_tex_filter(false);
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
		var _shader	= GMParty_shd_step;
		shader_set(_shader);
		shader_set_uniform_f(shader_get_uniform(_shader, "u_uSize"), surfaceTexSize, surfaceSlotSize, GMPARTY_TEXTURE_GRID_SIZE);
		surface_set_target(getSurfacePong());
		draw_surface(getSurfaceParticle(), 0, 0);
		shader_reset();
		surface_reset_target();
		gpu_pop_state();
		
		swap();
		
		if !ds_priority_empty(countPriority) {
			var _pr = ds_priority_find_min(countPriority);
			while (_pr.ttl < countTimer) {
				countAlive -= _pr.count;
				removeIndices(_pr.index, _pr.count);
				removeSpriteBinding(_pr.sprite, _pr.count);
				removeBlendBinding(_pr.blendMode, _pr.count);
				ds_priority_delete_min(countPriority);
				_pr = ds_priority_find_min(countPriority);
				if ds_priority_empty(countPriority) break;
			}
		}
		
		var _slen = array_length(countStack);
		if (_slen > 0) {
			var _str;
			for(var i = 0; i < _slen; i ++) {
				_str = countStack[i];
				if (_str.ttl < countTimer) {
					count -= _str.count;
				} else {
					break;
				}
			}
			array_delete(countStack, 0, i);
		}
		
		countTimer++;
	}
	/// Returns all texture bindings and data required for render step.
	static prepTexBindings = function() {
		var _names = variable_struct_get_names(spriteMap),
			_len = array_length(_names);
		var _tb = [];
		for (var i = 0; i < _len; i++) {
			_tb[i] = utils.texdataLookup(_names[i]);
		}
		return _tb;
	}
	/// Stages samplers and sets uniforms to passed {_shader} Asset.GMShader from {_tb} texture bindings in a specific {_index} index.
	/// @arg {Asset.GMShader} _shader
	/// @arg {Array} _tb
	/// @arg {Real} _index
	static uniformsFromTexBindings = function(_shader, _tb, _index) {
		// stage all textures to fragment shader
		var _bind = _tb[_index];
		var _len = array_length(_bind.textures);
		var _tex;
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpSpriteIndex"), _bind.sprite_index);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpTextureNum"), _len);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpImageNum"), _bind.image_number, _bind.image_per_sampler, _bind.image_per_row);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpImageOffset"), -_bind.sprite_xoffset, -_bind.sprite_yoffset, _bind.sprite_width - _bind.sprite_xoffset, _bind.sprite_height - _bind.sprite_yoffset);
		for(var i = 0; i < _len; i ++) {
			_tex = _bind.textures[i];
			if !sprite_exists(_tex.texture) {
				texBindingsObsolete = true;
				continue;
			}
			utils.glShaderStageFS(shader_get_sampler_index(_shader, string("ugmpTexture{0}", i)), sprite_get_texture(_tex.texture, 0));
			shader_set_uniform_f(shader_get_uniform(_shader, string("ugmpTextureSize{0}", i)), _tex.texture_width, _tex.texture_height, _tex.uv_width, _tex.uv_height);
		}
	}
	/// Updates the camera values needed for 3d projection
	/// @arg {Real} _cx
	/// @arg {Real} _cy
	/// @arg {Real} _cz
	static renderSetCamera = function(_cx, _cy, _cz) {
		__CamX = _cx;
		__CamY = _cy;
		__CamZ = _cz;
	}
	/// Renders the solver, optionally you can pass a custom {_shader} Asset.GMShader.
	/// @arg {Asset.GMshader} _shader
	static render = function(_shader=GMParty_shd_render_2D) {
		var _bmode = gpu_get_blendmode();
		
		if is_undefined(texBindings) {
			texBindingsObsolete = true;
		}
		if texBindingsObsolete {
			texBindings = prepTexBindings();
			texBindingsObsolete = false;
		}
		
		var _rbuffer = getRenderBuffer();
		shader_set(_shader);
		utils.glShaderStageVS(shader_get_sampler_index(_shader, "ugmpParticleData"), surface_get_texture(getSurfaceParticle()));
		gpu_set_tex_filter_ext(shader_get_sampler_index(_shader, "ugmpParticleData"), false);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpSize"), surfaceTexSize, surfaceSlotSize, GMPARTY_TEXTURE_GRID_SIZE);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpIndexTell"), countTell);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpIndexCount"), count);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpIndexFTB"), drawFTBParticles);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpSysTranslate"), translateX, translateY, translateZ);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpBlendMode"), _bmode);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpTime"), countTimer);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpTimeFrequency"), 0.33);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpCamLookat"), __CamX, __CamY, __CamZ);
		
		var _len = array_length(texBindings);
		for(var i = 0; i < _len; i ++) {
			var _ftbi = drawFTBBuffers ? _len - 1 - i : i;
			uniformsFromTexBindings(_shader, texBindings, _ftbi);
			vertex_submit(_rbuffer, pr_trianglelist, -1);
			var _blends = variable_struct_get_names(blendingMap);
			var _blendlen = array_length(_blends);
			for(var j = 0; j < _blendlen; j ++) {
				var _blendcurrent = real(_blends[j]);
				gpu_set_blendmode(_blendcurrent);
				shader_set_uniform_f(shader_get_uniform(_shader, "ugmpBlendMode"), _blendcurrent);
				vertex_submit(_rbuffer, pr_trianglelist, -1);
			}
			if (_blendlen != 0) {
				shader_set_uniform_f(shader_get_uniform(_shader, "ugmpBlendMode"), _bmode);
				gpu_set_blendmode(_bmode);
			}
		}
		shader_reset();
	}
	/// Clears solver particle data.
	static clear = function() {
		count = 0;
		ds_priority_clear(countPriority);
		countMap = {};
		spriteMap = {};
		blendingMap = {};
		texBindings = undefined;
		texBindingsObsolete = true;
	}
	/// Frees solver data from memory.
	static free = function() {
		utils.surfSnapFree(surfaceParticleIndex);
		utils.surfFree(surfaceParticleIndex);
		utils.surfFree(surfacePongIndex);
		ds_priority_destroy(countPriority);
	}
}

/// Creates a new particle type.
function GMPartyType() constructor {
	static utils = gmpartyUtils();
	static PUID = 0;
	index = PUID++;
	utils.particleAddRef(index, self);
	
	flags = e_gmpartyPartFlag.WiggleOscillate | e_gmpartyPartFlag.WiggleRangeSymmetry;
	
	#region Particle variables (can be decorated)
	
	emitType = e_gmpartyEmitShape.Box;
	emitTarget = undefined;
	emitScale = [1.0, 1.0, 1.0];
	emitOffset = [0.0, 0.0, 0.0, 0.0];
	
	emitDistribution = e_gmpartyEmitDistribution.Linear;
	emitColorMixing	= e_gmpartyMixing.Vector;
	emitFire = e_gmpartyEmitFire.Absolute;
	emitRot = {
		yaw : 0.0,
		pitch : 0.0,
		roll : 0.0
	}
	emitRange = {
		min : 0.0,
		max : 1.0
	}
	
	seed = utils.lcgRandomInt();
	
	life = {
		min : 100,
		max : 100
	}
	
	speed = {
		min : 0.0,
		max : 0.0,
		delta : 0.0,
		wiggle : 0.0
	}
	
	xpos = {
		min : 0,
		max : 0
	}
	ypos = {
		min : 0,
		max : 0
	}
	zpos = {
		min : 0,
		max : 0
	}
	
	xscale = {
		min : 1,
		max : 1,
		delta : 0,
		wiggle : 0
	}
	yscale = {
		min : 1,
		max : 1,
		delta : 0,
		wiggle : 0
	}
	zscale = {
		min : 1,
		max : 1,
		delta : 0,
		wiggle : 0
	}
	size = {
		min : 1.0,
		max : 1.0,
		delta : 0.0,
		wiggle : 0.0
	}
	
	snapToDirection	= false;
	xorient = {
		min : 0,
		max : 0,
		deltaMin : 0,
		deltaMax : 0,
		wiggle : 0
	}
	yorient = {
		min : 0,
		max : 0,
		deltaMin : 0,
		deltaMax : 0,
		wiggle : 0
	}
	zorient = {
		min : 0,
		max : 0,
		deltaMin : 0,
		deltaMax : 0,
		wiggle : 0
	}
	
	xrot = {
		min : 0,
		max : 0,
		wiggle : 0
	}
	yrot = {
		min : 0,
		max : 0,
		wiggle : 0
	}
	zrot = {
		min : 0,
		max : 0,
		wiggle : 0
	}
	
	xdir = {
		min : 0,
		max : 0
	}
	ydir = {
		min : 0,
		max : 0
	}
	zdir = {
		min : 0,
		max : 0
	}
	
	color0 = {
		min : c_white,
		max : c_white
	}
	color1 = {
		min : -1,
		max : -1
	}
	color2 = {
		min : -1,
		max : -1
	}
	color3 = {
		min : -1,
		max : -1
	}
	alpha0 = {
		min : 1.0,
		max : 1.0
	}
	alpha1 = {
		min : -1.0,
		max : -1.0
	}
	alpha2 = {
		min : -1.0,
		max : -1.0
	}
	alpha3 = {
		min : -1.0,
		max : -1.0
	}
	
	sprite = GMPARTY_SHAPE_SPRITE_INDEX;
	blendMode = bm_normal;
	
	image = {
		min : 0,
		max : 0,
		count : 14
	}
	imageSpeed = {
		min : 0.0,
		max : 0.0,
		lifetimeScale : false
	}
	
	mass = {
		min : 1.0,
		max : 1.0
	}
	restitution = {
		min : 0.85,
		max : 0.85
	}
	gravityIntensity = {
		min : 0.0,
		max : 0.0
	}
	gravityDirection = {
		x : 0.0,
		y : 1.0,
		z : 0.0
	}
	#endregion
	
	effectorComponents = {};
	/// Sets a particle component with a given {_key} string to execute effector/collider shader programs.
	/// @arg {String} _key
	/// @arg {Struct} _effectorRef
	/// @arg {Struct} _colliderRef
	static componentSet = function(_key, _effectorRef, _colliderRef) {
		var _effstr = {
			effectorRef : _effectorRef,
			colliderRef : _colliderRef
		}
		effectorComponents[$ _key] = _effstr;
	}
	/// Returns a component struct from a given {_key} string.
	/// @arg {String} _key
	/// @return {Struct}
	static componentGet = function(_key) {
		return effectorComponents[$ _key];
	}
	/// Removes a component with a given {_key} string.
	/// @arg {String} _key
	static componentRemove = function(_key) {
		variable_struct_remove(effectorComponents, _key);
	}
}

/// Creates a decorator object that can be passed to override particle type values during emission.
function GMPartyDecorator() constructor {
	// @TODO
}

//------------------------------------------------------------//
// Colliders
enum e_gmpartyColShape {
	Box,
	Sphere,
	Cylinder,
	Pill,
	Texture2D,
	TextureFaux3D,
	Heightmap
}

/// @ignore
function GMPartyColliderPrototype() constructor {
	type = undefined;
	
	distanceMultiplier = [0.0, 1.0];
	
	static bindColliderType = function() {
		var _shader = shader_current();
		shader_set_uniform_i(shader_get_uniform(_shader, "ugmpShapeType"),	type);
		shader_set_uniform_f_array(shader_get_uniform(_shader, "ugmpShapeDistMult"),	distanceMultiplier);
	}
}
/// Creates a global collider affecting all particles during effector execution.
function GMPartyColliderGlobal() : GMPartyColliderPrototype() constructor {
	type = -1;
	
	static bindColliderUniforms = function() {}
}
/// Creates a box collider at {x} {y} {z} position of {xlen} {ylen} {zlen} size.
function GMPartyColliderBox(_x, _y, _z, _xlen, _ylen, _zlen) : GMPartyColliderPrototype() constructor {
	type = e_gmpartyColShape.Box;
	
	x = _x;
	y = _y;
	z = _z;
	xlen = _xlen;
	ylen = _ylen;
	zlen = _zlen;
	
	static bindColliderUniforms = function() {
		var _shader = shader_current();
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTX1"),	x, y, z, 0);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTX2"),	xlen, ylen, zlen, 0);
	}
}
/// Creates a sphere collider at {x} {y} {z} position with a {radius} radius in pixels.
function GMPartyColliderSphere(_x, _y, _z, _radius) : GMPartyColliderPrototype() constructor {
	type = e_gmpartyColShape.Sphere;
	
	x = _x;
	y = _y;
	z = _z;
	radius =  _radius;
	
	static bindColliderUniforms = function() {
		var _shader = shader_current();
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTX1"),	x, y, z, radius);
	}
}
/// Creates a cylinder collider at {x} {y} {z} starting position, facing {xlen} {ylen} {zlen} and having a specified {radius} radius.
function GMPartyColliderCylinder(_x, _y, _z, _xlen, _ylen, _zlen, _radius) : GMPartyColliderPrototype() constructor {
	type = e_gmpartyColShape.Cylinder;
	
	x = _x;
	y = _y;
	z = _z;
	xlen = _xlen;
	ylen = _ylen;
	zlen = _zlen;
	radius = _radius;
	
	static bindColliderUniforms = function() {
		var _shader = shader_current();
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTX1"),	x, y, z, radius);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTX2"),	xlen, ylen, zlen, 0);
	}
}
/// Creates a pill collider at {x} {y} {z} starting position, facing {xlen} {ylen} {zlen} and having a specified {radius} radius.
function GMPartyColliderPill(_x, _y, _z, _xlen, _ylen, _zlen, _radius) : GMPartyColliderPrototype() constructor {
	type = e_gmpartyColShape.Pill;
	
	x = _x;
	y = _y;
	z = _z;
	xlen = _xlen;
	ylen = _ylen;
	zlen = _zlen;
	radius = _radius;
	
	static bindColliderUniforms = function() {
		var _shader = shader_current();
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTX1"),	x, y, z, radius);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTX2"),	xlen, ylen, zlen, 0);
	}
}
/// Creates a 2-dimensional distance field collider.
function GMPartyColliderSDF2D(_spr, _img, _x, _y, _xscale, _yscale, _angle) : GMPartyColliderPrototype() constructor {
	static utils = gmpartyUtils();
	type = e_gmpartyColShape.Texture2D;
	
	sprite = _spr;
	image = _img;
	x = _x;
	y = _y;
	xscale = _xscale;
	yscale = _yscale;
	angle = _angle;
	
	factor = 2.0;
	
	static bindColliderUniforms = function() {
		var _shader = shader_current();
		var _uvs = sprite_get_uvs(sprite, image);
		var _sdf = utils.sdftexLookup(sprite, image);
		var _offsets = [
			-sprite_get_xoffset(sprite),
			-sprite_get_yoffset(sprite),
			sprite_get_width(sprite) - sprite_get_xoffset(sprite),
			sprite_get_height(sprite) - sprite_get_yoffset(sprite)
		]
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTX1"), x, y, xscale, yscale);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTX2"), _offsets[0] * xscale, _offsets[1] * yscale, _offsets[2] * xscale, _offsets[3] * yscale);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTX3"), degtorad(angle), 0, 0, factor);
		gpu_set_tex_filter_ext(shader_get_sampler_index(_shader, "ugmpShapeCTXSampler"), true);
		texture_set_stage(shader_get_sampler_index(_shader, "ugmpShapeCTXSampler"), surface_get_texture(_sdf));
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTXSamplerSize"), surface_get_width(_sdf), surface_get_height(_sdf));
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTXSamplerUVs"),	_uvs[0], _uvs[1], _uvs[2], _uvs[3]);
	}
}
function GMPartyColliderSDF3D(_sdf_data, _x, _y, _z) : GMPartyColliderPrototype() constructor {
	type = e_gmpartyColShape.TextureFaux3D;
	
	sdf_data = _sdf_data;
	x = _x;
	y = _y;
	z = _z;
	xscale = 1;
	yscale = 1;
	zscale = 1;
	
	rotation = [0, 0, 0];
	
	static bindColliderUniforms = function() {
		var _shader = shader_current();
		var _bbox = sdf_data.collider.bbox;
		var _vol = sdf_data.collider.volume;
		var _mult = [
			(_bbox[1][0] - _bbox[0][0]) / _vol[0],
			(_bbox[1][1] - _bbox[0][1]) / _vol[1],
			(_bbox[1][2] - _bbox[0][2]) / _vol[2]
		];
		
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTX1"), x, y, z, _mult[0] * xscale);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTX2"), _bbox[0][0] * xscale, _bbox[0][1] * yscale, _bbox[0][2] * zscale, _mult[1] * yscale);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTX3"), _bbox[1][0] * xscale, _bbox[1][1] * yscale, _bbox[1][2] * zscale, _mult[2] * zscale);
		shader_set_uniform_f_array(shader_get_uniform(_shader, "ugmpShapeCTX4"), rotation);
		gpu_set_tex_filter_ext(shader_get_sampler_index(_shader, "ugmpShapeCTXSampler"), false);
		texture_set_stage(shader_get_sampler_index(_shader, "ugmpShapeCTXSampler"), surface_get_texture(sdf_data.getCollider()));
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTXSamplerSize"), sdf_data.collider.size, sdf_data.collider.size);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTXSamplerUVs"),	_vol[0], _vol[1], _vol[2], 0);
	}
}
function GMPartyColliderHeightmap(_height_data, _x_start, _y_start, _z_start, _x_len, _y_len, _z_len) : GMPartyColliderPrototype() constructor {
	type = e_gmpartyColShape.Heightmap;
	
	height_data = _height_data;
	
	x_start = _x_start;
	y_start = _y_start;
	z_start = _z_start;
	
	x_len = _x_len;
	y_len = _y_len;
	z_len = _z_len;
	
	rotation = 0;
	
	static bindColliderUniforms = function() {
		var _shader = shader_current();
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTX1"), x_start, y_start, z_start, 0);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTX2"), x_len, y_len, z_len, 0);
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTX3"), rotation, 0, 0, 0);
		gpu_set_tex_filter_ext(shader_get_sampler_index(_shader, "ugmpShapeCTXSampler"), true);
		texture_set_stage(shader_get_sampler_index(_shader, "ugmpShapeCTXSampler"), surface_get_texture(height_data.getHeightmap()));
		shader_set_uniform_f(shader_get_uniform(_shader, "ugmpShapeCTXSamplerSize"), height_data.heightmap.size, height_data.heightmap.size);
	}
}

//------------------------------------------------------------//
// Effectors
function GMPartyEffectorPrototype() constructor {
	shader = undefined;
	
	static cellBuffer = vertex_create_buffer();
	static cellFormat = gmpartyUtils().vformatCache([e_vertexComponent.Position2d, e_vertexComponent.Texcoord]);
	static cellSubmit = function(_solver, _cell) {
		var _uvs = _solver.getCellUVs(_cell);
		var _csize = _solver.surfaceTexSize;
		vertex_begin(cellBuffer, cellFormat);
		vertex_position(cellBuffer, _uvs[0] * _csize, _uvs[1] * _csize);
		vertex_texcoord(cellBuffer, _uvs[0], _uvs[1]);
		vertex_position(cellBuffer, _uvs[2] * _csize, _uvs[1] * _csize);
		vertex_texcoord(cellBuffer, _uvs[2], _uvs[1]);
		vertex_position(cellBuffer, _uvs[0] * _csize, _uvs[3] * _csize);
		vertex_texcoord(cellBuffer, _uvs[0], _uvs[3]);
		
		vertex_position(cellBuffer, _uvs[2] * _csize, _uvs[1] * _csize);
		vertex_texcoord(cellBuffer, _uvs[2], _uvs[1]);
		vertex_position(cellBuffer, _uvs[0] * _csize, _uvs[3] * _csize);
		vertex_texcoord(cellBuffer, _uvs[0], _uvs[3]);
		vertex_position(cellBuffer, _uvs[2] * _csize, _uvs[3] * _csize);
		vertex_texcoord(cellBuffer, _uvs[2], _uvs[3]);
		vertex_end(cellBuffer);
		
		vertex_submit(cellBuffer, pr_trianglelist, surface_get_texture(_solver.getSurfaceParticle()));
	}
	
	static ping = function(_solver) {
		gpu_push_state();
		gpu_set_tex_filter(false);
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
	}
	static submit = function(_solver) {}
	static pong = function(_solver) {
		gpu_pop_state();
		_solver.swap();
	}
}
/// Creates a new accelerator which adds {xspeed} {yspeed} {zspeed} velocity to every collected particle.
function GMPartyEffectorAccelerator(_xspeed, _yspeed, _zspeed) : GMPartyEffectorPrototype() constructor {
	xspeed = _xspeed;
	yspeed = _yspeed;
	zspeed = _zspeed;
	
	shader = GMParty_effshd_accelerate;
	
	static ping = function(_solver) {
		gpu_push_state();
		gpu_set_tex_filter(false);
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
		shader_set(shader);
		shader_set_uniform_f(shader_get_uniform(shader, "ugmpSize"),	_solver.surfaceTexSize, _solver.surfaceSlotSize, GMPARTY_TEXTURE_GRID_SIZE);
		shader_set_uniform_f(shader_get_uniform(shader, "ugmpAccel"),	xspeed, yspeed, zspeed);
		shader_set_uniform_f(shader_get_uniform(shader, "ugmpParticleTypeRange"), 0, 0xFFFFFFFF);
	}
	static submit = function(_solver) {
		surface_set_target(_solver.getSurfacePong());
		cellSubmit(_solver, e_gmpartyComponent.Speed);
		surface_reset_target();
		shader_reset();
	}
}
/// Creates a new attractor pulling (or pushing if negative force) every collected particle.
function GMPartyEffectorAttractor(_force, _absolute=false) : GMPartyEffectorPrototype() constructor {
	force = _force;
	absolute = _absolute;
	
	shader = GMParty_effshd_attract;
	
	static ping = function(_solver) {
		gpu_push_state();
		gpu_set_tex_filter(false);
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
		shader_set(shader);
		shader_set_uniform_f(shader_get_uniform(shader, "ugmpSize"),	_solver.surfaceTexSize, _solver.surfaceSlotSize, GMPARTY_TEXTURE_GRID_SIZE);
		shader_set_uniform_f(shader_get_uniform(shader, "ugmpForce"),	force);
		shader_set_uniform_i(shader_get_uniform(shader, "ugmpForceAbsolute"),	absolute);
		shader_set_uniform_f(shader_get_uniform(shader, "ugmpParticleTypeRange"), 0, 0xFFFFFFFF);
	}
	static submit = function(_solver) {
		surface_set_target(_solver.getSurfacePong());
		cellSubmit(_solver, e_gmpartyComponent.Speed);
		surface_reset_target();
		shader_reset();
	}
}
/// Creates a new destructor, removing an amount of life from every collected particle.
function GMPartyEffectorDestructor(_force=0xFFFFFF, _absolute=false) : GMPartyEffectorPrototype() constructor {
	force = _force;
	absolute = _absolute;
	
	shader = GMParty_effshd_destroy;
	
	static ping = function(_solver) {
		gpu_push_state();
		gpu_set_tex_filter(false);
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
		shader_set(shader);
		shader_set_uniform_f(shader_get_uniform(shader, "ugmpSize"),	_solver.surfaceTexSize, _solver.surfaceSlotSize, GMPARTY_TEXTURE_GRID_SIZE);
		shader_set_uniform_f(shader_get_uniform(shader, "ugmpForce"),	force);
		shader_set_uniform_i(shader_get_uniform(shader, "ugmpForceAbsolute"),	absolute);
		shader_set_uniform_f(shader_get_uniform(shader, "ugmpParticleTypeRange"), 0, 0xFFFFFFFF);
	}
	static submit = function(_solver) {
		surface_set_target(_solver.getSurfacePong());
		cellSubmit(_solver, e_gmpartyComponent.Life);
		surface_reset_target();
		shader_reset();
	}
}
/// Creates a new body with which all collected particles can collide.
function GMPartyEffectorCollider(_mass=1.0) : GMPartyEffectorPrototype() constructor {
	mass = _mass;	// @TODO 
	rotation = 0;	// @TODO angular velocity
	xspeed = 0;		// @TODO
	yspeed = 0;
	zspeed = 0;
	
	shader = GMParty_effshd_collide;
	
	static ping = function(_solver) {
		gpu_push_state();
		gpu_set_tex_filter(false);
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
		shader_set(shader);
		shader_set_uniform_f(shader_get_uniform(shader, "ugmpSize"), _solver.surfaceTexSize, _solver.surfaceSlotSize, GMPARTY_TEXTURE_GRID_SIZE);
		shader_set_uniform_f(shader_get_uniform(shader, "ugmpMass"), mass);
		shader_set_uniform_f(shader_get_uniform(shader, "ugmpVelocity"), xspeed, yspeed, zspeed);
		shader_set_uniform_f(shader_get_uniform(shader, "ugmpAngVelocity"), degtorad(rotation) );
		shader_set_uniform_f(shader_get_uniform(shader, "ugmpParticleTypeRange"), 0, 0xFFFFFFFF);
	}
	static submit = function(_solver) {
		surface_set_target(_solver.getSurfacePong());
		cellSubmit(_solver, e_gmpartyComponent.Position);
		cellSubmit(_solver, e_gmpartyComponent.Speed);
		surface_reset_target();
		shader_reset();
	}
}

enum e_gmpePaintMode {
	Nop,			// pass src
	Mix,			// lerp between src and input
	Add,			// add input to src
	Scroll			// add input to src and wrap
}
enum e_gmpePaintSpace {
	RGB,
	HSV				// @TODO
}
/// Creates a new painter effector, processing color operations on each collected particle's individual RGBA components.
function GMPartyEffectorPainter(_input, _modes=undefined, _force=1.0, _space=e_gmpePaintSpace.RGB, _indices=undefined) : GMPartyEffectorPrototype() constructor {
	input = _input;	// per-channel input values
	mode = _modes ?? [e_gmpePaintMode.Mix, e_gmpePaintMode.Mix, e_gmpePaintMode.Mix, e_gmpePaintMode.Mix];	// mix all channels
	force = _force;
	absolute = false;
	space = _space;
	indices = _indices ?? [1, 1, 1, 1];	// affect all 4 particle color values
	
	shader = GMParty_effshd_paint;
	
	static ping = function(_solver) {
		gpu_push_state();
		gpu_set_tex_filter(false);
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
		shader_set(shader);
		shader_set_uniform_f(shader_get_uniform(shader, "ugmpSize"),	_solver.surfaceTexSize, _solver.surfaceSlotSize, GMPARTY_TEXTURE_GRID_SIZE);
		shader_set_uniform_f_array(shader_get_uniform(shader, "ugmpInput"),		input);
		shader_set_uniform_i_array(shader_get_uniform(shader, "ugmpMode"),		mode);
		shader_set_uniform_f(shader_get_uniform(shader, "ugmpForce"),			force);
		shader_set_uniform_i(shader_get_uniform(shader, "ugmpForceAbsolute"),	absolute);
		shader_set_uniform_i(shader_get_uniform(shader, "ugmpSpace"),			space);
		shader_set_uniform_f_array(shader_get_uniform(shader, "ugmpIndices"),	indices);
		shader_set_uniform_f(shader_get_uniform(shader, "ugmpParticleTypeRange"), 0, 0xFFFFFFFF);
	}
	static submit = function(_solver) {
		surface_set_target(_solver.getSurfacePong());
		cellSubmit(_solver, e_gmpartyComponent.Color);
		cellSubmit(_solver, e_gmpartyComponent.Alpha);
		surface_reset_target();
		shader_reset();
	}
}

enum e_gmpeInstruction {
	Nop,		// No operation on this component
	
	Set,		// Set to reg0..reg1 range
	SetCmp,		// Set to reg0 if comparison reg1 passes with values from vector reg2 component reg3
	
	Add,		// Add reg0
	AddCmp,		// Add reg0 if comparison reg1 passes with values from vector reg2 component reg3
	
	Sub,		// Subtract reg0
	SubCmp,		// Subtract reg0 if comparison reg1 passes with values from vector reg2 component reg3
	
	Div,		// Divide with reg0
	DivCmp,		// Divide reg0 if comparison reg1 passes with values from vector reg2 component reg3
	
	Mul,		// Multiply with reg0
	MulCmp,		// Multiply reg0 if comparison reg1 passes with values from vector reg2 component reg3
	
	Clamp,		// Clamp between reg0 and reg1
	ClampCmp,	
	
	LEN
}
enum e_gmpeCmpfunc {
	Nop,
	Less,
	LessEqual,
	Equal,
	Unequal,
	GreaterEqual,
	Greater
}
/// Creates a new custom particle processor.
function GMPartyEffectorProcessor(_cell, _instructions, _reg0=undefined, _reg1=undefined, _reg2=undefined, _reg3=undefined, _reg4=undefined, _reg5=undefined) : GMPartyEffectorPrototype() constructor {
	static utils = gmpartyUtils();
	
	cellTarget = _cell;
	
	shader = GMParty_effshd_processor;
	
	instructions = _instructions; // []
	reg0 = _reg0 ?? [0, 0, 0, 0];
	reg1 = _reg1 ?? [0, 0, 0, 0];
	reg2 = _reg2 ?? [0, 0, 0, 0];
	reg3 = _reg3 ?? [0, 0, 0, 0];
	reg4 = _reg4 ?? [0, 0, 0, 0];
	reg5 = _reg5 ?? [0, 0, 0, 0];
	
	seed = utils.lcgRandomInt();
	
	static ping = function(_solver) {
		gpu_push_state();
		gpu_set_tex_filter(false);
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
		shader_set(shader);
		shader_set_uniform_f(shader_get_uniform(shader, "ugmpSize"),		_solver.surfaceTexSize, _solver.surfaceSlotSize, GMPARTY_TEXTURE_GRID_SIZE);
		shader_set_uniform_i_array(shader_get_uniform(shader, "ugmpOPC"),	instructions);
		shader_set_uniform_f_array(shader_get_uniform(shader, "ugmpREG0"),	reg0);
		shader_set_uniform_f_array(shader_get_uniform(shader, "ugmpREG1"),	reg1);
		shader_set_uniform_f_array(shader_get_uniform(shader, "ugmpREG2"),	reg2);
		shader_set_uniform_f_array(shader_get_uniform(shader, "ugmpREG3"),	reg3);
		shader_set_uniform_f_array(shader_get_uniform(shader, "ugmpREG4"),	reg4);
		shader_set_uniform_f_array(shader_get_uniform(shader, "ugmpREG5"),	reg5);
		shader_set_uniform_f(shader_get_uniform(shader, "ugmpSeed"),		seed);
	}
	static submit = function(_solver) {
		surface_set_target(_solver.getSurfacePong());
		cellSubmit(_solver, cellTarget);
		surface_reset_target();
		shader_reset();
	}
}

//------------------------------------------------------------//
// 3D SDFs
//------------------------------------------------------------//
/// Creates an sdf out of a 3d model by refering to it's vertex buffer,
/// vertex format, target texture size and winding order. SDF buffers
/// (at least those in ram) can be compressed, but bear in mind this
/// diminishes the performance at which they can be resubmitted to vram.
/// @arg {Id.VertexBuffer} _vbuffer
/// @arg {Array<Real<e_vertexComponent>>} _vformat_array
/// @arg {Real} _texsize
/// @arg {Bool} _winding
/// @arg {Bool} _compress
/// @return {Struct.GMPartySDFModel}
function gmpartySDF3DCreate(_vbuffer, _vformat_array, _texsize, _winding=true, _compress=false) {
	var _sdf = new GMPartySDFModel();
	if _sdf.bake(_vbuffer, _vformat_array, _texsize, _winding, _compress) == false {
		return undefined;
	}
	return _sdf;
}
/// Frees an SDF from memory
/// @arg {Struct.GMPartySDFModel} _sdf
/// @return {Bool}
function gmpartySDF3DFree(_sdf) {
	return _sdf.free();
}
/// Saves an SDF to a file.
/// @arg {String} _fname
/// @return {Bool}
function gmpartySDF3DSave(_sdf, _fname) {
	var _buff = _sdf.write();
	buffer_save(_buff, _fname);
	buffer_delete(_buff);
	return true;
}
/// Loads an SDF from a file.
/// NOTE: Parsing and decompressing sdfs often ends up being slower in GM than
/// recreating them in rust. On the other hand, a single uncompressed 4k SDF
/// takes 256mb of memory. These are here for what it's worth, but use with care.
/// @arg {String} _fname
/// @return {Struct.GMPartySDFModel}
function gmpartySDF3DLoad(_fname) {
	var _buff = buffer_load(_fname);
	if _buff <= -1 {
		return undefined;
	}
	var _sdf = new GMPartySDFModel();
	var _result = _sdf.read(_buff);
	if !_result {
		_sdf.free();
		_sdf = undefined;
	}
	buffer_delete(_buff);
	return _sdf;
}

function GMPartySDFModel() constructor {
	static UTILS = gmpartyUtils();
	static __FMTH = 0x1CFB_878C;
	__INIT = false;
	
	collider = {
		texture: -1,
		buffer: -1,
		size: 0,
		bbox: [	[0, 0, 0], [0, 0, 0] ],
		volume: [0, 0, 0],
		scale: [0, 0, 0],
		voxels: 0,
		compressed: false
	}
	emitter = {
		texture: -1,
		width: 0,
		height: 0,
		emitters: 0,
		buffer: -1,
		compressed: false
	}
	
	static bake = function(_vbuffer, _vformat_array, _texsize, _winding, _compress = false) {
		if __INIT return false;
		
		var _json = UTILS.sdf3dCreate(_vbuffer, _vformat_array, _texsize, _winding);
		if is_undefined(_json) return false;
		
		collider = {
			texture: _json.surface,
			buffer: _compress ? buffer_compress(_json.surface_buffer, 0, buffer_get_size(_json.surface_buffer)) : _json.surface_buffer,
			size: _texsize,
			bbox: _json.bbox,
			volume: [_json.xlen, _json.ylen, _json.zlen],
			scale: _json.scale,
			voxels: _json.voxels,
			compressed: _compress
		}
		if _compress {
			buffer_delete(_json.surface_buffer);
		}
		
		emitter = {
			texture: _json.emitter,
			buffer: _compress ? buffer_compress(_json.emitter_buffer, 0, buffer_get_size(_json.emitter_buffer)) : _json.emitter_buffer,
			width: _json.emitter_texture_size,
			height: _json.emitter_texture_size,
			emitters: _json.emitter_count,
			compressed: _compress
		}
		if _compress {
			buffer_delete(_json.emitter_buffer);
		}
		
		delete _json;
		
		__INIT = true;
		
		return true;
	}
	static getCollider = function() {
		if !__INIT return undefined;
		var _result = collider.texture;
		if !surface_exists(collider.texture) {
			collider.texture = surface_create(collider.size, collider.size, surface_rgba32float);
			var _buff = collider.compressed ? buffer_decompress(collider.buffer) : collider.buffer;
			buffer_resize(_buff, collider.size * collider.size * 4 * 4);
			buffer_set_surface(_buff, collider.texture, 0);
			if collider.compressed {
				buffer_delete(_buff);
			}
			_result = collider.texture;
		}
		return _result;
	}
	static getEmitter = function() {
		if !__INIT return undefined;
		var _result = emitter.texture;
		if !surface_exists(emitter.texture) {
			emitter.texture = surface_create(emitter.size, emitter.size, surface_rgba32float);
			var _buff = emitter.compressed ? buffer_decompress(emitter.buffer) : emitter.buffer;
			buffer_resize(_buff, emitter.size * emitter.size * 4 * 4);
			buffer_set_surface(_buff, emitter.texture, 0);
			if emitter.compressed {
				buffer_delete(_buff);
			}
			_result = emitter.texture;
		}
		return _result;
	}
	static write = function() {
		var _b = buffer_create(65536, buffer_grow, 1);
		buffer_write(_b, buffer_u32, __FMTH);
		buffer_write(_b, buffer_u16, collider.size);
		buffer_write(_b, buffer_f32, collider.bbox[0][0]);
		buffer_write(_b, buffer_f32, collider.bbox[0][1]);
		buffer_write(_b, buffer_f32, collider.bbox[0][2]);
		buffer_write(_b, buffer_f32, collider.bbox[1][0]);
		buffer_write(_b, buffer_f32, collider.bbox[1][1]);
		buffer_write(_b, buffer_f32, collider.bbox[1][2]);
		buffer_write(_b, buffer_u16, collider.volume[0]);
		buffer_write(_b, buffer_u16, collider.volume[1]);
		buffer_write(_b, buffer_u16, collider.volume[2]);
		buffer_write(_b, buffer_f32, collider.scale[0]);
		buffer_write(_b, buffer_f32, collider.scale[1]);
		buffer_write(_b, buffer_f32, collider.scale[2]);
		buffer_write(_b, buffer_u32, collider.voxels);
		buffer_write(_b, buffer_u8, collider.compressed);
		var _size = buffer_get_size(collider.buffer);
		buffer_write(_b, buffer_u32, _size);
		buffer_copy(collider.buffer, 0, _size, _b, buffer_tell(_b));
		buffer_seek(_b, buffer_seek_relative, _size);
		
		buffer_write(_b, buffer_u16, emitter.size);
		buffer_write(_b, buffer_u32, emitter.emitters);
		buffer_write(_b, buffer_u8, emitter.compressed);
		_size = buffer_get_size(emitter.buffer);
		buffer_write(_b, buffer_u32, _size);
		buffer_copy(emitter.buffer, 0, _size, _b, buffer_tell(_b));
		buffer_seek(_b, buffer_seek_relative, _size);
		
		buffer_resize(_b, buffer_tell(_b));
		
		return _b;
	}
	static read = function(_buffer) {
		var _b = _buffer;
		var _fmth = buffer_peek(_b, 0, buffer_u32);
		if _fmth != __FMTH {
			// header mismatch
			return false;
		}
		var _bpos = buffer_tell(_b);
		buffer_seek(_b, buffer_seek_start, 4);
		collider.size = buffer_read(_b, buffer_u16);
		collider.bbox[0][0] = buffer_read(_b, buffer_f32);
		collider.bbox[0][1] = buffer_read(_b, buffer_f32);
		collider.bbox[0][2] = buffer_read(_b, buffer_f32);
		collider.bbox[1][0] = buffer_read(_b, buffer_f32);
		collider.bbox[1][1] = buffer_read(_b, buffer_f32);
		collider.bbox[1][2] = buffer_read(_b, buffer_f32);
		collider.volume[0] = buffer_read(_b, buffer_u16);
		collider.volume[1] = buffer_read(_b, buffer_u16);
		collider.volume[2] = buffer_read(_b, buffer_u16);
		collider.scale[0] = buffer_read(_b, buffer_f32);
		collider.scale[1] = buffer_read(_b, buffer_f32);
		collider.scale[2] = buffer_read(_b, buffer_f32);
		collider.voxels = buffer_read(_b, buffer_u32);
		collider.compressed = buffer_read(_b, buffer_u8);
		var _size = buffer_read(_b, buffer_u32);
		if buffer_exists(collider.buffer) {
			buffer_delete(collider.buffer);
		}
		collider.buffer = buffer_create(_size, buffer_fixed, 1);
		buffer_copy(_b, buffer_tell(_b), _size, collider.buffer, 0);
		buffer_seek(collider.buffer, buffer_seek_end, 0);
		buffer_seek(_b, buffer_seek_relative, _size);
		
		emitter.size = buffer_read(_b, buffer_u16);
		emitter.emitters = buffer_read(_b, buffer_u32);
		emitter.compressed = buffer_read(_b, buffer_u8);
		_size = buffer_read(_b, buffer_u32);
		if buffer_exists(emitter.buffer) {
			buffer_delete(emitter.buffer);
		}
		emitter.buffer = buffer_create(_size, buffer_fixed, 1);
		buffer_copy(_b, buffer_tell(_b), _size, emitter.buffer, 0);
		buffer_seek(emitter.buffer, buffer_seek_end, 0);
		//buffer_seek(_b, buffer_seek_relative, _size);
		buffer_seek(_b, buffer_seek_start, _bpos);
		
		__INIT = true;
		
		return true;
	}
	static flush = function() {
		if surface_exists(collider.texture) {
			surface_free(collider.texture);
		}
		if surface_exists(emitter.texture) {
			surface_free(emitter.texture);
		}
	}
	static free = function() {
		if !__INIT return false;
		flush();
		buffer_delete(collider.buffer);
		buffer_delete(emitter.buffer);
		delete collider;
		delete emitter;
		__INIT = false;
		return true;
	}
}

//------------------------------------------------------------//
// Heightmap resources
//------------------------------------------------------------//
/// Creates a Party heightmap resource by baking an sprite
/// onto a texture of desired resolution.
/// @arg {Asset.GMSprite} _sprite
/// @arg {Real} _texsize
/// @return {Struct.GMPartyHeightmap}
function gmpartyHeightmapCreate(_sprite, _texsize) {
	var _hm = new GMPartyHeightmap();
	if _hm.bake(_sprite, _texsize) == false {
		return undefined;
	}
	return _hm;
}
/// Frees a heightmap resource from memory
/// @arg {Struct.GMPartyHeightmap} _heightmap
/// @return {Bool}
function gmpartyHeightmapFree(_heightmap) {
	return _heightmap.free();
}


function GMPartyHeightmap(_sprite) constructor {
	static UTILS = gmpartyUtils();
	__INIT = false;
	
	heightmap = {
		target: -1,
		texture: -1,
		size: 0,
		factor: 1.0
	}
	
	static bake = function(_sprite, _texsize, _factor=1.0) {
		if __INIT return false;
		
		heightmap.target = _sprite;
		heightmap.size = _texsize;
		heightmap.factor = _factor;
		
		__INIT = true;
		return true;
	}
	
	static getHeightmap = function() {
		if !__INIT return undefined;
		
		if !surface_exists(heightmap.texture) {
			heightmap.texture = surface_create(heightmap.size, heightmap.size, surface_rgba32float);
			var _shader = GMParty_shd_heightfield_init;
			gpu_push_state();
			gpu_set_tex_filter(true);
			gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
			UTILS.shaderPush(_shader);
			shader_set_uniform_f(shader_get_uniform(_shader, "ugmpTexsize"), heightmap.size, heightmap.size);
			shader_set_uniform_f(shader_get_uniform(_shader, "ugmpFactor"), heightmap.factor);
			surface_set_target(heightmap.texture);
			draw_sprite_stretched(heightmap.target, 0, 0, 0, heightmap.size, heightmap.size);
			surface_reset_target();
			UTILS.shaderPop();
			gpu_pop_state();
		}
		
		return heightmap.texture;
	}
	
	static flush = function() {
		if surface_exists(heightmap.texture) {
			surface_free(heightmap.texture);
		}
	}
	static free = function() {
		if !__INIT return false;
		flush();
		delete heightmap;
		__INIT = false;
		return true;
	}
}

//------------------------------------------------------------//
// Texture emitter
//------------------------------------------------------------//
/// Creates a texture emitter resource out of GMSprite asset.
/// @arg {Asset.GMSprite} _sprite
/// @return {Struct.GMPartyTextureEmitter}
function gmpartyTextureEmitterCreate(_sprite) {
	var _tex = new GMPartyTextureEmitter();
	if _tex.bake(_sprite) == false {
		return undefined;
	}
	return _tex;
}
/// Frees a texture emitter resource from memory.
/// @arg {Struct.GMPartyTextureEmitter} _texemitter
/// @return {Bool}
function gmpartyTextureEmitterFree(_texemitter) {
	return _texemitter.free();
}

function GMPartyTextureEmitter() constructor {
	static UTILS = gmpartyUtils();
	__INIT = false;
	
	emitter = {
		target: -1,
		texture: -1,
		width: 0,
		height: 0,
		emitters: 0
	}
	
	static bake = function(_sprite) {
		if __INIT return false;
		
		emitter.target = _sprite;
		emitter.width = sprite_get_width(_sprite);
		emitter.height = sprite_get_height(_sprite);
		
		__INIT = true;
		return true;
	}
	static getEmitter = function() {
		if !__INIT return undefined;
		
		if !surface_exists(emitter.texture) {
			emitter.texture = surface_create(emitter.width, emitter.height, surface_rgba32float);
			gpu_push_state();
			var _shader = GMParty_shd_passthrough;
			UTILS.shaderPush(_shader);
			gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
			surface_set_target(emitter.texture);
			draw_sprite(emitter.target, 0, sprite_get_xoffset(emitter.target), sprite_get_yoffset(emitter.target));
			surface_reset_target();
			UTILS.shaderPop();
			gpu_pop_state();
			var _seeds = UTILS.textureEmitterSeed(emitter.texture);
			emitter.emitters = _seeds;
		}
		
		return emitter.texture;
	}
	static flush = function() {
		if surface_exists(emitter.texture) {
			surface_free(emitter.texture);
		}
	}
	static free = function() {
		if !__INIT return false;
		flush();
		delete emitter;
		__INIT = false;
		return true;
	}
}


