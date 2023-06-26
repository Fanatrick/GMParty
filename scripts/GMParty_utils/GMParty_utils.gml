/// Feather disable all
#macro GMPARTY_UTILS_SDF3D (true)
#macro GMPARTY_UTILS_SDF3D_PATH "SDF3D/sdf3d.dll"

enum e_vertexComponent {
	Position2d,
	Position3d,
	Color,
	Texcoord,
	Normal,
	Float1,
	Float2,
	Float3,
	Float4,
	Ubyte4
}

function gmpartyUtils() {
	static __inner = {
		//------------------------------------------------------------//
		// Vertex formats
		vformatMapRef : {},
		vformatCreate : function(_format_array) {
			var _def = vertex_usage_texcoord,	// HTML5 compatibility
				_len = array_length(_format_array);
			vertex_format_begin();
			for(var i = 0; i < _len; i++) {
				var _component = _format_array[i];
				switch(_component) {
					case e_vertexComponent.Position2d:
						vertex_format_add_position();
						break;
					case e_vertexComponent.Position3d:
						vertex_format_add_position_3d();
						break;
					case e_vertexComponent.Color:
						vertex_format_add_color();
						break;
					case e_vertexComponent.Texcoord:
						vertex_format_add_texcoord();
						break;
					case e_vertexComponent.Normal:
						vertex_format_add_normal();
						break;
					case e_vertexComponent.Float1:
						vertex_format_add_custom(vertex_type_float1, _def);
						break;
					case e_vertexComponent.Float2:
						vertex_format_add_custom(vertex_type_float2, _def);
						break;
					case e_vertexComponent.Float3:
						vertex_format_add_custom(vertex_type_float3, _def);
						break;
					case e_vertexComponent.Float4:
						vertex_format_add_custom(vertex_type_float4, _def);
						break;
					case e_vertexComponent.Ubyte4:
						vertex_format_add_custom(vertex_type_ubyte4, _def);
						break;
					default:
						break;
				}
			}
			return vertex_format_end();
		},
		vformatCache : function (_format_array) {
			var _key = string(_format_array),
				_format = self.vformatMapRef[$ _key];
			if is_undefined(_format) {
				_format = self.vformatCreate(_format_array);
				self.vformatMapRef[$ _key] = _format;
			}
			return _format;
		},
		vformatSizeof : function(_component) {
			switch(_component) {
				case e_vertexComponent.Position2d:
					return 8;
				case e_vertexComponent.Position3d:
					return 12;
				case e_vertexComponent.Color:
					return 4;
				case e_vertexComponent.Texcoord:
					return 8;
				case e_vertexComponent.Normal:
					return 12;
				case e_vertexComponent.Float1:
					return 4;
				case e_vertexComponent.Float2:
					return 8;
				case e_vertexComponent.Float3:
					return 12;
				case e_vertexComponent.Float4:
					return 16;
				case e_vertexComponent.Ubyte4:
					return 4;
				default:
					break;
			}
		},
		vformatGetSize : function(_format_array) {
			var _len = array_length(_format_array);
			for(var i = 0, j = 0; i < _len; i ++) {
				j += self.vformatSizeof(_format_array[i]);
			}
			return j;
		},
		vformatGetOffset : function(_format_array, _component) {
			var _len = array_length(_format_array);
			for(var i = 0, j = 0; i < _len; i ++) {
				if _format_array[i] == _component {
					break;
				}
				j += self.vformatSizeof(_format_array[i]);
			}
			return j;
		},
		//------------------------------------------------------------//
		// Surfaces
		surfFormatMapRef : {},
		surfSnapshotMapRef : {},
		surfPrep : function(_surf, _width, _height, _format = surface_rgba32float) {
			var _recreate = false,
				_ret = _surf;
			if surface_exists(_surf) {
				if surface_get_width(_surf) != _width || surface_get_height(_surf) != _height {
					_recreate = true;
				}
				else if _format != self.surfGetFormat(_surf) {
					_recreate = true;
				}
			}	else	{
				// read from snapshot if it exists
				var _snap = self.surfSnapGet(_surf);
				if !is_undefined(_snap) {
					self.surfSnapRead(_surf);
				}	else	{
					_recreate = true;
				}
			}
			if (_recreate) {
				self.surfFree(_surf);
				self.surfSnapFree(_surf);
				var _sdepth = surface_get_depth_disable();
				surface_depth_disable(true);
				_ret = surface_create(_width, _height, _format);
				self.surfSetFormat(_ret, _format);
				surface_depth_disable(_sdepth);
			}
			return _ret;
		},
		surfSetFormat : function(_surf, _format) {
			self.surfFormatMapRef[$ string(_surf)] = _format;
		},
		surfGetFormat : function(_surf) {
			return self.surfFormatMapRef[$ string(_surf)];
		},
		surfGetFormatFragSize : function(_format) {
			switch (_format) {
				case surface_rgba16float:	// channels * bytes
					return 8;
				case surface_rgba32float:
					return 16;
				default:
					throw(string("Unsupported surface format: {0}", _format));
			}
		},
		surfFree : function(_surf) {
			if surface_exists(_surf) {
				variable_struct_remove(self.surfFormatMapRef, _surf);
				surface_free(_surf);
				return true;
			}	else	{
				return false;
			}
		},
		surfSnapWrite : function(_surf) {
			if !surface_exists(_surf) return false;
			var _sw = surface_get_width(_surf),
				_sh = surface_get_height(_surf),
				_fmt = self.surfGetFormat(_surf);
			var _buff = buffer_create(_sw * _sh * self.surfGetFormatFragSize(_fmt), buffer_fixed, 1);
			buffer_get_surface(_buff, _surf, 0);
			surfSnapFree(_surf);
			self.surfSnapshotMapRef[$ _surf] = _buff;
			return true;
		},
		surfSnapRead : function(_surf) {
			var _snap = surfSnapGet(_surf ?? -1);
			if buffer_exists(_snap) {
				buffer_set_surface(_snap, _surf, 0);
				return true;
			}
			return false;
		},
		surfSnapGet : function(_surf) {
			return self.surfSnapshotMapRef[$ _surf];
		},
		surfSnapFree : function(_surf) {
			var _snap = surfSnapGet(_surf ?? -1);
			if buffer_exists(_snap) {
				buffer_delete(self.surfSnapshotMapRef[$ _surf]);
				variable_struct_remove(self.surfSnapshotMapRef, _surf);
				return true;
			}
			return false;
		},
		//------------------------------------------------------------//
		// Particles
		particleRefs : {},
		particleAddRef : function(_pid, _ref) {
			self.particleRefs[$ _pid] = _ref;
		},
		particleFromId : function(_pid) {
			return self.particleRefs[$ _pid];
		},
		//------------------------------------------------------------//
		// Shader stack
		shaderStack : [],
		shaderPush : function(_shader) {
			var _cs = shader_current();
			array_push(self.shaderStack, _cs);
			shader_reset();
			shader_set(_shader);
		},
		shaderPop : function() {
			if (array_length(self.shaderStack) <= 0) {
				return;
			}
			shader_reset();
			shader_set(array_pop(self.shaderStack));
		},
		//------------------------------------------------------------//
		// SDFs
		sdftexLookupTable : {},
		sdftexLookup : function(_sprite, _img, _cutoff=0.0) {
			var _imgc = sprite_get_number(_sprite);
			var _texid = sprite_get_info(_sprite).frames[_img % _imgc].texture;
			var _sdf = self.sdftexLookupTable[$ _texid] ?? -1;
			if !surface_exists(_sdf) {
				_sdf = self.sdftexBake(_texid, _cutoff);
				self.sdftexLookupTable[$ _texid] = _sdf;
			}
			return _sdf;
		},
		sdftexBake : function(_texid, _cutoff) {
			var _texw = 1/texture_get_texel_width(_texid),
				_texh = 1/texture_get_texel_height(_texid);
			var _sf = surface_rgba32float;
			var _surf = surface_create(_texw, _texh, _sf);
			gpu_push_state();
			gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
			// build vb
			var _vform = self.vformatCache([e_vertexComponent.Position2d, e_vertexComponent.Texcoord]);
			var _vbuff = vertex_create_buffer();
			vertex_begin(_vbuff, _vform);
				vertex_position(_vbuff, 0, 0);
				vertex_texcoord(_vbuff, 0.0, 0.0);
				vertex_position(_vbuff, _texw, 0);
				vertex_texcoord(_vbuff, 1.0, 0.0);
				vertex_position(_vbuff, 0, _texh);
				vertex_texcoord(_vbuff, 0.0, 1.0);
				vertex_position(_vbuff, _texw, _texh);
				vertex_texcoord(_vbuff, 1.0, 1.0);
			vertex_end(_vbuff);
			// init state
			surface_set_target(_surf);
			var _shader = GMParty_shd_jfainit;
			self.shaderPush(_shader);
			shader_set_uniform_f(shader_get_uniform(_shader, "ugmpTexsize"), _texw, _texh);
			shader_set_uniform_f(shader_get_uniform(_shader, "ugmpCutoff"), _cutoff);
			vertex_submit(_vbuff, pr_trianglestrip, _texid);
			self.shaderPop();
			surface_reset_target();
			// iterate
			var _ping = _surf,
				_pong = surface_create(_texw, _texh, _sf);
			_shader = GMParty_shd_jfastep;
			self.shaderPush(_shader);
			shader_set_uniform_f(shader_get_uniform(_shader, "ugmpTexsize"), _texw, _texh);
			for(var i = 1, j = log2(max(_texw, _texh)); i <= j; i ++) {
				surface_set_target(_pong);
				shader_set_uniform_f(shader_get_uniform(_shader, "ugmpOffset"), power(2, j-i));
				vertex_submit(_vbuff, pr_trianglestrip, surface_get_texture(_ping));
				surface_reset_target();
				var _sref = _pong;
				_pong = _ping;
				_ping = _sref;
			}
			self.shaderPop();
			// finalize
			_shader = GMParty_shd_jfafin;
			self.shaderPush(_shader);
			shader_set_uniform_f(shader_get_uniform(_shader, "ugmpTexsize"), _texw, _texh);
			surface_set_target(_pong);
			vertex_submit(_vbuff, pr_trianglestrip, surface_get_texture(_ping));
			surface_reset_target();
			self.shaderPop();
			// free, pop, return
			surface_free(_ping);
			gpu_pop_state();
			return _pong;
		},
		sdftexFlush : function() {
			var _names = variable_struct_get_names(self.sdftexLookupTable),
				_len = array_length(_names);
			var _entry;
			for(var i = 0; i < _len; i ++) {
				_entry = self.sdftexLookupTable[$ _names[i]];
				if surface_exists(_entry) {
					surface_free(_entry);
				}
				variable_struct_remove(self.sdftexLookupTable, _names[i]);
			}
		},
		//------------------------------------------------------------//
		// SDF3D
		sdf3dCreate : function(_vbuffer, _vformat_array, _texsize, _wrt = true) {
			static __seed_buffer = external_define(
				GMPARTY_UTILS_SDF3D_PATH,
				"seed_buffer",
				dll_cdecl,
				ty_real,
				4,
				ty_string,
				ty_real,
				ty_string,
				ty_real
			);
			static __seed_config = external_define(
				GMPARTY_UTILS_SDF3D_PATH,
				"seed_config",
				dll_cdecl,
				ty_real,
				3,
				ty_real,
				ty_real,
				ty_real
			);
			static __seed_result_json = external_define(
				GMPARTY_UTILS_SDF3D_PATH,
				"seed_result_json",
				dll_cdecl,
				ty_string,
				0
			);
			var _vbsize = vertex_get_buffer_size(_vbuffer),
				_vcount = vertex_get_number(_vbuffer),
				_pos = self.vformatGetOffset(e_vertexComponent.Position3d);
			if _vcount mod 3 != 0 {
				// vbuffer not a list of triangles
				return undefined;
			}
			var _vfsize = _vbsize / _vcount,
				_vfoffset = self.vformatGetOffset(_vformat_array, e_vertexComponent.Position3d),
				_tris = _vcount div 3;
			if _vfoffset >= _vfsize {
				return undefined;
			}
			
			var _buffer = buffer_create_from_vertex_buffer(_vbuffer, buffer_fixed, 4);
			buffer_set_used_size(_buffer, _vbsize);
			var _target = buffer_create(_texsize * _texsize * 4 * 4, buffer_fixed, 4);
			buffer_set_used_size(_target, _texsize * _texsize * 4 * 4);
			
			external_call(__seed_config, _vfsize div 4, _vfoffset div 4, 0);
			var _seeded = external_call(__seed_buffer, string(buffer_get_address(_buffer)), _vbsize div 4, string(buffer_get_address(_target)), _texsize);
			var _json = external_call(__seed_result_json);
			
			var _json = json_parse(_json);
			
			if _seeded < 0 {
				buffer_delete(_buffer);
				buffer_delete(_target);
				return undefined;
			}
			
			var _surf = surface_create(_texsize, _texsize, surface_rgba32float);
			buffer_set_surface(_target, _surf, 0);
			_json.surface = _surf;
			_json.voxels = _seeded;
			_json.texture_size = _texsize;
			//_json.
			
			var _output = self.sdf3dBake(_json);
			
			_json.surface = _output;
			
			buffer_delete(_buffer);
			buffer_delete(_target);
			
			return _json;
		},
		sdf3dBake : function(_seed_dat) {
			var _surf = _seed_dat.surface,
				_sw = surface_get_width(_surf),
				_sh = surface_get_width(_surf),
				_pong = surface_create(_sw, _sh, surface_rgba32float);
			var _bbox = _seed_dat.bbox,
				_size = [_seed_dat.xlen, _seed_dat.ylen, _seed_dat.zlen];
			gpu_push_state();
			gpu_set_blendmode_ext_sepalpha(bm_one, bm_zero, bm_one, bm_zero);
			
			// erode
			var _shader = GMParty_shd_sdf3d_erode;
			self.shaderPush(_shader);
			shader_set_uniform_f(shader_get_uniform(_shader, "ugmpSdf3dSize"), _sw, _sh);
			shader_set_uniform_f_array(shader_get_uniform(_shader, "ugmpSdf3dVolume"), _size);
			shader_set_uniform_f(shader_get_uniform(_shader, "ugmpSdf3dErode"), 6);
			surface_set_target(_pong);
			draw_surface(_surf, 0, 0);
			surface_reset_target();
			self.shaderPop();
			
			// extrude
			var _shader = GMParty_shd_sdf3d_extrude;
			self.shaderPush(_shader);
			shader_set_uniform_f(shader_get_uniform(_shader, "ugmpSdf3dSize"), _sw, _sh);
			shader_set_uniform_f_array(shader_get_uniform(_shader, "ugmpSdf3dVolume"), _size);
			surface_set_target(_surf);
			draw_surface(_pong, 0, 0);
			surface_reset_target();
			surface_set_target(_pong);
			draw_surface(_surf, 0, 0);
			surface_reset_target();
			self.shaderPop();
			
			// jfa
			_shader = GMParty_shd_sdf3d_jfa; //GMParty_shd_jfastep
			self.shaderPush(_shader);
			shader_set_uniform_f(shader_get_uniform(_shader, "ugmpSdf3dSize"), _sw, _sh);
			shader_set_uniform_f_array(shader_get_uniform(_shader, "ugmpSdf3dVolume"), _size);
			for(var i = 1, j = ceil(log2(max(_size[0], _size[1], _size[2]))); i <= j; i ++) { // max(_size[0], _size[1], _size[2], 
				surface_set_target(_pong);
				shader_set_uniform_f(shader_get_uniform(_shader, "ugmpOffset"), power(2, j-i) );
				draw_surface(_surf, 0, 0);
				surface_reset_target();
				var _sref = _pong;
				_pong = _surf;
				_surf = _sref;
			}
			self.shaderPop();
			
			// finalize
			_shader = GMParty_shd_sdf3d_end;
			self.shaderPush(_shader);
			shader_set_uniform_f(shader_get_uniform(_shader, "ugmpSdf3dSize"), _sw, _sh);
			shader_set_uniform_f_array(shader_get_uniform(_shader, "ugmpSdf3dVolume"), _size);
			surface_set_target(_surf);
			draw_surface(_pong, 0, 0);
			surface_reset_target();
			self.shaderPop();
			// free, pop, return
			surface_free(_pong);
			gpu_pop_state();
			
			return _surf;
		},
		//------------------------------------------------------------//
		// Textures
		texdataLookupTable : {},
		texdataLookup : function(_sprite) {
			var _entry = self.texdataLookupTable[$ _sprite];
			if is_undefined(_entry) {
				_entry = self.texdataBakeSprite(_sprite);
				self.texdataLookupTable[$ _sprite] = _entry;
			}
			return _entry;
		},
		texdataFlush : function() {
			var _names = variable_struct_get_names(self.texdataLookupTable),
				_len = array_length(_names);
			var _entry;
			for(var i = 0; i < _len; i ++) {
				_entry = self.texdataLookupTable[$ _names[i]];
				var _texs = _entry.textures,
					_tlen = array_length(_texs);
				for(var j = 0; j < _tlen; j ++) {
					sprite_delete(_entry.textures[j].texture);
				}
				variable_struct_remove(self.texdataLookupTable, _names[i]);
			}
		},
		texdataBakeSprite : function(_sprite) {
			gpu_push_state();
			gpu_set_tex_filter(false);
			gpu_set_blendmode_ext(bm_one, bm_src_color);
			var _num = sprite_get_number(_sprite),
				_w = sprite_get_width(_sprite),
				_h = sprite_get_height(_sprite),
				_ox = sprite_get_xoffset(_sprite),
				_oy = sprite_get_yoffset(_sprite);
			var _cw = GMPARTY_TEXTURE_SIZE_MAX div _w,
				_ch = GMPARTY_TEXTURE_SIZE_MAX div _h,
				_ct = _cw * _ch;
			var _fitrows = ceil(_num / _cw),
				_fitsurfs = _fitrows / _ch;
			var _surf;
			var _textures = [];
			var _imgn = 0;
			var _imgfirst;
			for(var i = 0; i < _fitsurfs; i ++) {
				var _sw = _w * min(_cw, _num),
					_sh = _h * min(_fitrows - i * _ch, _ch);
				_surf = surface_create(_sw, _sh);
				surface_set_target(_surf);
				var _imgs = [],
					_imgc = min(_num - _imgn, _ct);
				_imgfirst = _imgn;
				for(var j = 0; j < _imgc; j ++) {
					var _sx = j % _cw,
						_sy = j div _cw;
					draw_sprite(_sprite, _imgn, _sx * _w + _ox, _sy * _h + _oy);
					_imgn ++;
				}
				surface_reset_target();
				var _spr = sprite_create_from_surface(_surf, 0, 0, _sw, _sh, 0, 0, 0, 0);
				surface_free(_surf);
				var _tex = {
					index : _sprite,
					texture : _spr,
					texture_width : _sw,
					texture_height : _sh,
					image_number : _imgc,
					image_first : _imgfirst,
					uv_width : _w / _sw,
					uv_height : _h / _sh
				}
				_textures[i] = _tex;
			}
			gpu_pop_state();
			var _output = {
				sprite_index : _sprite,
				image_number : _num,
				image_per_sampler : _ct,
				image_per_row : _cw,
				sprite_width : _w,
				sprite_height : _h,
				sprite_xoffset : _ox,
				sprite_yoffset : _oy,
				textures : _textures
			}
			return _output;
		},
		//------------------------------------------------------------//
		// GL
		glShaderStageVS : function(_sampled_id, _texture_id) {
			//texture_set_stage(_sampled_id, _texture_id);
			texture_set_stage_vs(_sampled_id, _texture_id);
		},
		glShaderStageFS : function(_sampled_id, _texture_id) {
			texture_set_stage(_sampled_id, _texture_id);
		},
		glConfigGet : function() {
			// create struct
			var _struct = {};
		
			var _names = [
				"gl_MaxTextureImageUnits",
				"gl_MaxCombinedTextureImageUnits",
				"gl_MaxDrawBuffers",
				"gl_MaxFragmentUniformVectors",
				"gl_MaxVaryingVectors",
				"gl_MaxVertexAttribs",
				"gl_MaxVertexTextureImageUnits",
				"gl_MaxVertexUniformVectors",
				"__VERSION__",
				"GL_ES",
				"GL_VTF"
			];
			
			// create surface
			var _surf = surface_create(4, 4),
				_shader = GMParty_shd_glconstants;
			gpu_push_state();	
			surface_set_target(_surf);
			draw_clear_alpha(c_black, 0.0);
				shader_set(_shader);
				self.glShaderStageVS(shader_get_sampler_index(_shader, "u_uSamplerVTF"), sprite_get_texture(GMParty_tex_glconstants_vtf, 0) );
					draw_rectangle(0, 0, 4, 4, false);
				shader_reset();
			surface_reset_target();
			gpu_push_state();
			// loop through names and fill the map
			// NOTICE:	surface_getpixel() doesn't suffer from buffer_get_surface() platform
			//			inconsistencies in format (RGBA-BGRA)
			var _len = array_length(_names);
			for(var i = 0; i < _len; i++) {
				var _pixel = surface_getpixel(_surf, i mod 4, i div 4),
					_val = color_get_red(_pixel)*256 + color_get_green(_pixel);
				_struct[$ _names[i] ] = _val;
			}
			
			// free surface
			surface_free(_surf);
			
			return _struct;
		},
		//------------------------------------------------------------//
		// RNG
		lcgSeedStack : [int64(0)],
		lcgConfig : {
			LCG_M	: int64(0xFFFFFFFB),	// mod
			LCG_A	: int64(0x41C64E6D),	// multiplier
			LCG_C	: int64(0x3C6EF35F),	// increment
		},
		lcgPush : function(_seed) {
			array_push(self.lcgSeedStack, int64(_seed));
		},
		lcgPop : function() {
			if array_length(self.lcgSeedStack) < 1 {
				return array_last(self.lcgSeedStack);
			}	else	{
				return array_pop(self.lcgSeedStack);
			}
		},
		lcgSet : function(_seed) {
			self.lcgSeedStack[array_length(self.lcgSeedStack) - 1] = int64(_seed);
		},
		lcgGet : function() {
			return array_last(self.lcgSeedStack);
		},
		lcgClear : function() {
			array_resize(self.lcgSeedStack, 1);
		},
		lcgGetDepth : function() {
			return array_length(self.lcgSeedStack);
		},
		lcgRandom : function(_max = undefined, _iterate = true) {
			_max = _max ?? (self.lcgConfig.LCG_M - 1);
			var _config = self.lcgConfig,
				_seed = self.lcgGet() * _config.LCG_A + _config.LCG_C;
			if _iterate self.lcgSet(_seed);
			var _result = real(abs(_seed) % _config.LCG_M) / real(_config.LCG_M-1) * _max;
			return _result;
		},
		lcgRandomRange : function(_min, _max, _iterate = true) {
			return _min + self.lcgRandom(_max - _min, _iterate);
		},
		lcgRandomInt : function(_max = undefined, _iterate = true) {
			_max = _max ?? (self.lcgConfig.LCG_M - 1);
			var _config = self.lcgConfig,
				_seed = self.lcgGet() * _config.LCG_A + _config.LCG_C;
			if _iterate self.lcgSet(_seed);
			var _result = abs(_seed) % _config.LCG_M;
			return _result % (_max + 1);
		},
		lcgRandomIntRange : function(_min, _max, _iterate = true) {
			return _min + self.lcgRandomInt(_max - _min, _iterate);
		},
		//------------------------------------------------------------//
		// misc
		pqWrite : function(_ds_prio) {
			var _temp_prio = ds_priority_create();
			ds_priority_copy(_temp_prio, _ds_prio);
			var _ret = [];
			var _entry;
			while (ds_priority_size(_temp_prio) > 0) {
				_entry = ds_priority_delete_min(_temp_prio);
				array_push(_ret, _entry);
			}
			ds_priority_destroy(_temp_prio);
			return _ret;
		},
		pqRead : function(_array) {
			var _new_prio = ds_priority_create();
			var _len = array_length(_array);
			for(var i = 0; i < _len; i ++) {
				ds_priority_add(_new_prio, _array[i], _array[i].ttl);
			}
			return _new_prio;
		},
		wrapa : function(_x, _min, _max) {
			if (_x < _min) {
				return (_max - (_min - _x) % (_max - _min));
			}
			return (_min + (_x - _min) % (_max - _min));
		},
	}
	return __inner;
}


