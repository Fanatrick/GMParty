// Feather disable GM1041
if !instance_exists(system.id) {
	instance_destroy();
	exit;
}

var _cc = (stream_count < 0) ? irandom(abs(stream_count)) : stream_count;

if !is_undefined(stream_type) && _cc > 0 {
	var _remain = _cc;
	while (_remain > 0) {
		var _n = min(_remain, GMPARTY_EMIT_MAX);
		system.solver.emit(stream_type, _n, emitter);
		_remain -= _n;
	}
}
