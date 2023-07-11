emitter.emitRot = {
	yaw : current_time / 20,
	pitch : 0.0,
	roll : current_time / 14
}

// Emit 2000 particles, decorate them with an emitter
solver.emit(part, 1000, emitter);

// Process a single step
solver.process();

// End the game
if (keyboard_check_direct(vk_escape)) {
    game_end();
}
