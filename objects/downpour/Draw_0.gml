draw_clear(c_black);

var _cam = camera_get_active();

yaw -= (window_mouse_get_x() - window_get_width() / 2) / 10;
pitch -= (window_mouse_get_y() - window_get_height() / 2) / 10;
pitch = clamp(pitch, -80, 80);

window_mouse_set(window_get_width() / 2, window_get_height() / 2);

if (keyboard_check_direct(vk_escape)) {
    game_end();
}

var _spd = 4;

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
if (keyboard_check(vk_space)) {
    z += _spd * (-1 + keyboard_check(vk_control)*2);
}

var _xt = x + dcos(yaw),
	_yt = y - dsin(yaw),
	_zt = z - dsin(pitch);

camera_set_view_mat(_cam, matrix_build_lookat(x, y, z, _xt, _yt, _zt, 0, 0, 1));
camera_set_proj_mat(_cam, matrix_build_projection_perspective_fov(60, window_get_width() / window_get_height(), 1, 32000));
camera_apply(_cam);

solver.renderSetCamera(_xt - x, _yt - y, _zt - z);
solver.render();
