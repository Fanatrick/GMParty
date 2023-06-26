// Emit 1000 particles of some type, decorating them with an emitter
solver.emit(part, 1000, emitter);

// Process a single step
solver.process();

// End the game
if (keyboard_check_direct(vk_escape)) {
    game_end();
}