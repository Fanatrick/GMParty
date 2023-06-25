//collider0.x = 256 + sin(current_time *.003) * 128;
//collider0.y = 256 + cos(current_time *.003) * 128;
//emitter.gravityDirection = { x : sin(current_time * 0.)*.2, y : cos(current_time * 0.)*.2, z : 1.0 };

solver.emit(part, 250, emitter);
solver.process();

