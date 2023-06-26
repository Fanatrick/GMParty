// Clear our scene
draw_clear(c_black);

// Camera and movement
var _cam = camera_get_active();

if init {
	yaw -= (window_mouse_get_x() - window_get_width() / 2) / 10;
	pitch -= (window_mouse_get_y() - window_get_height() / 2) / 10;
	pitch = clamp(pitch, -80, 80);
}
init = true;

window_mouse_set(window_get_width() / 2, window_get_height() / 2);

var _spd = 8;

if (keyboard_check(ord("A"))) {
    x -= dsin(yaw) * _spd;
    y -= dcos(yaw) * _spd;
}
if (keyboard_check(ord("D"))) {
    x += dsin(yaw) * _spd;
    y += dcos(yaw) * _spd;
}
if (keyboard_check(ord("W"))) {
    x += dcos(yaw) * _spd;
    y -= dsin(yaw) * _spd;
}
if (keyboard_check(ord("S"))) {
    x -= dcos(yaw) * _spd;
    y += dsin(yaw) * _spd;
}
z += _spd * (keyboard_check(ord("E")) - keyboard_check(ord("Q")));

var _xt = x + dcos(yaw),
	_yt = y - dsin(yaw),
	_zt = z - dsin(pitch);

camera_set_view_mat(_cam, matrix_build_lookat(x, y, z, _xt, _yt, _zt, 0, 0, 1));
camera_set_proj_mat(_cam, matrix_build_projection_perspective_fov(60, window_get_width() / window_get_height(), 1, 32000));
camera_apply(_cam);

// Since we're drawing in 3d, our solver needs some camera context
solver.renderSetCamera(_xt - x, _yt - y, _zt - z);

// Render our solver
solver.render();
