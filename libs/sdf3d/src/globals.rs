use lazy_static::lazy_static;
use std::sync::Mutex;

use crate::Point3;

lazy_static! {
    static ref GLOBAL_STATE: Mutex<Config> = Mutex::new(Config::new());
}

#[derive(Clone)]
pub struct Config {
    pub vertex_size: usize,
    pub vertex_offset: usize,

    pub seed_xlen: usize,
    pub seed_ylen: usize,
    pub seed_zlen: usize,
    pub seed_bbox: [Point3<f32>; 2],

    pub seed_scale: Point3<f32>,

    pub winding: bool, // 0 = CCW, 1 = CW
}
impl Config {
    pub fn new() -> Self {
        Config {
            vertex_size: 0,
            vertex_offset: 0,
            seed_xlen: 0,
            seed_ylen: 0,
            seed_zlen: 0,
            seed_bbox: [
                Point3::new(std::f32::MAX, std::f32::MAX, std::f32::MAX),
                Point3::new(std::f32::MIN, std::f32::MIN, std::f32::MIN),
            ],
            seed_scale: Point3::new(1.0, 1.0, 1.0),
            winding: false,
        }
    }
}
pub fn set_config(new_config: Config) {
    let mut state = GLOBAL_STATE.lock().unwrap();
    *state = new_config;
}

pub fn get_config() -> Config {
    let state = GLOBAL_STATE.lock().unwrap();
    state.clone()
}
