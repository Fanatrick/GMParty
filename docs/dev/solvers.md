# [Documentation](../documentation.md)
# Solvers
Party solvers process and contain states of particle simulations. They are equivalent to `part_system` in standard GML. They can be instantiated by calling `GMPartySolver()` constructor.

## Constructor
`GMPartySolver([num=GMPARTY_DEFAULT_SOLVER_SIZE]) constructor`
Constructs a new Party solver object allocating `num` or `default` amount of particle indices.
Param| Type | Description
--- | --- | --------
`*optional*num` | `{Real}` | Number of particle indices this solver will allocate at creation. **Default: GMPARTY_DEFAULT_SOLVER_SIZE**
Returns | `{Struct.GMPartySolver}`

## Enums
`enum e_gmpartyComponent`
Each variant describes up to 4 particle components (sometimes more depending on encoding).
Variant | Particle components
--- | --------
0: `Life` | life, life_max, seed, type
1: `Position` | x, y, z, **FLAGS**
2: `Speed` | xspeed, yspeed, zspeed, **BLEND_MODE**
3: `Acceleration` | acceleration, acceleration_wiggle, *empty*, *empty*
4: `Scale` | xscale, yscale, zscale, size
5: `ScaleDelta` | delta_xscale, delta_yscale, delta_zscale, delta_size
6: `ScaleWiggle` | wiggle_xscale, wiggle_yscale, wiggle_zscale, wiggle_size
7: `Orientation` | xangle, yangle, zangle, snap_direction
8: `OrientationDelta` | xrot, yrot, zrot, **empty**
9: `OrientationWiggle` | wiggle_xrot, wiggle_yrot, wiggle_zrot, **empty**
10: `DirectionDelta` | delta_xdir, delta_ydir, delta_zdir, **empty**
11: `DirectionWiggle` | wiggle_xdir, wiggle_ydir, wiggle_zdir, **empty**
12: `Image` | image_index, image_max, image_speed, sprite_index
13: `Color` | color0, color1, color2, color3
14: `Alpha` | alpha0, alpha1, alpha2, alpha3
15: `Physics` | mass, restitution, gravity_intensity, gravity_octahedral_direction
`LEN` | Total number of component cells

`enum e_gmpartyOverflow`
Describes behavior during emission buffer overflows.
Variant | Description
--- | -------
`Strict` | Only allows a strict maximum number of particles. This variant makes the solver overwrite oldest particles on overflow.
`Optimal` | Allows an optimal maximum number of particles that can fit the texture size (for example if solver allocates `100`, the texture can actually handle 128)
`Upscale` | Solver will upscale and rearrange memory to satisfy new requirements.

## Fields
Party solvers internally leverage GPU memory by encoding particle states as textures stored in VRAM. These shouldn't be mutated by the end-user, but are here to provide info to the internal system and user-facing API.
Variable | Type | Description
--- | --- | --------
`surfaceSlotSize` | `{Real}` | Cell size in pixels.
`surfaceTexSize` | `{Real}` | Texture size in pixels.
`surfaceParticleIndex` | `{Surface.Id}` | Surface ID of the current state of particles in the solver.
`surfacePongIndex` | `{Surface.Id}` | Surface ID of the internal pong surface.
`surfaceSnapshotBuffer` | `{Buffer.Id}` | Buffer ID of the last state snapshot.

Party solvers track emission events, keeping a neat stack of all particles, their texture pages, life expectancies, blend modes and sprite bindings.

Variable | Type | Description
--- | --- | --------
`count` | `{Real}` | Number of particles kept in memory by this solver.
`countAlive` | `{Real}` | Number of particles tracked as being alive by this solver.
`countTimer` | `{Real}` | Number of consistent alive steps processed.
`countTell` | `{Real}` | Current particle ID buffer position.
`countOverflowSetting` | `{Enum.e_gmpartyOverflow}` | Describes behavior during emission overflow.
`countUnderflowCorrection` | `{Bool}` | Should the solver downscale memory consumption when emission becomes lower than expected.
`countUnderflowAllocMin` | `{Real}` | Minimum allocation during underflow.
`countMax` | `{Real}` | Max number of particles.
`countMaxEffective` | `{Real}` | Effective max number of particles (`countOverflowSetting` dependent).

Solvers contain key-value maps which describe the current state on the CPU side of things.

