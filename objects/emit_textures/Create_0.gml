// Create a solver, allocate 100k particles.
solver = new GMPartySolver(100000);

// Create a particle type, edit its fields
part = new GMPartyType();
part.life = {
	min: 10,
	max: 30
}
part.sprite = spr_simple;
part.size = {
	min: 0.01,
	max: 0.03,
	delta: 0.0,
	wiggle: 0.0
}
part.speed = {
	min: 0.0,
	max: 1.0,
	wiggle: 0.0,
	delta: 0.0
}
part.zdir = {
	min : 90,
	max : 90
}

part.emitColorMixing = e_gmpartyMixing.ComponentHSV;
part.color0 = {
	min: 0xffff00,
	max: 0xffffff
}
part.color1 = {
	min: 0xffff00,
	max: 0xffffff
}
part.color2 = {
	min: 0xffff00,
	max: 0xffffff
}
part.color3 = {
	min: 0xffff00,
	max: 0xffffff
}
part.blendMode = bm_add;

// Create an emitter decorator
emitter = new GMPartyDecorator();
// Create a texture emitter, bind it as an emission target
emit_sprite = gmpartyTextureEmitterCreate(spr_logo);
emitter.emitTarget = emit_sprite;
emitter.emitOffset = [-sprite_get_xoffset(spr_logo), -sprite_get_yoffset(spr_logo)];
emitter.emitType = e_gmpartyEmitShape.Sprite;

// Set some other emitter properties
emitter.emitFire = e_gmpartyEmitFire.Absolute;
emitter.emitRot = {
	pitch: 0,
	yaw: 0,
	roll: 0
}
emitter.xpos = { min : 600, max : 1000 };
emitter.ypos = { min : 400, max : 1000 };
emitter.zpos = { min : 0, max : 0 };
