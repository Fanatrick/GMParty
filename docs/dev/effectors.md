# [Documentation](docs/documentation.md)
# Effectors
Party utilizes `effectors` in describing behaviors that occur when a particle ends up inside a collider.

## Prototype
`GMPartyEffectorPrototype() constructor`
Serves as a parent from which all effectors inherit common behavior.
Variable | Type | Description
--- | --- | --------
`shader` | `{Asset.GMShader}` | Points to a shader that performs the transformation of this effector.
`static cellBuffer` | `{Id.VertexBuffer}` | Holds an internal vertex buffer which can then affect specific cell components.

`static cellSubmit(solver, cell)`
**Description:** 
Param| Type | Description
--- | --- | --- | --------
`solver` | `{Struct.GMPartySolver}` | Solver reference, lets the effector know who the caller is.
`cell` | `{Enum.e_gmpartyComponent}` | Points to which cell component this effector transforms. Effectors are allowed to edit multiple cell components.

`static ping()`
**Description:** Pings the solver to prepare this effector.

`static submit()`
**Description:** Submits the effector transformation to the solver.

`static pong()`
**Description:** Pongs the solver to finalize this effector.

## Effector types
`GMPartyEffectorAccelerator(xspeed, yspeed, zspeed) : GMPartyEffectorPrototype() constructor`
This effector will accelerate all particles it collides with by a designated speed vector.
Param | Type | Description
--- | --- | --- | --------
`xspeed` | `{Real}` | X acceleration.
`yspeed` | `{Real}` | Y acceleration.
`zspeed` | `{Real}` | Z acceleration.
Returns | `{Struct.GMPartyEffectorAccelerator}` | Returns new `GMPartyEffectorAccelerator` effector reference.

`GMPartyEffectorAttractor(force, [absolute=false]) : GMPartyEffectorPrototype() constructor`
This effector will attract all particles it collides with towards it's distance field. Negative force can be passed as an input.
Param | Type | Description
--- | --- | --- | --------
`force` | `{Real}` | Force applied to colliding particles.
`*optional*absolute` | `{Bool}` | Should the applied force be absolute or relative to the distance field.
Returns | `{Struct.GMPartyEffectorAttractor}` | Returns new `GMPartyEffectorAttractor` effector reference.

`GMPartyEffectorDestructor(force, [absolute=false]) : GMPartyEffectorPrototype() constructor`
Depending on the force applied to particles it collides with, this effector will remove an amount of life from them. This value cannot be negative (life cannot be added to particles this way).
Param | Type | Description
--- | --- | --- | --------
`force` | `{Real}` | Force applied to colliding particles.
`*optional*absolute` | `{Bool}` | Should the applied force be absolute or relative to the distance field.
Returns | `{Struct.GMPartyEffectorDestructor}` | Returns new `GMPartyEffectorDestructor` effector reference.

`GMPartyEffectorCollider([mass=1.0]) : GMPartyEffectorPrototype() constructor`
This effector applies physics-based collisions for the collider it is bound to.
Param | Type | Description
--- | --- | --- | --------
`*optional*mass` | `{Bool}` | Collider object's physical mass.
Returns | `{Struct.GMPartyEffectorCollider}` | Returns new `GMPartyEffectorCollider` effector reference.

# Special types
There are a couple of special effector types that require additional explanation.
## Painter
This effector paints every particle colliding with it, operating on individual components of a desired color space.

## Enums
`enum e_gmpePaintMode`
Variants define a painting operation across RGBA components.
Variant | Description
--- | --------
`Nop` | No operation on this component.
`Mix` | Interpolate between source and input channels.
`Add` | Add input to source channels.
`Scroll` | Add input to source channels and wrap-around.

`enum e_gmpePaintSpace`
Variants define a color space.
Variant | Description
--- | --------
`RGB` | Perform operations in RGB color space.
`*todo*HSV` | Perform operations in HSV color space.

## Constructor
`GMPartyEffectorPainter(input, [modes=undefined], [force=1.0], [space=e_gmpePaintSpace.RGB], [indices=undefined]) : GMPartyEffectorPrototype() constructor`
Constructs a painter effector
Param | Type | Description
--- | --- | --------
`input` | `{Array<4, f32>}` | A 4-component array, serving as input color per RGBA channel.
`*optional*modes` | `{Array<4, Enum.e_gmpePaintMode>}` | 4-component array defining which operation should occur on which color channel.
`*optional*force` | `{Real}` | Relative painting force multiplier.
`*optional*space` | `{Enum.e_gmpePaintSpace}` | Defines a color space with which the effector will be working.
`*optional*indices` | `{Array<4, Bool>}` | An array of 4 bools, each telling the effector to either affect or skip a certain channel.
Returns | `{Struct.GMPartyEffectorPainter}` | Returns new `GMPartyEffectorPainter` effector reference.

