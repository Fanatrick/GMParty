/// Feather disable all
//------------------------------------------------------------//
// overrides
#macro part_system_exists					__part_system_exists
#macro part_system_create					__part_system_create
#macro part_system_create_layer				__part_system_create_layer
#macro part_system_get_layer				__part_system_get_layer
#macro part_system_layer					__part_system_layer
#macro part_system_depth					__part_system_depth
#macro part_system_position					__part_system_position
#macro part_system_clear					__part_system_clear
#macro part_system_destroy					__part_system_destroy
#macro part_particles_clear					__part_particles_clear
#macro part_particles_count					__part_particles_count

#macro part_system_automatic_update			__part_system_automatic_update
#macro part_system_automatic_draw			__part_system_automatic_draw
#macro part_system_update					__part_system_update
#macro part_system_drawit					__part_system_drawit
#macro part_system_draw_order				__part_system_draw_order

#macro part_particles_create				__part_particles_create
#macro part_particles_create_colour			__part_particles_create_colour

#macro part_type_exists						__part_type_exists
#macro part_type_create						__part_type_create
#macro part_type_destroy					__part_type_destroy
#macro part_type_clear						__part_type_clear
#macro part_type_shape						__part_type_shape
#macro part_type_sprite						__part_type_sprite
#macro part_type_size						__part_type_size
#macro part_type_scale						__part_type_scale
#macro part_type_speed						__part_type_speed
#macro part_type_direction					__part_type_direction
#macro part_type_gravity					__part_type_gravity
#macro part_type_orientation				__part_type_orientation
#macro part_type_color_mix					__part_type_color_mix
#macro part_type_color_rgb					__part_type_color_rgb
#macro part_type_color_hsv					__part_type_color_hsv
#macro part_type_color1						__part_type_color1
#macro part_type_color2						__part_type_color2
#macro part_type_color3						__part_type_color3
#macro part_type_colour_mix					__part_type_color_mix
#macro part_type_colour_rgb					__part_type_color_rgb
#macro part_type_colour_hsv					__part_type_color_hsv
#macro part_type_colour1					__part_type_color1
#macro part_type_colour2					__part_type_color2
#macro part_type_colour3					__part_type_color3
#macro part_type_alpha1						__part_type_alpha1
#macro part_type_alpha2						__part_type_alpha2
#macro part_type_alpha3						__part_type_alpha3
#macro part_type_blend						__part_type_blend
#macro part_type_life						__part_type_life
#macro part_type_step						__part_type_step
#macro part_type_death						__part_type_death

#macro part_emitter_exists					__part_emitter_exists
#macro part_emitter_create					__part_emitter_create
#macro part_emitter_clear					__part_emitter_clear
#macro part_emitter_region					__part_emitter_region
#macro part_emitter_burst					__part_emitter_burst
#macro part_emitter_stream					__part_emitter_stream
#macro part_emitter_destroy					__part_emitter_destroy
#macro part_emitter_destroy_all				__part_emitter_destroy_all

//------------------------------------------------------------//
// originals
#macro GM_part_system_exists				part_system_exists
#macro GM_part_system_create				part_system_create
#macro GM_part_system_create_layer			part_system_create_layer
#macro GM_part_system_get_layer				part_system_get_layer
#macro GM_part_system_layer					part_system_layer
#macro GM_part_system_depth					part_system_depth
#macro GM_part_system_position				part_system_position
#macro GM_part_system_clear					part_system_clear
#macro GM_part_system_destroy				part_system_destroy
#macro GM_part_particles_clear				part_particles_clear
#macro GM_part_particles_count				part_particles_count

#macro GM_part_system_automatic_update		part_system_automatic_update
#macro GM_part_system_automatic_draw		part_system_automatic_draw
#macro GM_part_system_update				part_system_update
#macro GM_part_system_drawit				part_system_drawit
#macro GM_part_system_draw_order			part_system_draw_order

#macro GM_part_particles_create				part_particles_create
#macro GM_part_particles_create_colour		part_particles_create_colour

