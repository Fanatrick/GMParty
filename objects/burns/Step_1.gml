collider0.x = x + dcos(-yaw) * 2000;
collider0.y = y + dsin(-yaw) * 2000;
collider0.z = z;

emitter.emitRot.pitch = 180;
emitter.emitRot.roll = current_time / 20;

// Emit 2000 particles, decorate them with an emitter
solver.emit(part, 2000, emitter);

// Process a single step
solver.process();

// End the game
if (keyboard_check_direct(vk_escape)) {
    game_end();
}