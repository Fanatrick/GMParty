# [Documentation](../documentation.md)
# Particle types
Particle types are structs that describe particle's configuration and emission values. When particles are emitted, their configuration tells the system which range should be taken into account for each individual field.

## Constructor
`GMPartyType() constructor`
Constructs a new particle type.
Param| Type | Description
--- | --- | --- | --------
Returns | `{Struct.GMPartySolver}` | Particle type reference

## Enums
`enum e_gmpartyPartFlag`
Each variant is a flag bit, which defines particle type's behavior during simulation and rendering.
Flag | Description
--- | --------
`SpeedAllowNegative` | Allows the `speed` component to hold negative values.
`SpeedInvertDelta` | Inverts speed delta if the `speed` component crosses signs.
`SizeAllowNegative` | Allows the `size` component to hold negative values.
`WiggleAdditive` | Allows additive wiggle of components.
`*default*WiggleRangeSymmetry` | Processes component wiggling in both negative and positive range.
`*default*WiggleOscillate` | Performs oscillation wiggle alike GM standard particle system.
`Is3d` | Tells the system to rotate this particle in 3 dimensions.
`IsLookat` | Tells the system to render this particle as a billboard.

## Particle index
Each particle type is assigned an id during construction.
Field | Value | Description
--- | --- | --------
`index` | `{Real}` | Unique identifier of a particle type object.

The particle type can then be accessed globally via `gmpartyUtils()`:
```js
// ** //
myParticle = new GMPartyType();
myIndex = myParticle.index;
// ** //
utils = gmpartyUtils();
var thisParticle = utils.particleFromId(myIndex);
assert_equal(myParticle.index, thisParticle.index, "");
```

## Particle config fields
Particle type variables are mostly structs that define emission range, deltas and wiggle values. It's important to note that every field among these can be redecorated.
Field | Value | Default | Description
--- | --- | --- | --------
`life` | `min` | 100 | Min life duration in steps.
- | `max` | 100 | Max life duration in steps.
`speed` | `min` | 0.0 | Min speed.
- | `max` | 0.0 | Max speed.
- | `delta` | 0.0 | Acceleration.
- | `wiggle` | 0.0 | Speed wiggle.
`xpos` | `min` | 0.0 | Min emitter x position.
- | `max` | 0.0 | Max emitter x position
`ypos` | `min` | 0.0 | Min emitter y position.
- | `max` | 0.0 | Max emitter y position
`zpos` | `min` | 0.0 | Min emitter z position.
- | `max` | 0.0 | Max emitter z position
`xscale` | `min` | 1.0 | Min x scale.
- | `max` | 1.0 | Max x scale.
- | `delta` | 0.0 | X scale delta.
- | `wiggle` | 0.0 | X scale wiggle.
`yscale` | `min` | 1.0 | Min y scale.
- | `max` | 1.0 | Max y scale.
- | `delta` | 0.0 | Y scale delta.
- | `wiggle` | 0.0 | Y scale wiggle.
`zscale` | `min` | 1.0 | Min z scale.
- | `max` | 1.0 | Max z scale.
- | `delta` | 0.0 | Z scale delta.
- | `wiggle` | 0.0 | Z scale wiggle.
`size` | `min` | 1.0 | Min size.
- | `max` | 1.0 | Max size.
- | `delta` | 0.0 | Size delta.
- | `wiggle` | 0.0 | Size wiggle.
`snapToDirection` | - | false | Bool representing should this particle face the direction it's traveling.
`xorient` | `min` | 0.0 | Min x orientation in degrees.
- | `max` | 0.0 | Max x orientation in degrees.
- | `deltaMin` | 0.0 | Min x orientation added every step.
- | `deltaMax` | 0.0 | Max x orientation added every step.
- | `wiggle` | 0.0 | X orientation wiggle.
`yorient` | `min` | 0.0 | Min y orientation in degrees.
- | `max` | 0.0 | Max y orientation in degrees.
- | `deltaMin` | 0.0 | Min y orientation added every step.
- | `deltaMax` | 0.0 | Max y orientation added every step.
- | `wiggle` | 0.0 | Y orientation wiggle.
`zorient` | `min` | 0.0 | Min z orientation in degrees.
- | `max` | 0.0 | Max z orientation in degrees.
- | `deltaMin` | 0.0 | Min z orientation added every step.
- | `deltaMax` | 0.0 | Max z orientation added every step.
- | `wiggle` | 0.0 | Z orientation wiggle.
`xrot` | `min` | 0.0 | Min x rotation in degrees applied every step.
- | `max` | 0.0 | Max x rotation in degrees applied every step.
- | `wiggle` | 0.0 | X rotation wiggle.
`yrot` | `min` | 0.0 | Min y rotation in degrees applied every step.
- | `max` | 0.0 | Max y rotation in degrees applied every step.
- | `wiggle` | 0.0 | Y rotation wiggle.
`zrot` | `min` | 0.0 | Min z rotation in degrees applied every step.
- | `max` | 0.0 | Max z rotation in degrees applied every step.
- | `wiggle` | 0.0 | Z rotation wiggle.
`xdir` | `min` | 0 | Min spawning x direction in degrees.
- | `max` | 0 | Max spawning x direction in degrees.
`ydir` | `min` | 0 | Min spawning y direction in degrees.
- | `max` | 0 | Max spawning y direction in degrees.
`zdir` | `min` | 0 | Min spawning z direction in degrees.
- | `max` | 0 | Max spawning z direction in degrees.