#macro GM_part_type_exists					part_type_exists
#macro GM_part_type_create					part_type_create
#macro GM_part_type_destroy					part_type_destroy
#macro GM_part_type_clear					part_type_clear
#macro GM_part_type_shape					part_type_shape
#macro GM_part_type_sprite					part_type_sprite
#macro GM_part_type_size					part_type_size
#macro GM_part_type_scale					part_type_scale
#macro GM_part_type_speed					part_type_speed
#macro GM_part_type_direction				part_type_direction
#macro GM_part_type_gravity					part_type_gravity
#macro GM_part_type_orientation				part_type_orientation
#macro GM_part_type_color_mix				part_type_color_mix
#macro GM_part_type_color_rgb				part_type_color_rgb
#macro GM_part_type_color_hsv				part_type_color_hsv
#macro GM_part_type_color1					part_type_color1
#macro GM_part_type_color2					part_type_color2
#macro GM_part_type_color3					part_type_color3
#macro GM_part_type_colour_mix				part_type_color_mix
#macro GM_part_type_colour_rgb				part_type_color_rgb
#macro GM_part_type_colour_hsv				part_type_color_hsv
#macro GM_part_type_colour1					part_type_color1
#macro GM_part_type_colour2					part_type_color2
#macro GM_part_type_colour3					part_type_color3
#macro GM_part_type_alpha1					part_type_alpha1
#macro GM_part_type_alpha2					part_type_alpha2
#macro GM_part_type_alpha3					part_type_alpha3
#macro GM_part_type_blend					part_type_blend
#macro GM_part_type_life					part_type_life
#macro GM_part_type_step					part_type_step
#macro GM_part_type_death					part_type_death

#macro GM_part_emitter_exists				part_emitter_exists
#macro GM_part_emitter_create				part_emitter_create
#macro GM_part_emitter_clear				part_emitter_clear
#macro GM_part_emitter_region				part_emitter_region
#macro GM_part_emitter_burst				part_emitter_burst
#macro GM_part_emitter_stream				part_emitter_stream
#macro GM_part_emitter_destroy				part_emitter_destroy
#macro GM_part_emitter_destroy_all			part_emitter_destroy_all

//------------------------------------------------------------//
// part_system

function __part_system_exists(_ind) {
	if instance_exists(_ind) {
		if (_ind.object_index == GMParty_obj_partsys_handler) {
			return true;
		}
	}
	return false;
}
function __part_system_create(_partsys=undefined, _alloc=GMPARTY_DEFAULT_SOLVER_SIZE) {
	return instance_create_depth(0, 0, 0, GMParty_obj_partsys_handler, {alloc: _alloc, asset: _partsys});
}
function __part_system_create_layer(_layer, _persistent, _partsys=undefined, _alloc=GMPARTY_DEFAULT_SOLVER_SIZE) {
	var _obj = instance_create_layer(0, 0, _layer, GMParty_obj_partsys_handler, {alloc: _alloc, asset: _partsys});
	_obj.persistent = _persistent;
	return _obj;
}
function __part_system_get_layer(_ind) {
	return _ind.layer;
}
function __part_system_layer(_ind, _layer) {
	_ind.layer = _layer;
}
function __part_system_depth(_ind, _depth) {
	_ind.depth = _depth;
}
function __part_system_position(_ind, _x, _y) {
	_ind.solver.translateX = _x;
	_ind.solver.translateY = _y;
}
function __part_system_clear(_ind) {	// ??
	
}
function __part_system_destroy(_ind) {
	if part_system_exists(_ind) {
		instance_destroy(_ind);
	}
}
function __part_particles_clear(_ind) {
	_ind.solver.clear();
}
function __part_particles_count(_ind) {
	return _ind.solver.count;
}
function __part_system_automatic_update(_ind, _bool) {
	_ind.automatic_update = _bool;
}
function __part_system_automatic_draw(_ind, _bool) {
	_ind.automatic_draw = _bool;
}
function __part_system_update(_ind) {
	_ind.solver.process();
}
function __part_system_drawit(_ind) {
	var _shader = shader_current() == -1 ? undefined : shader_current();
	_ind.solver.render(_shader);
}
function __part_system_draw_order(_ind, _oldtonew) {
	_ind.solver.drawFTBParticles = _oldtonew;
	_ind.solver.drawFTBBuffers = _oldtonew;
}

