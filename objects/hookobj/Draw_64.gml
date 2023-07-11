draw_text(16, 16, "test");
//part_emitter_burst(sys, emit, part, 500);

shader_set(GMParty_shd_visualizer);
draw_surface_stretched(sys.solver.getSurfaceParticle(), 0, 64, 256, 256);
shader_reset();