There are 4 color and alpha fields defining a gradient through which every particle can interpolate during its lifetime. Both `color0` and `alpha0` need to be defined, the rest can be omitted in order and particles will still interpolate but only through defined values.

Field | Value | Default | Description
--- | --- | --- | --------
`color0` | `min` | `c_white` | Min 32bit color constant.
- | `max` | `c_white` | Max 32bit color constant.
`color1` | `min` | -1 | Min 32bit color constant.
- | `max` | -1 | Max 32bit color constant.
`color2` | `min` | -1 | Min 32bit color constant.
- | `max` | -1 | Max 32bit color constant.
`color3` | `min` | -1 | Min 32bit color constant.
- | `max` | -1 | Max 32bit color constant.

Field | Value | Default | Description
--- | --- | --- | --------
`alpha0` | `min` | 1.0 | Min normalized float representing transparency
- | `max` | 1.0 | Max normalized float representing transparency.
`alpha1` | `min` | -1.0 | Min normalized float representing transparency.
- | `max` | -1.0 | Max normalized float representing transparency.
`alpha2` | `min` | -1.0 | Min normalized float representing transparency.
- | `max` | -1.0 | Max normalized float representing transparency.
`alpha3` | `min` | -1.0 | Min normalized float representing transparency.
- | `max` | -1.0 | Max normalized float representing transparency.

Additionally, Party supports fields that define sprites, images and blend modes of individual particles in a state-preserving manner.

Field | Value | Default | Description
--- | --- | --- | --------
`sprite` | - | `GMPARTY_SHAPE_SPRITE_INDEX` | Sprite index of this particle type, on default this value points to a makeshift GM standard particle texture.
`image` | `min` | 0 | Min image index.
- | `max` | 0 | Max image index.
- | `count` | 14 | Number of individual images of this sprite resource.
`imageSpeed` | `min` | 0.0 | Min image speed.
- | `max` | 0.0 | Max image speed.
- | `lifetimeScale` | false | Bool representing if this particle's image index should scale with its lifetime.

Lastly, there are a couple of fields defining physics properties.

