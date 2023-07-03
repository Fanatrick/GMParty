# [Documentation](docs/documentation.md)
# \*WIP\* Hooks

## GameMaker standard
GameMaker standard particle system runs on the CPU, making it extremely slow in comparison to Party. It's also mostly stateless, meaning you can't really do any sort of emerging behavior on a per-particle basis. The ergonomics also leave a lot to be desired, but the user base is familiar with it and the community has been building tools supporting it for more than a decade.

## Party hooks
Party supports hooking onto the standard particle system, overriding its calls while still exposing its functionality. This makes the transition from standard to Party system effortless, even for projects already in development. 
It's easy to plug-n-play, frees up a big chunk of precious single-threaded CPU cycles, lets you leverage the tools and editors you grew accustomed to while providing additional functionality like distance fields, effectors, colliders and particle components.

## Contents
Party ships with `GMParty/hooks` directory. This directory consists of:

`GMParty_hooks.gml`
- Contains all function overrides and their implementation.
- Including this file into your project will override all standard `part_*()` functions.
- Commenting this file out, or removing it from the project disables these overrides.

`GMParty_obj_partsys_handler` `{Asset.GMObject}`
- `part_system_*` handler.
- Abstracts the standard GM particle system.

`GMParty_obj_partemitter_handler` `{Asset.GMObject}`
- `part_emitter_*` handler.
- Abstracts the standard GM particle emitter.

`GMParty_spr_pt_shape` `Asset.GMSprite`
- Acts like the default GM particle texture page.
- **IMPORTANT**: This file will soon be moved out of hooks since it serves as the default sprite of Party particle types.

## Usage
- Using Party hooks means you'll still be referring to the official GameMaker documentation during development.
- Overridden functions are saved and exposed globally with a `GM_` prefix added to them (ie. `GM_part_system_create()` is correct).

---
<- [SDF3D](docs/dev/sdfs.md)
-> [Utilities](docs/dev/utils.md)
