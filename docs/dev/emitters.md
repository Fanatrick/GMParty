# [Documentation](../documentation.md)
# Emitters
In Party, particle types themselves expose fields that define their emission behavior. There is no need for emitter objects, particles can instead be decorated by GMPartyDecorator constructs.

## Enums
`enum e_gmpartyMixing`
Variants describe how the interpolation between colors is calculated.
Variant | Description
--- | --------
`Vector` | Interpolate between vectors.
`ComponentRGB` | Interpolate between individual RGB components.
`ComponentHSV` | Interpolate between individual HSV components.

`enum e_gmpartyEmitDistribution`
Variants describe emission distribution.
Variant | Description
--- | --------
`Linear` | Linear distribution.
`Gaussian` | Gaussian distribution.
`InvGaussian` | Inverse-Gaussian distribution.

`enum e_gmpartyEmitShape`
Variants define the shape of the emission.
Variant | Description
--- | --------
`Box` | Emission occurs inside a box.
`Sphere` | Emission occurs inside a sphere.
`Line` | Emission occurs on a line.
`Model` | Emission occurs inside a 3d model.

`enum e_gmpartyEmitFire`
Variants control the firing direction during emission.
Variant | Description
--- | --------
`Absolute` | Particles are fired towards their absolute emission direction vector.
`Relative` | Particles are fired relative to their emission shape.
`Mix` | Particle direction vectors are mixed between their absolute and relative firing direction.

## Particle type emission fields
These fields define the behavior of particle types during emission. They can all be decorated.
Variable | Type | Default | Description
--- | --- | --- | --------
`emitType` | `{Enum.e_gmpartyEmitShape}` | `e_gmpartyEmitShape.Box` | Shape variant.
`emitScale` | `{Array<3, f32>}` | [1.0, 1.0, 1.0] | Emission scale for targeted shapes.
`emitDistribution` | `{Enum.e_gmpartyEmitDistribution}` | `e_gmpartyEmitDistribution.Linear` | Emission distribution type.
`emitColorMixing` | `{Enum.e_gmpartyMixing}` | `e_gmpartyMixing.Vector` | Emission color mixing variant.
`emitFire` | `{Enum.e_gmpartyEmitFire}` | `e_gmpartyEmitFire.Absolute` | Emission firing vector variant.
`seed` | `{Real}` | `gmpartyUtils().lcgRandomInt();` | Randomized seed used during the emission event.

These two fields additionally describe emitter rotation and range.

Field | Value | Default | Description
--- | --- | --- | --------
`emitRot` | `yaw` | 0.0 | Yaw component of 3d rotation in degrees.
- | `pitch` | 0.0 | Pitch component of 3d rotation in degrees.
- | `roll` | 0.0 | Roll component of 3d rotation in degrees.
`emitRange` | `min` | 0.0 | Min emission range.
- | `max` | 1.0 | Max emission range.

## emitTarget

Finally, there's a special field that accepts references to emitter objects. Some emitter variants like `Model` requires additional data, this value points the solver to this data during emission.

Variable | Type | Default | Description
--- | --- | --- | --------
`emitTarget` | `{Id.Any}` | `undefined` | A reference to an object that handles the emission overloading.

Type | Target | Description
--- | --- | ------
`e_gmpartyEmitShape.Model` | `{Struct.GMPartySDFModel}` | Requires a baked 3d SDF as input target.

## Example
```js
// Create a particle type, edit its fields
part = new GMPartyType();
part.xdir = { min : 0.0, max : 360.0 };
part.ydir = { min : 0.0, max : 360.0 };
part.zdir = { min : 0.0, max : 360.0 };
part.xpos = { min : 0.0, max : 1024.0 };
part.ypos = { min : 0.0, max : 1024.0 };
part.zpos = { min : 0.0, max : 1024.0 };

part.emitType = e_gmpartyEmitShape.Model;
part.emitFire = e_gmpartyEmitFire.Relative;
part.emitRot = {
	pitch: 180,
	yaw: 90,
	roll: 0
}

// Create an SDF out of a 3d model
var utils = gmpartyUtils();
myBuffer = buffer_load("tree.vbuff");
myVertexFormatArray = [e_vertexComponent.Position3d, e_vertexComponent.Normal, e_vertexComponent.Color];
myVertexBuffer = vertex_create_buffer_from_buffer(myBuffer, utils.vformatCache(myVertexFormatArray) );
mySDF = gmpartySDF3DCreate(myVertexBuffer, myVertexFormatArray, 2048, true, true);

// Bind SDF as emitTarget, scale up the model
part.emitTarget = mySDF;
part.emitScale = [80.0, 80.0, 80.0];
```
---
<- [Particle types](types.md)

-> [Decorators](decorators.md)