//------------------------------------------------------------//
// part_particles
function __part_particles_create(_ind, _x, _y, _ptype, _number) {
	var _remain = _number;
	var _emitter = {
		xpos : {
			min : _x,
			max : _x
		},
		ypos : {
			min : _y,
			max : _y
		}
	}
	while (_remain > 0) {
		var _n = min(_remain, GMPARTY_EMIT_MAX);
		_ind.solver.emit(_ptype, _n, _emitter);
		_remain -= _n;
	}
}
function __part_particles_create_colour(_ind, _x, _y, _ptype, _color, _number) {
	var _remain = _number;
	var _emitter = {
		xpos : {
			min : _x,
			max : _x
		},
		ypos : {
			min : _y,
			max : _y
		},
		color0 : {
			min : _color,
			max : _color
		},
		color1 : {
			min : -1,
			max : -1
		},
		color2 : {
			min : -1,
			max : -1
		},
		color3 : {
			min : -1,
			max : -1
		}
	}
	while (_remain > 0) {
		var _n = min(_remain, GMPARTY_EMIT_MAX);
		_ind.solver.emit(_ptype, _n, _emitter);
		_remain -= _n;
	}
}

//------------------------------------------------------------//
// part_type
function __part_type_exists(_ind) {
	if !is_undefined(_ind) {
		if is_instanceof(_ind, GMPartyType) {
			return true;
		}
	}
	return false;
}
function __part_type_create() {
	return new GMPartyType();
}
function __part_type_destroy(_ind) {
	if part_type_exists(_ind) {
		delete _ind;
	}
}
function __part_type_clear(_ind) {	// ??
	
}

function __part_type_shape(_ind, _shape) {
	_ind.sprite = GMPARTY_SHAPE_SPRITE_INDEX;
	_ind.image = {
		min : _shape,
		max : _shape,
		count : sprite_get_number(GMPARTY_SHAPE_SPRITE_INDEX)
	};
	_ind.imageSpeed = {
		min : 0.0,
		max : 0.0,
		lifetimeScale : false
	};
}
function __part_type_sprite(_ind, _sprite, _animate, _stretch, _random) {
	var _imgmax = _random ? sprite_get_number(GMPARTY_SHAPE_SPRITE_INDEX) - 1 : 0;
	_ind.sprite = _sprite;
	_ind.image = {
		min : 0,
		max : _imgmax,
		count : sprite_get_number(GMPARTY_SHAPE_SPRITE_INDEX)
	};
	_ind.imageSpeed = {
		min : _animate,
		max : _animate,
		lifetimeScale : _stretch
	};
}

function __part_type_size(_ind, _size_min, _size_max, _size_incr, _size_wiggle) {
	_ind.size = {
		min : _size_min,
		max : _size_max,
		delta : _size_incr,
		wiggle : _size_wiggle
	}
}
function __part_type_scale(_ind, _xscale, _yscale) {
	_ind.xscale = {
		min : _xscale,
		max : _xscale,
		delta : 0,
		wiggle : 0
	}
	_ind.yscale = {
		min : _yscale,
		max : _yscale,
		delta : 0,
		wiggle : 0
	}
}
function __part_type_speed(_ind, _speed_min, _speed_max, _speed_incr, _speed_wiggle) {
	_ind.speed = {
		min : _speed_min,
		max : _speed_max,
		delta : _speed_incr,
		wiggle : _speed_wiggle
	}
}
function __part_type_direction(_ind, _dir_min, _dir_max, _dir_incr, _dir_wiggle) {
	_ind.zdir = {
		min : _dir_min,
		max : _dir_max
	}
	_ind.zrot = {
		min : _dir_incr,
		max : _dir_incr,
		wiggle : _dir_wiggle
	}
}
function __part_type_gravity(_ind, _grav_amount, _grav_dir) {
	//_ind.gravityIntensity = {
	//	min : _grav_amount,
	//	max : _grav_amount
	//}
	//_ind.gravityDirection = {
	//	x :	sin(degtorad(_grav_dir+90)),
	//	y : cos(degtorad(_grav_dir+90)),
	//	z : 0
	//}
	// GM's particle gravity is parametric/stateless.
	// We can use an accelerator component instead.
	var _grav = _ind.componentGet("gmlstd_gravity");
	if is_undefined(_grav) {
		var _eff = new GMPartyEffectorAccelerator(lengthdir_x(_grav_amount, _grav_dir), lengthdir_y(_grav_amount, _grav_dir), 0);
		var _col = new GMPartyColliderGlobal();
		_ind.componentSet("gmlstd_gravity", _eff, _col);
	} else {
		_grav.effectorRef.xspeed = lengthdir_x(_grav_amount, _grav_dir);
		_grav.effectorRef.yspeed = lengthdir_y(_grav_amount, _grav_dir);
	}
}
function __part_type_orientation(_ind, _ang_min, _ang_max, _ang_incr, _ang_wiggle, _ang_relative) {
	_ind.xorient = {
		min : _ang_min,
		max : _ang_max,
		deltaMin : _ang_incr,
		deltaMax : _ang_incr,
		wiggle : _ang_wiggle
	}
	_ind.snapToDirection = _ang_relative;
}

