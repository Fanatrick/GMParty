# GMParty 0.8.1 (experimental)
**Party** is a modern, 3d particle system for GameMaker. It's simple to use, scalable, extensible and offers high performance by leveraging the GPU. It can hook itself onto GameMaker's standard particle system, emulating it on the GPU while also providing the user with superpowers.

*Party is currently experimental. Feel free to report issues and submit PRs.*

## Features
- **High performance** - process and render millions of particles in parallel
- **Stateful, non-parametric system** - each particle is a separate discrete entity
- **Plug-n-play** - can override or run on top of the standard GM CPU particle system

**Party** provides nearly everything the standard GM particle system does while improving it in a couple of ways:

- Additional dimension
- Additional color and alpha tween components
- Additional emission shapes and settings
- Additional randomization fields including delta and wiggle for each particle component
- Stateful fields such as gravity, sprite_index, etc. which are stateless in standard GM
- Deterministic emission states - allowing you to repeat/loop emission patterns
- Particle components - solve complex, emerging behavior of individual particle types
- Effectors - attractors, destructors, painters, colliders, custom processors
- Collider shapes - spheres, boxes, cylinders, sprites
- Additional particle flags and common built-in behavior
- VRAM management - Party will automatically upscale/downscale and rearrange memory buffers of living solvers
- Physics

**Party** currently does not support:

- **part_type_step**
- **part_type_death**

## Requirements

- GameMaker version 2023.4 or above
- Target platform needs to support:
  - **surface_rgba16float** or **surface_rgba32float** surface formats
  - Texture lookups for vertex shaders
  - [GMD3D11.dll](https://github.com/blueburncz/GMD3D11) is included, enabling VTF on Windows

## Credits

- [blueburncz/GMD3D11](https://github.com/blueburncz/GMD3D11)