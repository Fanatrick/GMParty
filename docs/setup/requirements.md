# [Documentation](../documentation.md)
## Requirements
### GameMaker:
- IDE `>= v2023.400`
- Runtime `>= v2023.400`

### Platform requirements:
- Shader backend `GLSL` / `GLSL-ES` `v100`
- Surface format `surface_rgba32float`
- Vertex texture fetching

## Limitations
**Party** hooks currently do not support:
- **part_type_step**
- **part_type_death**

**Known issues**:
- Behavior of GPU particles deviates from their standard CPU counterparts in some areas
- Distribution can be wrong depending on device/platform
- Missing **clear()** methods for **GMPartyType** and **GMPartyWrapper**
- Shader uniforms should be cached for performance
- Particle component processing sequence is not guaranteed
- In 3d, view matrix needs to be reapplied after **GMPartySolver** calls
- Snapshots are currently bugged, making fbos volatile on device driver context updates (going full-screen and such)

---
-> [Installation](docs/setup/installation.md)

