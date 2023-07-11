# [Documentation](../documentation.md)
# Colliders
Colliders are objects which play a big part in defining particle behavior. They define volumes in world-space that detect collisions with particles, performing effector transformations onto every particle they manage to collide with.

## Enums
`enum e_gmpartyColShape`
Variants describe the shape of the collider.

Variant | Description
--- | --------
`Box` | Box-shaped collider.
`Sphere` | Sphere-shaped collider.
`Cylinder` | Cylinder-shaped collider.
`Pill` | Pill-shaped collider.
`Texture2D` | Collider shape is defined by a 2d distance field.
`TextureFaux3D` | Collider shape is defined by a 3d distance field.
`Heightmap` | Collider shape is a 2d heightmap projected onto a 3d scene.

## Prototype
`GMPartyColliderPrototype() constructor`
Serves as a parent from which all colliders inherit common behavior.

Variable | Type | Description
--- | --- | --------
`type` | `{Enum.e_gmpartyColShape}` | Defines which type of a collider this object is.
`distanceMultiplier` | `{Array<2, f32>}` | An array with two components defining the intensity factor of the collision from start to end of the distance field.

`static bindColliderType()`
**Description:** Used internally to bind collider type to a shader.
`static bindColliderUniforms()`
**Description:** Used internally to bind collider uniforms to a shader.

## Collider types
`GMPartyColliderGlobal() : GMPartyColliderPrototype() constructor`
This is a global collider. It procs effector collisions for all living particles and is not defined by anything. 

`GMPartyColliderBox(x, y, z, xlen, ylen, zlen) : GMPartyColliderPrototype() constructor`
This collider represents a 3d box, defined by 3d position and length vectors.
Param | Type | Description
--- | --- | --------
`x` | `{Real}` | X position.
`y` | `{Real}` | Y position.
`z` | `{Real}` | Z position.
`xlen` | `{Real}` | X length.
`ylen` | `{Real}` | Y length.
`zlen` | `{Real}` | Z length.
Returns | `{Struct.GMPartyColliderBox}` | Returns new `GMPartyColliderBox` collider reference.

`GMPartyColliderSphere(x, y, z, radius) : GMPartyColliderPrototype() constructor`
This collider represents a 3d sphere, defined by 3d position and radius.
Param | Type | Description
--- | --- | --------
`x` | `{Real}` | X position.
`y` | `{Real}` | Y position.
`z` | `{Real}` | Z position.
`radius` | `{Real}` | Sphere radius.
Returns | `{Struct.GMPartyColliderSphere}` | Returns new `GMPartyColliderSphere` collider reference.

`GMPartyColliderCylinder(x, y, z, xlen, ylen, zlen, radius) : GMPartyColliderPrototype() constructor`
This collider represents a 3d cylinder, defined by 3d position and length vectors, including radius.
Param | Type | Description
--- | --- | --------
`x` | `{Real}` | X position.
`y` | `{Real}` | Y position.
`z` | `{Real}` | Z position.
`xlen` | `{Real}` | X length.
`ylen` | `{Real}` | Y length.
`zlen` | `{Real}` | Z length.
`radius` | `{Real}` | Cylinder radius.
Returns | `{Struct.GMPartyColliderCylinder}` | Returns new `GMPartyColliderCylinder` collider reference.

`GMPartyColliderPill(x, y, z, xlen, ylen, zlen, radius) : GMPartyColliderPrototype() constructor`
This collider represents a 3d pill, defined by 3d position and length vectors, including radius.
Param | Type | Description
--- | --- | --------
`x` | `{Real}` | X position.
`y` | `{Real}` | Y position.
`z` | `{Real}` | Z position.
`xlen` | `{Real}` | X length.
`ylen` | `{Real}` | Y length.
`zlen` | `{Real}` | Z length.
`radius` | `{Real}` | Pill radius.
Returns | `{Struct.GMPartyColliderPill}` | Returns new `GMPartyColliderPill` collider reference.

`GMPartyColliderSDF2D(sprite, image, x, y, xscale, yscale, angle) : GMPartyColliderPrototype() constructor`
This collider represents a 2d SDF texture.
Param | Type | Description
--- | --- | --------
`sprite` | `{Asset.GMSprite}` | Sprite index.
`image` | `{Real}` | Image index.
`x` | `{Real}` | X position.
`y` | `{Real}` | Y position.
`xscale` | `{Real}` | X scale.
`yscale` | `{Real}` | Y scale.
`angle` | `{Real}` | Image angle in degrees.
Returns | `{Struct.GMPartyColliderSDF2D}` | Returns new `GMPartyColliderSDF2D` collider reference.

