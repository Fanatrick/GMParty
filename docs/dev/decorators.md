# [Documentation](../documentation.md)
# Decorators
As briefly touched upon in [emitters](emitters.md), most of the particle configuration can be "overridden" if we pass a decorator struct as input to `GMPartySolver::emit()` call.
These decorators can be repurposed across solvers and particle types, and are a powerful tool for defining emitters and leveraging stateful behavior of Party particles.

## Constructor
`GMPartyDecorator() constructor`
Constructs an empty decorator object.
Param| Type | Description
--- | --- | --- | --------
Returns | `{Struct.GMPartyDecorator}`

Decorators by themselves contain no fields or methods whatsoever. They're basically a blank slate, where you can define particle type configuration overrides. For example, a particle type can have its emission vector directed towards a random point on a sphere. By passing a decorator that has its emission vector pointed in front of it, we can override the particle type vector with it.

## Example
```js
[Create Event]
// Create a solver, allocate 100k particles.
solver = new GMPartySolver(100000);

// Create a particle type.
part = new GMPartyType();
// This particle is configured to be fired in a random direction.
part.xdir	= { min : 0.0, max : 360.0 };
part.ydir	= { min : 0.0, max : 360.0 };
part.zdir	= { min : 0.0, max : 360.0 };

// Create a decorator to be used as an emitter
emitter = new GMPartyDecorator();
// Make it override and shoot all particles decorated by it upwards
emitter.xdir = { min : 0.0, max : 0.0 };
emitter.ydir = { min : 0.0, max : 0.0 };
emitter.zdir = { min : -90.0, max : -90.0 };

[Step Event]
// Emit 2000 particles, decorate them with our emitter
solver.emit(part, 2000, emitter);

// Process a single step
solver.process();

```
---
<- [Emitters](emitters.md)

-> [Colliders](colliders.md)