function __part_type_color_mix(_ind, _color1, _color2) {
	_ind.emitColorMixing = e_gmpartyMixing.Vector;
	_ind.color0 = {
		min : _color1,
		max : _color2
	}
	_ind.color1 = {
		min : -1,
		max : -1
	}
	_ind.color2 = {
		min : -1,
		max : -1
	}
	_ind.color3 = {
		min : -1,
		max : -1
	}
}
function __part_type_color_rgb(_ind, _rmin, _rmax, _gmin, _gmax, _bmin, _bmax) {
	var _c1 = make_color_rgb(_rmin, _gmin, _bmin),
		_c2 = make_color_rgb(_rmax, _gmax, _bmax);
	_ind.emitColorMixing = e_gmpartyMixing.ComponentRGB;
	_ind.color0 = {
		min : _c1,
		max : _c2
	}
	_ind.color1 = {
		min : -1,
		max : -1
	}
	_ind.color2 = {
		min : -1,
		max : -1
	}
	_ind.color3 = {
		min : -1,
		max : -1
	}
}
function __part_type_color_hsv(_ind, _hmin, _hmax, _smin, _smax, _vmin, _vmax) {
	var _c1 = make_color_hsv(_hmin, _smin, _vmin),
		_c2 = make_color_hsv(_hmax, _smax, _vmax);
	_ind.emitColorMixing = e_gmpartyMixing.ComponentHSV;
	_ind.color0 = {
		min : _c1,
		max : _c2
	}
	_ind.color1 = {
		min : -1,
		max : -1
	}
	_ind.color2 = {
		min : -1,
		max : -1
	}
	_ind.color3 = {
		min : -1,
		max : -1
	}
}
function __part_type_color1(_ind, _color) {
	_ind.emitColorMixing = e_gmpartyMixing.Vector;
	_ind.color0 = {
		min : _color,
		max : _color
	}
	_ind.color1 = {
		min : -1,
		max : -1
	}
	_ind.color2 = {
		min : -1,
		max : -1
	}
	_ind.color3 = {
		min : -1,
		max : -1
	}
}
function __part_type_color2(_ind, _color1, _color2) {
	_ind.emitColorMixing = e_gmpartyMixing.Vector;
	_ind.color0 = {
		min : _color1,
		max : _color1
	}
	_ind.color1 = {
		min : _color2,
		max : _color2
	}
	_ind.color2 = {
		min : -1,
		max : -1
	}
	_ind.color3 = {
		min : -1,
		max : -1
	}
}
function __part_type_color3(_ind, _color1, _color2, _color3) {
	_ind.emitColorMixing = e_gmpartyMixing.Vector;
	_ind.color0 = {
		min : _color1,
		max : _color1
	}
	_ind.color1 = {
		min : _color2,
		max : _color2
	}
	_ind.color2 = {
		min : _color3,
		max : _color3
	}
	_ind.color3 = {
		min : -1,
		max : -1
	}
}
function __part_type_alpha1(_ind, _alpha1) {
	_ind.alpha0 = {
		min : _alpha1,
		max : _alpha1
	}
	_ind.alpha1 = {
		min : -1,
		max : -1
	}
	_ind.alpha2 = {
		min : -1,
		max : -1
	}
	_ind.alpha3 = {
		min : -1,
		max : -1
	}
}
function __part_type_alpha2(_ind, _alpha1, _alpha2) {
	_ind.alpha0 = {
		min : _alpha1,
		max : _alpha1
	}
	_ind.alpha1 = {
		min : _alpha2,
		max : _alpha2
	}
	_ind.alpha2 = {
		min : -1,
		max : -1
	}
	_ind.alpha3 = {
		min : -1,
		max : -1
	}
}
function __part_type_alpha3(_ind, _alpha1, _alpha2, _alpha3) {
	_ind.alpha0 = {
		min : _alpha1,
		max : _alpha1
	}
	_ind.alpha1 = {
		min : _alpha2,
		max : _alpha2
	}
	_ind.alpha2 = {
		min : _alpha3,
		max : _alpha3
	}
	_ind.alpha3 = {
		min : -1,
		max : -1
	}
}
function __part_type_blend(_ind, _blend) {	// ??
	_ind.blendMode = (_blend == true) ? bm_add : bm_normal;
}
function __part_type_life(_ind, _life_min, _life_max) {
	_ind.life = {
		min : _life_min,
		max : _life_max
	}
}
function __part_type_step(_ind, _step_number, _step_type) {	// ??
	// compute waiting room
}
function __part_type_death(_ind, _death_number, _death_type) {	// ??
	// compute waiting room
}

