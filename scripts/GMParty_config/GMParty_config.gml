#macro GMPARTY_VERSION ((0<<16)+(8<<8)+(5))
#macro GMPARTY_VERSION_STRING (string("{0}.{1}.{2}", GMPARTY_VERSION>>16, (GMPARTY_VERSION & 0xFFFF)>>8, (GMPARTY_VERSION & 0xFF)))

#macro GMPARTY_TEXTURE_SIZE_MAX		(4096)
#macro GMPARTY_TEXTURE_CELL_COUNT	(e_gmpartyComponent.LEN)
#macro GMPARTY_TEXTURE_GRID_SIZE	ceil(sqrt(GMPARTY_TEXTURE_CELL_COUNT))
#macro GMPARTY_TEXTURE_CELL_SIZE	(GMPARTY_TEXTURE_SIZE_MAX div GMPARTY_TEXTURE_GRID_SIZE)
#macro GMPARTY_TEXTURE_INDEX_COUNT	(GMPARTY_TEXTURE_CELL_SIZE * GMPARTY_TEXTURE_CELL_SIZE)

#macro GMPARTY_EMIT_MAX (4096)			// maximum number of gmpartycles emitted at once (should be kept as a power-of-2 int)
#macro GMPARTY_EMIT_BUFFERS (ceil(log2(GMPARTY_EMIT_MAX)) + 1)	// number of prebaked buffers needed to satisfy EMIT_MAX
#macro GMPARTY_EMIT_SEED_MOD (65536)	// seed modulo, prevents precision errors on mobile

#macro GMPARTY_RENDER_MIN (1)			// minimum render buffer size
#macro GMPARTY_RENDER_MAX (GMPARTY_TEXTURE_INDEX_COUNT)			// maximum render buffer size
#macro GMPARTY_RENDER_BUFFERS (ceil(log2(GMPARTY_RENDER_MAX)) - ceil(log2(GMPARTY_RENDER_MIN)) + 1)

#macro GMPARTY_DEFAULT_SOLVER_SIZE (128) //(512*512)
#macro GMPARTY_SHAPE_SPRITE_INDEX (GMParty_spr_pt_shape)

#macro GMPARTY_UTILS_SDF3D (true)
#macro GMPARTY_UTILS_SDF3D_PATH "SDF3D/sdf3d.dll"

#macro GMPARTY_UTILS_GMD3D11_PATH "GMD3D11/GMD3D11.dll"