Variable | Type | Key:Value | Description
-- | -- | ---- | ------
`countMap` | `{Struct}` | `particle_index:particle_type_ref` | Map of all particle indices currently marked as living in the solver, containing references to their particle types and their number.
`spriteMap` | `{Struct}` | `sprite_index:particle_num` | Map of all sprite_index bindings in this solver, each containing a number of living particles with that specific sprite.
`blendingMap` | `{Struct}` | `blend_mode:particle_num` | Map of all tracked blend_mode bindings.
`texBindings` | `{Struct}` | `texture_page:particle_indices` | Map of all texture bindings matching their particle types.
`texBindingsObsolete` | `{Bool}` | - | If the current `texBindings` are obsolete and need to be recreated before rendering.

Solvers have their own position offsets which are applied during rendering. These are only here to satisfy GM standard `part_system_position` function calls.
Variable | Type | Description
--- | --- | --------
`translateX` | `{Real}` | X offset applied during rendering
`translateY` | `{Real}` | Y offset applied during rendering
`translateZ` | `{Real}` | Z offset applied during rendering

Solvers usually render particles and vertex buffers sorted back-to-front. This behavior can be toggled.
Variable | Type | Description
--- | --- | --------
`drawFTBParticles` | `{Bool}` | Should this solver draw individual particles sorted front-to-back.
`drawFTBBuffers` | `{Bool}` | Should this solver draw individual batch buffers sorted front-to-back.

## Getters and internals
Solvers provide a couple of getters and expose their surface internals.

`static getSurfaceParticle()`
**Description:** Returns the particle state as a surface index.
Param | Type | Description
--- | --- | --------
Returns | `{Id.Surface}` | Returns the particle state surface index, rebuilding it from snapshot if available.

`static getSurfacePong()`
**Description:** Returns a pong surface index.
Param | Type | Description
--- | --- | --------
Returns | `{Id.Surface}` | Returns the pong surface index, rebuilding it from snapshot if available.

`static swap()`
**Description:** Performs a swap between particle state and pong surface references.

`static sync()`
**Description:** Syncs pong surface with current particle state.

## Snapshots

Solvers can serialize snapshots of their particle state.

`static snapshotExists()`
**Description:** Checks if a snapshot of this solver exists in memory.

`static snapshotWrite()`
**Description:** Writes a new snapshot of this solver.

`static snapshotRead()`
**Description:** Reads particle state from the last snapshot.

`static snapshotFree()`
**Description:** Frees state snapshots from memory.

## Emission, simulation, rendering
Solvers process the simulation in steps, it is not a delta-timed approach. To have something moving we first have to emit a number of particles (while optionally decorating them).
`static emit(part, num, [decorator])`
**Description:** Emits a number of particles of a certain type, while decorating them with a decorator struct.
Param| Type | Description
--- | --- | --------
`part` | `{Struct.GMPartyType}` | Particle type reference.
`num` | `{Real}` | Number of particles to emit.
`*optional* decorator` | `{Struct}` | Optional decorator struct.
Returns | `{Struct.GMPartySolver}`

Once we have an active solver with living particles inside, we can use `process()` to simulate a the next frame.
`static process()`
**Description:** Processes a single step of particle simulation, including their behavior components.

Finally, we can render this solver in one of our draw events (or onto another framebuffer).
`static render([shader=GMParty_shd_render])`
**Description:** Renders the solver, optionally with your own custom shader.
Param| Type | Description
--- | --- | --- | --------
`*optional* shader` | `{Asset.GMShader}` | Custom shader to render the solver with.

Some particles can be flagged as 3d or billboards. In such cases, we need to update the renderer with our camera position.
`static renderSetCamera(cx, cy, cz)`
**Description:** Updates the internal renderer with the camera's position vector.
Param| Type | Description
--- | --- | --------
`cx` | `{Real}` | Camera X
`cy` | `{Real}` | Camera Y
`cz` | `{Real}` | Camera Z

## Cleanup
After we're done with the solver it's important we free it from memory.
`static clear()`
**Description:** Removes all particles and their bindings from this solver, basically resetting it.

`static free()`
**Description:** Frees the solver and it's resources from memory, marking it for GC.


## Example
```js
[Create Event]
// Create a new solver, allocate 2000 particles to it
mySolver = new GMPartySolver(2000);
// Keep our solver's particle count strictly below maximum
mySolver.countOverflowSetting = e_gmpartyOverflow.Strict;
// Create a new particle type, do stuff with it
myParticle = new GMPartyType();
myParticle.life = { min: 30, max: 60 };
/* SNIP */

[Step Event]
// Emit a 100 particles of our particle type
mySolver.emit(myParticle, 100);

[Draw Event]
mySolver.render();

[Cleanup Event]
mySolver.free();
```
---
<- [Configuration](../setup/configuration.md)

-> [Particle types](types.md)

