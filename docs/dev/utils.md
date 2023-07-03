# [Documentation](../documentation.md)
# Utilities
Party includes `GMParty_utils.gml` and uses it internally. Not a whole lot of it is important, but there are a couple of useful functions that can be utilized. This library is "lazily-loaded" as a struct and can be referred to like this:
```js
myParticle = new GMPartyType();
utils = gmpartyUtils();
thisParticle = utils.particleFromId(myParticle.index);
assert_equal(myParticle.index, thisParticle.index, "");
```

## Enums
`enum e_vertexComponent`
Variants represent formats of all available vertex attributes.
Variant | Vertex component
--- | --------
`Position2d` | `{f32, f32}` 2d world position
`Position3d` | `{f32, f32, f32}` 3d world position
`Color` | `{u8, u8, u8, u8}` color components
`Texcoord` | `{f32, f32}` texture coords
`Normal` | `{f32, f32, f32}` normal vector
`Float1` | `{f32}` floating point value
`Float2` | `{f32, f32}` floating point values
`Float3` | `{f32, f32, f32}` floating point values
`Float4` | `{f32, f32, f32, f32}` floating point values
`Ubyte4` | `{u8, u8, u8, u8}` unsigned byte values

## particleFromId
This function serves as a global accessor for particle types. Each particle type created is assigned a unique id as an `index` field.
`particleFromId : function(ind)`
**Description:** Returns a reference to a particle type previously created with a matching index.
Param | Type | Description
--- | --- | --------
`ind` | `{Real}` | Unique `GMPartyType` index.
Returns | `{Struct.GMPartyType}` | Reference to a `GMPartyType` object, or `undefined` if an index does not exist.

## vformatCache
Creates a vertex format from an array of `e_vertexComponent` variants, or returns it if it was previously created.
`vformatCache : function(vformat_array)`
**Description** Returns a vertex format with vertex components passed as an array. 
Param | Type | Description
--- | --- | --------
`vformat_array` | `{Array<Enum.e_vertexComponent>}` | An array consisting of `e_vertexComponent` variants describing a vertex format.
Returns | `{Id.VertexFormat}` | Vertex format index.

```js
// Create a matching vertex format array of this vertex buffer.
model_vf = [
	e_vertexComponent.Position3d,
	e_vertexComponent.Normal,
	e_vertexComponent.Color
];
// Create a vb out of it.
model_vb = vertex_create_buffer_from_buffer(model_buff, utils.vformatCache(model_vf) );
// Create an sdf
model_sdf = gmpartySDF3DCreate(model_vb, model_vf, 2048, true, true);
```

## GL Config
Depending on platform, you might want to change the way textures are staged to `fragment` and `vertex` shaders, or check whether the GPU device meets certain requirements.

`glShaderStageVS : function(sampled_id, texture_id)`
`glShaderStageFS : function(sampled_id, texture_id)`
**Description:** These functions are used internally by Party to set the stage of the currently bound shader program. This is where you can reconfigure the default behavior.
Param | Type | Description
--- | --- | --------
`sampled_id` | `{Id.Sampler}` | Shader sampler uniform index.
`texture_id` | `{Pointer.Texture}` | Texture index.

`glConfigGet : function()`
**Description:** Returns a struct containing gl device constants.
Param | Type | Description
--- | --- | --------
Returns | `{Struct}` | Returns a struct containing these values:

Const | Description
--- | ---
`gl_MaxTextureImageUnits` | Max number of texture units that are available per shader type.
`gl_MaxCombinedTextureImageUnits` | Max number of combined texture units per pipeline.
`gl_MaxDrawBuffers` | Max number of simultaneous draw buffers.
`gl_MaxFragmentUniformVectors` | Max number of `uniform` vectors available in fragment shaders.
`gl_MaxVaryingVectors` | Max number of available `varying` vectors.
`gl_MaxVertexAttribs` | Max number of `attributes` available to vertex buffers.
`gl_MaxVertexTextureImageUnits` | Max number of texture units available in vertex shaders.
`gl_MaxVertexUniformVectors` | Max number of `uniform` vectors available in vertex shaders.
`__VERSION__` | GL version.
`GL_ES` | If using an embeddable (bare essentials) subset of GL.
`GL_VTF`| If vertex texture fetching is available.

---
<- [Hooks](hooks.md)