## Example
```js
// Create our stuff
solver = new GMPartySolver(100000);
part = new GMPartyType();
/*SNIP*/

// Create our box collider
collider = new GMPartyColliderBox(-10000, -10000, 1000, 20000, 20000, 256);
// Create our painter processor, adding to red and subtracting from blue
effector = new GMPartyEffectorPainter(
	[5, 0, -5, 0],	// Input is now ???A(5, 0, -5, 0)
	[
		e_gmpePaintMode.Add,	// Add input[0] to source[0]
		e_gmpePaintMode.Nop,	// No-op on source[1]
		e_gmpePaintMode.Add,	// Add input[2] to source[2] (subtract)
		e_gmpePaintMode.Nop		// No-op on source[3]
	],
	e_gmpePaintSpace.RGB,	// Input is now RGBA(5, 0, -5, 0)
	[1, 0, 1, 0]	// Affect only first and third channels
);

part.componentSet("paint it, !black", effector, collider);
```

## \*WIP\* Processor
This effector lets you build simple custom processors. Its use cases are fringe, but it's here for simple transformations without the need for touching the shader backend at all.

## Enums
`enum e_gmpeInstruction`
Variants define an operation to be done on the cell.
Variant | Description
--- | --------
`Nop` | No operation on this component.
`Set` | Set to reg0..reg1 range.
`SetCmp`| Set to reg0 if comparison reg1 passes with values from vector reg2 component reg3.
`Add` | Add reg0.
`AddCmp` | Add reg0 if comparison reg1 passes with values from vector reg2 component reg3.
`Sub` | Subtract reg0.
`SubCmp` | Subtract reg0 if comparison reg1 passes with values from vector reg2 component reg3.
`Div` | Divide with reg0.
`DivCmp` | Divide reg0 if comparison reg1 passes with values from vector reg2 component reg3.
`Mul` | Multiply with reg0.
`MulCmp` | Multiply reg0 if comparison reg1 passes with values from vector reg2 component reg3.
`Clamp` | Clamp between reg0 and reg1.
`ClampCmp` | Clamp between reg0 and reg1 if comparison reg2 passes with values from vector reg3 component reg4.
`LEN` | Total number of instructions.

`enum e_gmpeCmpfunc`
Variants describe the comparison operation between registers.
Variant | Description
--- | --------
`Nop` | Never passes comparison.
`Less` | Passes if A < B
`LessEqual` | Passes if A <= B
`Equal` | Passes if A == B
`Unequal` | Passes if A != B
`GreaterEqual` | Passes if A >= B
`Greater` | Passes if A > B

## Constructor
`GMPartyEffectorProcessor(cell, instructions, reg0, reg1, reg2, reg3, reg4, reg5) : GMPartyEffectorPrototype() constructor`
Constructs a custom processor effector.
Param | Type | Description
--- | --- | --------
`cell` | `{Enum.e_gmpartyComponent}` | Which cell should this processor affect.
`instructions` | `{Array<4, Enum.e_gmpeInstruction>}` | 4-component array defining instructions across cell components.
`reg0` | `{Array<4, f32>}` | 4-component array describing register 0
`reg1` | `{Array<4, f32>}` | 4-component array describing register 1
`reg2` | `{Array<4, f32>}` | 4-component array describing register 2
`reg3` | `{Array<4, f32>}` | 4-component array describing register 3
`reg4` | `{Array<4, f32>}` | 4-component array describing register 4
`reg5` | `{Array<4, f32>}` | 4-component array describing register 5

## Example
```js
// Clamp all particles inside some space
collider = new GMPartyColliderGlobal();
effector = new GMPartyEffectorProcessor(
	e_gmpartyComponent.Position,	// Affect position cell
	[
		e_gmpeInstruction.Clamp,	// Clamp position.x
		e_gmpeInstruction.Clamp,	// Clamp position.y
		e_gmpeInstruction.Clamp,	// Clamp position.z
		e_gmpeInstruction.Nop,		// Don't touch flag cell component!
	],
	[-1000, -750, -500, 0],	// Clamp min becomes reg0
	[1000, 1250, 1500, 0]	// Clamp max becomes reg1
	/*the rest can be left undefined*/
)
part.componentSet("clamping", effector, collider);
```
---
<- [Colliders](docs/dev/colliders.md)
-> [SDF3D](docs/dev/sdfs.md)
