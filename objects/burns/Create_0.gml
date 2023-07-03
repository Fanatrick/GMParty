var utils = gmpartyUtils();

// cam setup
x = 450;
y = 1920;
z = -900;
yaw = 108;
pitch = 20;
init = false;

// Create a solver, allocate 100k particles.
solver = new GMPartySolver(100000);

// Create a particle type, edit its fields
part = new GMPartyType();
part.color0 = { min : c_red, max : c_white};
part.color1 = { min : c_red, max : c_white};
part.color2 = { min : c_blue, max : c_blue};
part.color3 = { min : c_black, max : c_black};
part.alpha0 = { min : 0.02, max : 0.04};
part.alpha1 = { min : 0.04, max : 0.02};
part.alpha2 = { min : 0.0, max : 0.0};
part.sprite	= spr_burns;
part.image	= { min : 0, max : 0, count : 1};
part.life	= { min : 60, max : 90};
part.size	= { min : 0.02, max : 0.1, delta : 0.0, wiggle : 0.02 };
part.speed	= { min : 0.0, max : 1.0, delta : 0.0, wiggle : 0.2 };
part.xorient = { min : 0, max : 360, deltaMin : -16, deltaMax : 16, wiggle : 0 };
part.xdir	= { min : 0.0, max : 360.0 };
part.ydir	= { min : 0.0, max : 360.0 };
part.zdir	= { min : 0.0, max : 360.0 };
part.blendMode = bm_add;
part.flags |= e_gmpartyPartFlag.IsLookat;

// Create a decorator which will basically be used as an emitter,
// overriding existing fields of all particles decorated with it
// during emission.
emitter = new GMPartyDecorator();
//emitter.emitType = e_gmpartyEmitShape.Box;
emitter.emitType = e_gmpartyEmitShape.Model;
emitter.emitFire = e_gmpartyEmitFire.Relative;
emitter.emitRot = {
	pitch: 0,
	yaw: 0,
	roll: 0
}

emitter.xpos = { min : 0, max : 0 };
emitter.ypos = { min : 0, max : 0 };
emitter.zpos = { min : 0, max : 0 };
emitter.gravityIntensity = { min : 0.2, max : 0.4 };
emitter.gravityDirection = { x : 0.0, y : 0.0, z : -1.0 };

// Load a buffer from a file.
model_buff = buffer_load("tree.vbuff");

// Create a matching vertex format array of this vertex buffer.
model_vf = [e_vertexComponent.Position3d, e_vertexComponent.Normal, e_vertexComponent.Color];

// Create a vb out of it.
model_vb = vertex_create_buffer_from_buffer(model_buff, utils.vformatCache(model_vf) );

// Get sdf from disk or bake a new one
model_sdf = gmpartySDF3DLoad("tree.sdf");
if is_undefined(model_sdf) {
	model_sdf = gmpartySDF3DCreate(model_vb, model_vf, 2048, true, true);
	gmpartySDF3DSave(model_sdf, "tree.sdf");
}

// Set sdf as an emit target
emitter.emitTarget = model_sdf;
emitter.emitScale = [80, 80, 80];

// Create a magnetic sphere
collider0 = new GMPartyColliderSphere(x, y, z, 1024);
effector0 = new GMPartyEffectorAttractor(4);
part.componentSet("yeah b magnets!", effector0, collider0);

