# [Documentation](../documentation.md)
# Texture Emitters
Party also uses `SDF3D` to bake emission textures out of sprites. 

## Constructor
`GMPartyTextureEmitter() constructor`
Constructs a new SDF model container.
Param| Type | Description
--- | --- | --------
Returns | `{Struct.GMPartyTextureEmitter}`

## Fields
Similar to 3d SDFs `GMPartyTextureEmitter` objects also contain `emitter` struct.
Field | Value | Type | Description
--- | --- | --- | --------
emitter | `texture` | `{Id.Surface}` | Surface index describing this emitters memory in VRAM.
/ | `target` | `{Asset.GMSprite}` | A sprite resource targetted as a texture candidate.
/ | `width` | `{Real}` | Texture width.
/ | `height` | `{Real}` | Texture height.
/ | `emitters` | `{Real}` | Total number of emitters contained within this SDF emitter.
/ | `compressed` | `{Bool}` | Boolean describing if the emitter is compressed in RAM.

`static bake(sprite)`
**Description:** Bakes the emitter data making it possible to call `getEmitter()` for this emission target.
Param | Type | Description
--- | --- | --------
`sprite` | `{Asset.GMSprite}` | A sprite resource we want to represent as an emitter.
Returns | `{Bool}` | Returns `true` if the operation was successful.

`static getEmitter()`
**Description:** Safely returns the emitter texture stored in VRAM, recreating it from RAM if it's missing.
Param | Type | Description
--- | --- | --------
Returns | `{Id.Surface}` | Surface index of the emitter.

`static flush()`
**Description:** Flushes texture contents from VRAM.
Param | Type | Description
--- | --- | --------
Returns | None | -

`static free()`
**Description:** Frees the texture emitter and its resources from memory.
Param | Type | Description
--- | --- | --------
Returns | `{Bool}` | Returns `true` on successful operation.

## API
`gmpartyTextureEmitterCreate(sprite)`
**Description:** Constructs `GMPartyTextureEmitter` object out of a sprite binding.
Param| Type | Description
--- | --- | --------
`sprite` | `{Asset.GMSprite}` | Sprite index we want to turn into an emission texture.
Returns | `{Struct.GMPartyTextureEmitter}` | Reference to this emitter.

`gmpartyTextureEmitterFree(texemitter)`
**Description:** Frees the emitter and its resources from memory.
Param| Type | Description
--- | --- | --------
`texemitter` | `{Struct.GMPartyTextureEmitter}` | Reference to a texture emitter object being freed.
Returns | `{Bool}` | Returns `true` on successful operation.

## Example
```js
// Create an emitter decorator
emitter = new GMPartyDecorator();
// Create a texture emitter, bind it as an emission target
emit_sprite = gmpartyTextureEmitterCreate(spr_logo);
emitter.emitType = e_gmpartyEmitShape.Sprite;
emitter.emitTarget = emit_sprite;
emitter.emitOffset = [-sprite_get_xoffset(spr_logo), -sprite_get_yoffset(spr_logo)];
```
---
<- [SDF3D](sdfs.md)

-> [Hooks](hooks.md)
