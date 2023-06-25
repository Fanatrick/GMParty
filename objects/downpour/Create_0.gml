utils = gmpartyUtils();

z = -928;
yaw = 0;
pitch = 0;

//gpu_set_ztestenable(true);
//gpu_set_zwriteenable(true);

solver = new GMPartySolver(100000);		// alloc 100k particles

part = new GMPartyType();
part.sprite	= spr_rain;
part.image	= { min : 0, max : 0, count : 1};
part.life	= { min : 150, max : 250}	;
part.size	= { min : 0.4, max : 0.4, delta : 0.0, wiggle : 0.0 };
part.speed	= { min : 1.0, max : 2.0, delta : 0.0, wiggle : 0.2 };
part.xdir	= { min : 0.0, max : 0.0 };
part.ydir	= { min : 0.0, max : 0.0 };
part.zdir	= { min : 0.0, max : 0.0 };
//part.xrot	= { min : 2.0, max : 10.0, wiggle : 0.0 };
//part.yrot	= { min : 1.0, max : 5.0, wiggle : 0.0 };
//part.zrot	= { min : 2.0, max : 10.0, w<iggle : 0.0 };
part.snapToDirection = true;
part.flags |= e_gmpartyPartFlag.Is3d;

emitter = new GMPartyWrapper();
emitter.emitType = e_gmpartyEmitShape.Box;
emitter.emitFire = e_gmpartyEmitFire.Relative;
emitter.xpos = { min : -50, max : 50 };
emitter.ypos = { min : -50, max : 50 };
emitter.zpos = { min : -1500, max : -1000 };
emitter.ydir = { min : -180, max : 180};
emitter.gravityIntensity = { min : 0.5, max : 0.5 };
emitter.gravityDirection = { x : 0.0, y : 0.0, z : 1.0 };
emitter.restitution = { min : 0.31, max : 0.41 };

//emitter.ydir = { min : -120, max : -120};
//emitter.yorient = {	min : 90, max : 90, deltaMin : 0, deltaMax : 0, wiggle : 0 };
//emitter.zorient = {	min : 0, max : 360, deltaMin : 0, deltaMax : 0, wiggle : 0 };
//emitter.xorient = {	min : -180, max : 180, deltaMin : 1, deltaMax : 3, wiggle : 0 };
//emitter.yorient = {	min : -180, max : 180, deltaMin : 1, deltaMax : 3, wiggle : 0 };
//emitter.zorient = {	min : -180, max : 180, deltaMin : 1, deltaMax : 3, wiggle : 0 };

// add particle components
model_buff = buffer_load("tree.vbuff");
//model_buff = buffer_load("sphere.vbuff");
model_vf = [e_vertexComponent.Position3d, e_vertexComponent.Normal, e_vertexComponent.Color];
//model_vf = [e_vertexComponent.Position3d, e_vertexComponent.Texcoord, e_vertexComponent.Normal, e_vertexComponent.Float3];
model_vb = vertex_create_buffer_from_buffer(model_buff, utils.vformatCache(model_vf) );
model_sdf = utils.sdf3dCreate(model_vb, model_vf, 8192);
trace(model_sdf);

collider0 = new GMPartyColliderSDF3D(model_sdf, 0, 0, -300);
effector0 = new GMPartyEffectorCollider();
//destructor0 = new GMPartyEffectorDestructor(5);
part.componentSet("some_component", effector0, collider0);
//part.componentSet("some_component1", destructor0, collider0);

collider1 = new GMPartyColliderSphere(256, 256, -800, 256);
effector1 = new GMPartyEffectorAttractor(18);
//part.componentSet("some_component", effector1, collider1);

collider2 = new GMPartyColliderBox(x-2560, y-2560, 1000, 5120, 5120, 256);
effector2 = new GMPartyEffectorCollider();
part.componentSet("some_component2", effector2, collider2);


