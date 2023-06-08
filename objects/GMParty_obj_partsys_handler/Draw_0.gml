if automatic_draw {
	if (solver.count > 0) {
		gpu_push_state();
		solver.render();
		gpu_pop_state();
	}
}
