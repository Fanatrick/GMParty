# [Documentation](docs/documentation.md)
# SDF3D
Party utilizes an external library `SDF3D` written in Rust to calculate distance fields out of 3d models. Internals are a bit complex and hidden away in `gmpartyUtils()` but the user-facing API is very straightforward.

## Constructor
`GMPartySDFModel() constructor`
Constructs a new SDF model container.
Param| Type | Description
--- | --- | --- | --------
Returns | `{Struct.GMPartySDFModel}`

## Fields
`GMPartySDFModel` objects contain `collider` and `emitter` structs.
Field | Value | Type | Description
--- | --- | --- | --------
`collider` | `texture` | `{Id.Surface}` | Surface index describing this colliders memory in VRAM.
- | `buffer` | `{Id.Buffer}` | Non-volatile RAM copy of collider data.
- | `size` | `{Real}` | Texture size.
- | `bbox` | `{Array<2, Array<3, f32>>}` | Bounding box coordinates
- | `volume` | `{Array<3, i32>}` | Volume of the SDF collider (discrete values across 3 dimensions).
- | `scale` | `{Array<3, f32>}` | Quantization factor (model_size.xyz / volume.xyz).
- | `voxels` | `{Real}` | Total number of voxels contained within this SDF collider.
- | `compressed` | `{Bool}` | Boolean describing if the collider is compressed in RAM.
emitter | `texture` | `{Id.Surface}` | Surface index describing this emitters memory in VRAM.
- | `buffer` | `{Id.Buffer}` | Non-volatile RAM copy of emitter data.
- | `size` | `{Real}` | Texture size.
- | `emitters` | `{Real}` | Total number of emitters contained within this SDF emitter.
- | `compressed` | `{Bool}` | Boolean describing if the emitter is compressed in RAM.

`static bake(vbuffer, vformat_array, texsize, winding, [compress=false])`
**Description:** Bakes the SDF data from 3d model data and additional config input.
Param | Type | Description
--- | --- | --- | --------
`vbuffer` | `{Id.VertexBuffer}` | Models vertex buffer.
`vformat_array` | `{Array<n, Enum.e_vertexComponent>}` | An array with vertex components describing the vertex format of the model.
`texsize` | `{Real}` | Texture resolution.
`winding` | `{Bool}` | Boolean describing vertex winding order (true = right, false = left)
`*optional*compress` | `{Bool}` | Should the baked SDF be compressed in RAM
Returns | `{Bool}` | Returns `true` if the operation was successful.

`static getCollider()`
**Description:** Safely returns the collider SDF texture stored in VRAM, recreating it from RAM if it's missing.
Param | Type | Description
--- | --- | --- | --------
Returns | `{Id.Surface}` | Surface index of the SDF collider.

`static getEmitter()`
**Description:** Safely returns the emitter SDF texture stored in VRAM, recreating it from RAM if it's missing.
Param | Type | Description
--- | --- | --- | --------
Returns | `{Id.Surface}` | Surface index of the SDF emitter.

`static write()`
**Description:** Serializes the SDF to a buffer.
Param | Type | Description
--- | --- | --- | --------
Returns | `{Id.Buffer}` | SDF serialized to a buffer.

`static read(buffer)`
**Description:** Loads the SDF from a buffer.
Param | Type | Description
--- | --- | --- | --------
`buffer` | `{Id.Buffer}` | Buffer containing a serialized SDF.
Returns | `{Bool}` | Returns `true` if the operation was successful.

`static flush()`
**Description:** Flushes SDF contents from VRAM.
Param | Type | Description
--- | --- | --- | --------
Returns | None | -

`static free()`
**Description:** Frees the SDF and its resources from memory.
Param | Type | Description
--- | --- | --- | --------
Returns | `{Bool}` | Returns `true` on successful operation.

## API
`gmpartySDF3DCreate(vbuffer, vformat_array, texsize, [winding=true], [compress = false])`
**Description:** Constructs `GMPartySDFModel` object out of a vertex buffer with given parameters.
Param| Type | Description
--- | --- | --- | --------
`vbuffer` | `{Id.VertexBuffer}` | Models vertex buffer.
`vformat_array` | `{Array<n, Enum.e_vertexComponent>}` | An array with vertex components describing the vertex format of the model.
`texsize` | `{Real}` | Texture resolution.
`*optional*winding` | `{Bool}` | Boolean describing vertex winding order (true = right, false = left).
`*optional*compress` | `{Bool}` | Should the baked SDF be compressed in RAM.
Returns | `{Struct.GMPartySDFModel}` | Reference to this SDF object.

`gmpartySDF3DFree(sdf)`
**Description:** Frees the SDF and its resources from memory.
Param| Type | Description
--- | --- | --- | --------
`sdf` | `{Struct.GMPartySDFModel}` | Reference to an SDF objects being freed.
Returns | `{Bool}` | Returns `true` on successful operation.

`gmpartySDF3DSave(sdf, fname)`
**Description:** Serializes the SDF object to a file.
Param| Type | Description
--- | --- | --- | --------
`sdf` | `{Struct.GMPartySDFModel}` | Reference to an SDF objects being saved.
`fname` | `{String}` | Filename string.
Returns | `{Bool}` | Returns `true` on successful operation.

`gmpartySDF3DLoad(fname)`
**Description:** Loads SDF object from a file.
Param| Type | Description
--- | --- | --- | --------
`fname` | `{String}` | Filename string.
Returns | `{Struct.GMPartySDFModel}` | Returns the reference to a loaded SDF object, or `undefined` on failure.

## Example
```js
// Get SDF from disk or bake a new one
model_sdf = gmpartySDF3DLoad("tree.sdf");
if is_undefined(model_sdf) {
	model_sdf = gmpartySDF3DCreate(model_vb, model_vf, 2048, true, true);
	gmpartySDF3DSave(model_sdf, "tree.sdf");
}
```
---
<- [Effectors](docs/dev/effectors.md)
-> [Hooks](docs/dev/hooks.md)

