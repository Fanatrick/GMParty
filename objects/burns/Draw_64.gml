// Draw instructions
draw_text_color(16, 16, string(
	"WASD: Move around\nQ/E: Ascend/Descend\nTracked: {0}\nAlive: {1}",
	solver.count,
	solver.countAlive
	), c_red, c_red, c_red, c_red, 1
);

//shader_set(GMParty_shd_visualizer);
//draw_surface(model_sdf.emitter, 0, 80);
//shader_reset();
