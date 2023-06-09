var utils = gmpartyUtils();

// cam setup
x = 450;
y = 1920;
z = 890;
yaw = 108;
pitch = 20;
init = false;

// Create a solver, allocate 100k particles.
solver = new GMPartySolver(100000);

// Create a particle type, edit its fields
part = new GMPartyType();
part.sprite	= spr_rain;
part.image	= { min : 0, max : 0, count : 1};
part.life	= { min : 200, max : 250}	;
part.size	= { min : 0.4, max : 0.4, delta : 0.0, wiggle : 0.0 };
part.speed	= { min : 1.0, max : 2.0, delta : 0.0, wiggle : 0.2 };
part.xdir	= { min : 0.0, max : 0.0 };
part.ydir	= { min : 0.0, max : 0.0 };
part.zdir	= { min : 0.0, max : 0.0 };
//part.xrot	= { min : -0.8, max : 0.8, wiggle : 0.0 };
//part.yrot	= { min : -0.8, max : 0.8, wiggle : 0.0 };
//part.zrot	= { min : -0.8, max : 0.8, wiggle : 0.0 };
part.restitution = { min : 0.2, max : 0.3 };
part.snapToDirection = true;
part.flags |= e_gmpartyPartFlag.Is3d;

// Create a decorator which will basically be used as an emitter,
// overriding existing fields of all particles decorated with it
// during emission.
emitter = new GMPartyDecorator();
emitter.emitType = e_gmpartyEmitShape.Box;
emitter.emitFire = e_gmpartyEmitFire.Relative;
emitter.xpos = { min : -5000, max : 5000 };
emitter.ypos = { min : -5000, max : 5000 };
emitter.zpos = { min : -1500, max : -1000 };
emitter.ydir = { min : -180, max : 180};
emitter.gravityIntensity = { min : 0.4, max : 0.5 };
emitter.gravityDirection = { x : 0.2, y : 0.25, z : 1.0 };

// Load a buffer from a file.
model_buff = buffer_load("tree.vbuff");

// Create a matching vertex format array of this vertex buffer.
model_vf = [e_vertexComponent.Position3d, e_vertexComponent.Normal, e_vertexComponent.Color];

// Create a vb out of it.
model_vb = vertex_create_buffer_from_buffer(model_buff, utils.vformatCache(model_vf) );

// Get sdf from disk or bake a new one
//model_sdf = gmpartySDF3DLoad("tree.sdf");
//if is_undefined(model_sdf) {
	model_sdf = gmpartySDF3DCreate(model_vb, model_vf, 2048, true, true);
//	gmpartySDF3DSave(model_sdf, "tree.sdf");
//}

// Create a 3d model collider by passing the sdf data and world position.
collider0 = new GMPartyColliderSDF3D(model_sdf, 0, 256, 1000);
collider0.xscale = 80;
collider0.yscale = 80;
collider0.zscale = 80;
collider0.rotation[0] = 180;

// Create a heightmap collider to serve as ground.
heightmap = gmpartyHeightmapCreate(spr_heightmap, 4096);
collider2 = new GMPartyColliderHeightmap(heightmap, -5000, -5000, 1000, 10000, 10000, -2500);

// Create a collision effector to bind with our colliders
effector0 = new GMPartyEffectorCollider();

// Add these components to the particle type (solvers will have their own component stack in the future)
part.componentSet("some_component", effector0, collider0);
part.componentSet("some_other_component", effector0, collider2);
