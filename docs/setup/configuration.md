# [Documentation](../documentation.md)
## Configuration
Party can be configured by editing `GMParty/GMParty_config.gml`.
Parameter name | Type | Description
--- | --- | -----
`GMPARTY_VERSION` | `{Real}` | 24bits representing the version of Party currently running.
`GMPARTY_VERSION_STRING` | `{String}` | Party version formatted as a string.
`GMPARTY_TEXTURE_SIZE_MAX` | `{Real}` | Maximum texture size Party is allowed to allocate.
`GMPARTY_TEXTURE_CELL_COUNT` | `{Real}` | Number of cells (each storing 4 f32 components) per-particle
`GMPARTY_TEXTURE_GRID_SIZE` | `{Real}` | Size of the grid in vram (4x4 for 16 component cells)
`GMPARTY_TEXTURE_CELL_SIZE` | `{Real}` | Maximum cell size supported by `GMPARTY_TEXTURE_SIZE_MAX`
`GMPARTY_TEXTURE_INDEX_COUNT` | `{Real}` | Maximum number of particles supported by `GMPARTY_TEXTURE_INDEX_COUNT`
`GMPARTY_EMIT_MAX` | `{Real}` | Maximum number of particles able to be emitted at once. Depending on this value Party can prebake emission buffers.
`GMPARTY_EMIT_BUFFERS` | `{Real}` | Number of prebaked emission buffers needed to satisfy `GMPARTY_EMIT_MAX` 
`GMPARTY_EMIT_SEED_MOD` | `{Real}` | Emission RNG modulo, keeping it low (~2^8) prevents precision errors on some hardware.
`GMPARTY_RENDER_MIN` | `{Real}` | Minimum render buffer size.
`GMPARTY_RENDER_MAX` | `{Real}` | Maximum render buffer size.
`GMPARTY_RENDER_BUFFERS` | `{Real}` | Amount of pre-allocated render buffers needed to satisfy `MIN..MAX` range.
`GMPARTY_DEFAULT_SOLVER_SIZE` | `{Real}` | Default solver size.
`GMPARTY_SHAPE_SPRITE_INDEX` | `{Resource.Id}` | Resource index of default GM particles sprite.
`GMPARTY_UTILS_SDF3D` | `{Bool}` | Should Party load SDF3D.dll
`GMPARTY_UTILS_SDF3D_PATH` | `{String}` | Path and fname pointing to SDF3D.dll

---
<- [Installation](installation.md)

-> [Solvers](..dev/solvers.md)