Field | Value | Default | Description
--- | --- | --- | --------
`mass` | `min` | 1.0 | Min mass.
- | `max` | 1.0 | Max mass.
`restitution` | `min` | 0.85 | Min speed factor preserved during collisions.
- | `max` | 0.85 | Max speed factor preserved during collisions.
`gravityIntensity` | `min` | 0.0 | Min gravity intensity.
- | `max` | 0.0 | Max gravity intensity.
`gravityDirection` | `x` | 0.0 | X component of gravity's direction vector.
- | `y` | 0.0 | Y component of gravity's direction vector.
- | `z` | 0.0 | Z component of gravity's direction vector.

## Example
```js
// Create a particle type, edit its fields
part = new GMPartyType();
part.life = { min: 60, max: 90 };
part.color0 = { min: c_red, max: c_white };
part.color1 = { min: c_black, max: c_black };
part.alpha0 = { min: 0.25, max: 0.75 };
part.alpha1 = { min: 0.00, max: 0.00 };
part.size	= { min: 0.2, max: 0.4, delta: 0.0, wiggle: 0.1 };
part.speed	= { min: 0.0, max: 1.0, delta: 0.05, wiggle: 0.1 };
part.blendMode = bm_add;
part.flags |= e_gmpartyPartFlag.IsLookat;
```
## Particle components
Party offers a powerful particle component system that can introduce emerging gameplay and chaotic behavior to the simulation. A particle component is defined by 3 things:
- `Key` value which gives the component a name you can refer to.
- `PartyCollider` object, spatially defining a volume that affects particles.
- `PartyEffector` object, defining a type of transformation or behavior of particles inside the volume.

Variable | Type | Description
--- | --- | --------
`effectorComponents` | `{Struct}` | A struct consisting of effector+collider pairs defining custom particle components.

There's a wide variety of colliders and effectors, but more on them later. For now, it's enough to know they are bound to the particle type, but every object (among colliders and effectors) can be repurposed for other components or other particle types.
 It's important to mention this field cannot be decorated during emission. If it ends up seeming like a cool feature I'm open to authoring it for decorators and solvers as well.

`static componentSet(key, effectorRef, colliderRef)`
**Description:** Sets a component by referring to the effector and collider pair, also giving it a key (name).
Param| Type | Description
--- | --- | --------
`key` | `{String}` | A key (or a name) given to this component
`effectorRef` | `{Struct.GMPartyEffector}` | Reference to an effector object defining a type of transformation.
`key` | `{String}` | Reference to a collider object defining the volume, testing which particles should be affected by the effector object.

`static componentGet(key)`
**Description:** Checks if a component with a given `key` exists, returning it if it does.
Param| Type | Description
--- | --- | --------
`key` | `{String}` | A key (or a name) of the wanted component.
Returns | `{Struct}` or `undefined` | Returns the struct defining the wanted component, otherwise returns `undefined`.

`static componentRemove(key)`
**Description:** Removes a component with a given `key` if it exists.
Param| Type | Description
--- | --- | --------
`key` | `{String}` | A key (or a name) of the wanted component.

These component structs only contain two fields:
Variable | Type | Description
--- | --- | --------
`effectorRef` | `{Struct.GMPartyEffector}` | Reference to the effector of this component.
`colliderRef` | `{Struct.GMPartyCollider}` | Reference to the collider of this component.

## Example
```js
[Create Event]
// Create a solver, allocate 100k particles.
solver = new GMPartySolver(100000);
// Create a particle type, edit its fields
part = new GMPartyType();
/*snip*/
// Create a magnetic sphere
collider = new GMPartyColliderSphere(x, y, 0, 1024);
effector = new GMPartyEffectorAttractor(5.0);
part.componentSet("yeah b, magnets!", effector, collider);

[Step Event]
// Move the collider to our position
collider.x = self.x;
collider.y = self.y;
// Make the intensity of the effector proportional to our speed
effector.force = self.speed * 0.5;
```
---
<- [Solvers](solvers.md)

-> [Emitters](emitters.md)
