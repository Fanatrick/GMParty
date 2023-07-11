sys = part_system_create();
part = part_type_create();
emit = part_emitter_create(sys);

part_system_automatic_draw(sys, true);

part_type_shape(part, pt_shape_explosion);
//part_type_sprite(part, spr_burns, 1, 1, 0);
//part_type_speed(part, 1, 10, 0, 0);

part_emitter_stream(sys, emit, part, 500);
part_emitter_region(sys, emit, 0, 1400, 0, 800, ps_shape_ellipse, ps_distr_linear);