//------------------------------------------------------------//
// part_emitter
function __part_emitter_exists(_ps, _ind) {
	if part_system_exists(_ps) {
		if instance_exists(_ind) {
			if (_ind.object_index == GMParty_obj_partemitter_handler) {
				if (_ind.system.id == _ps.id) {
					return true;
				}
			}
		}
	}
	return false;
}
function __part_emitter_create(_ps) {
	var _inst = instance_create_depth(0, 0, 0, GMParty_obj_partemitter_handler);
	_inst.system = _ps;
	return _inst;
}
function __part_emitter_clear(_ps, _ind) {		// ??
	
}
function __part_emitter_region(_ps, _ind, _xmin, _xmax, _ymin, _ymax, _shape, _distr) {
	static __shapes = [e_gmpartyEmitShape.Box, e_gmpartyEmitShape.Sphere, e_gmpartyEmitShape.Box, e_gmpartyEmitShape.Line];
	var _sh = __shapes[_shape];
	var _rot = (_shape == ps_shape_diamond) ? 45 : 0;
	if part_emitter_exists(_ps, _ind) {
		_ind.emitter.emitType = _sh;
		_ind.emitter.emitDistribution = _distr;
		_ind.emitter.xpos = {
			min : _xmin,
			max : _xmax
		}
		_ind.emitter.ypos = {
			min : _ymin,
			max : _ymax
		}
		_ind.emitter.emitRot = {
			yaw : 0,
			pitch : 0,
			roll : _rot
		}
	}
}
function __part_emitter_burst(_ps, _ind, _parttype, _number) {
	if part_emitter_exists(_ps, _ind) {
		var _remain = _number;
		while (_remain > 0) {
			var _n = min(_remain, GMPARTY_EMIT_MAX);
			_ps.solver.emit(_parttype, _n, _ind.emitter);
			_remain -= _n;
		}
	}
}
function __part_emitter_stream(_ps, _ind, _parttype, _number) {
	if part_emitter_exists(_ps, _ind) {
		_ind.stream_count = _number;
		_ind.stream_type = _parttype;
	}
}
function __part_emitter_destroy(_ps, _ind) {
	if part_emitter_exists(_ps, _ind) {
		instance_destroy(_ind);
	}
}
function __part_emitter_destroy_all(_ps) {
	if part_system_exists(_ps) {
		with (GMParty_obj_partemitter_handler) {
			if (_ps.id == system.id) {
				instance_destroy();
			}
		}
	}
}