Since we cannot precisely derive absolute distances from 2d SDF textures, this collider also contains a separate intensity `factor` field.
Variable | Type | Description
--- | --- | --------
`factor` | `{Real}` | Distance field intensity multiplier.

`GMPartyColliderSDF3D(sdf_data, x, y, z) : GMPartyColliderPrototype() constructor`
This collider represents a 3d SDF model texture.
Param | Type | Description
--- | --- | --------
`sdf_data` | `{Struct.GMPartySDFModel}` | Precomputed 3d SDF data.
`x` | `{Real}` | X position.
`y` | `{Real}` | Y position.
`z` | `{Real}` | Z position.
Returns | `{Struct.GMPartyColliderSDF3D}` | Returns new `GMPartyColliderSDF3D` collider reference.

SDF3D colliders contain these extra fields.
Variable | Type | Description
--- | --- | --------
`xscale` | `{Real}` | X scale of the model's 3d volume.
`yscale` | `{Real}` | Y scale of the model's 3d volume.
`zscale` | `{Real}` | Z scale of the model's 3d volume.
`rotation` | `{Array<3, f32>}` | A 3-component array describing pitch, yaw, and roll rotation components in degrees.

## Example
```js
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

// Create a 3d model collider by passing the sdf data and world position.
collider0 = new GMPartyColliderSDF3D(model_sdf, 0, 256, 1000);
collider0.xscale = 80;
collider0.yscale = 80;
collider0.zscale = 80;
collider0.rotation[0] = 180;
// Create a box collider to serve as ground.
collider1 = new GMPartyColliderBox(-10000, -10000, 1000, 20000, 20000, 256);

// Create a collision effector to bind with our colliders
effector0 = new GMPartyEffectorCollider();

// Add these components to the particle type (solvers will have their own component stack in the future)
part.componentSet("some_component", effector0, collider0);
part.componentSet("some_other_component", effector0, collider1);
```

`GMPartyColliderHeightmap(height_data, x_start, y_start, z_start, x_len, y_len, z_len) : GMPartyColliderPrototype() constructor`
This collider represents a 3d heightmap.
Param | Type | Description
--- | --- | --------
`height_data` | `{Struct.GMPartyHeightmap}` | Precomputed heightmap data.
`x_start` | `{Real}` | Starting X position.
`y_start` | `{Real}` | Starting Y position.
`z_start` | `{Real}` | Starting Z position.
`x_len` | `{Real}` | X length.
`y_len` | `{Real}` | Y length.
`z_len` | `{Real}` | Z length.
Returns | `{Struct.GMPartyHeightmap}` | Returns new `GMPartyHeightmap` collider reference.

Heightmap colliders contain an extra rotation field.
Variable | Type | Description
--- | --- | --------
`rotation` | `{Real}` | Rotation in degrees.

Heightmap colliders use a simple create-free api.
`gmpartyHeightmapCreate(sprite, texsize)`
**Description:** Constructs `GMPartyHeightmap` object out of a sprite binding.
Param| Type | Description
--- | --- | --------
`sprite` | `{Asset.GMSprite}` | Sprite index we want to turn into a heightmap collider.
`texsize` | `{Real}` | Target texture size.
Returns | `{Struct.GMPartyHeightmap}` | Reference to this collider.

`gmpartyHeightmapFree(heightmap)`
**Description:** Frees the heightmap collider and its resources from memory.
Param| Type | Description
--- | --- | --------
`heightmap` | `{Struct.GMPartyHeightmap}` | Reference to a heightmap collider object being freed.
Returns | `{Bool}` | Returns `true` on successful operation.

## Example
```js
// Create a heightmap collider to serve as ground.
heightmap = gmpartyHeightmapCreate(spr_heightmap, 4096);
collider0 = new GMPartyColliderHeightmap(heightmap, -5000, -5000, 1000, 10000, 10000, -2500);

// Create a collision effector to bind with our colliders
effector0 = new GMPartyEffectorCollider();

// Add collision component to the particle type
part.componentSet("heightmap_collisions", effector0, collider0);
```

---
<- [Decorators](decorators.md)

-> [Effectors](effectors.md)

