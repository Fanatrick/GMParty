use libc::c_char;
use nalgebra::{Point3, Vector3};
use std::ffi::CStr;
use std::ffi::CString;
use std::i64;
use std::usize;
use std::vec::Vec;

mod globals;
mod utils;

#[derive(Debug)]
pub struct Triangle {
    vertices: [Point3<f32>; 3],
    normal: Vector3<f32>,
}
impl Triangle {
    pub fn new(coords: [Point3<f32>; 3]) -> Triangle {
        let conf = globals::get_config();
        let winding: bool = conf.winding;
        // w.r.t. winding order
        let edge1: nalgebra::Matrix<
            f32,
            nalgebra::Const<3>,
            nalgebra::Const<1>,
            nalgebra::ArrayStorage<f32, 3, 1>,
        > = coords[1] - coords[0];
        let edge2: nalgebra::Matrix<
            f32,
            nalgebra::Const<3>,
            nalgebra::Const<1>,
            nalgebra::ArrayStorage<f32, 3, 1>,
        > = coords[2] - coords[0];

        let normal: nalgebra::Matrix<
            f32,
            nalgebra::Const<3>,
            nalgebra::Const<1>,
            nalgebra::ArrayStorage<f32, 3, 1>,
        > = if winding {
            edge2.cross(&edge1).normalize() // CCW
        } else {
            edge1.cross(&edge2).normalize() // CW
        };

        Triangle {
            vertices: [
                Point3::new(coords[0].x, coords[0].y, coords[0].z),
                Point3::new(coords[1].x, coords[1].y, coords[1].z),
                Point3::new(coords[2].x, coords[2].y, coords[2].z),
            ],
            normal: Vector3::new(normal.x, normal.y, normal.z),
        }
    }
}

#[derive(Debug)]
pub struct Model {
    triangles: Vec<Triangle>,
    bbox: [Point3<f32>; 2],
}
impl Model {
    pub fn new() -> Model {
        Model {
            triangles: Vec::new(),
            bbox: [
                Point3::new(std::f32::MAX, std::f32::MAX, std::f32::MAX),
                Point3::new(std::f32::MIN, std::f32::MIN, std::f32::MIN),
            ],
        }
    }
    pub fn add_triangle(&mut self, triangle: Triangle) {
        // iterate through each coord and update bbox
        for i in 0..3 {
            let coords: nalgebra::OPoint<f32, nalgebra::Const<3>> = triangle.vertices[i];
            self.bbox[0].x = utils::pmin(self.bbox[0].x, coords.x - 1.);
            self.bbox[0].y = utils::pmin(self.bbox[0].y, coords.y - 1.);
            self.bbox[0].z = utils::pmin(self.bbox[0].z, coords.z - 1.);
            self.bbox[1].x = utils::pmax(self.bbox[1].x, coords.x + 1.);
            self.bbox[1].y = utils::pmax(self.bbox[1].y, coords.y + 1.);
            self.bbox[1].z = utils::pmax(self.bbox[1].z, coords.z + 1.);
        }
        //println!("triangle: {:?}", triangle.normal);
        self.triangles.push(triangle);
    }
    pub fn load_from_buffer(
        &mut self,
        buffer: *const f32,
        size: usize,
        offset: usize,
        vertex_size: usize,
    ) -> usize {
        let buffer: &[f32] = unsafe { std::slice::from_raw_parts(buffer, size) };
        println!(
            "size: {} offset: {} vertex_size: {}",
            size, offset, vertex_size
        );
        let mut i: usize = offset;
        let mut lul: usize = 0;
        while i < size {
            let v0: nalgebra::OPoint<f32, nalgebra::Const<3>> =
                Point3::new(buffer[i], buffer[i + 1], buffer[i + 2]);
            i += vertex_size;
            let v1: nalgebra::OPoint<f32, nalgebra::Const<3>> =
                Point3::new(buffer[i], buffer[i + 1], buffer[i + 2]);
            i += vertex_size;
            let v2: nalgebra::OPoint<f32, nalgebra::Const<3>> =
                Point3::new(buffer[i], buffer[i + 1], buffer[i + 2]);
            i += vertex_size;
            self.add_triangle(Triangle::new([v0, v1, v2]));
            lul += 1;
        }
        lul
    }
}

#[derive(Debug)]
enum Intersection {
    FrontFacing(Point3<f32>),
    BackFacing(Point3<f32>),
}

fn line_intersects_triangle(
    line_start: Point3<f32>,
    line_end: Point3<f32>,
    triangle: &Triangle,
) -> Option<Intersection> {
    let edge1: nalgebra::Matrix<
        f32,
        nalgebra::Const<3>,
        nalgebra::Const<1>,
        nalgebra::ArrayStorage<f32, 3, 1>,
    > = triangle.vertices[1] - triangle.vertices[0];
    let edge2: nalgebra::Matrix<
        f32,
        nalgebra::Const<3>,
        nalgebra::Const<1>,
        nalgebra::ArrayStorage<f32, 3, 1>,
    > = triangle.vertices[2] - triangle.vertices[0];
    let h: nalgebra::Matrix<
        f32,
        nalgebra::Const<3>,
        nalgebra::Const<1>,
        nalgebra::ArrayStorage<f32, 3, 1>,
    > = line_end - line_start;

    let p: nalgebra::Matrix<
        f32,
        nalgebra::Const<3>,
        nalgebra::Const<1>,
        nalgebra::ArrayStorage<f32, 3, 1>,
    > = h.cross(&edge2);
    let determinant = edge1.dot(&p);

    if determinant.abs() < 1e-6 {
        return None;
    }

    let inv_determinant: f32 = 1.0 / determinant;
    let s: nalgebra::Matrix<
        f32,
        nalgebra::Const<3>,
        nalgebra::Const<1>,
        nalgebra::ArrayStorage<f32, 3, 1>,
    > = line_start - triangle.vertices[0];
    let u: f32 = inv_determinant * s.dot(&p);

    if u < 0.0 || u > 1.0 {
        return None;
    }

    let q: nalgebra::Matrix<
        f32,
        nalgebra::Const<3>,
        nalgebra::Const<1>,
        nalgebra::ArrayStorage<f32, 3, 1>,
    > = s.cross(&edge1);
    let v: f32 = inv_determinant * h.dot(&q);

    if v < 0.0 || u + v > 1.0 {
        return None;
    }

    let t: f32 = inv_determinant * edge2.dot(&q);

    if t > 0.0 && t < 1.0 {
        let intersection_point: nalgebra::OPoint<f32, nalgebra::Const<3>> = line_start + t * h;
        if triangle.normal.dot(&h) > 0.0 {
            return Some(Intersection::BackFacing(intersection_point));
        } else {
            return Some(Intersection::FrontFacing(intersection_point));
        }
    }

    None
}

#[derive(Debug)]
struct Hit {
    index: i32,
    intersection: Intersection,
}
fn framebuffer_seed_model_scanlines(
    model: &Model,
    buffer: &mut [f32],
    xlen: i32,
    ylen: i32,
    zlen: i32,
) -> i32 {
    let mut i: usize = 0;
    let mut pos: nalgebra::OPoint<f32, nalgebra::Const<3>> = Point3::new(0., 0., 0.);
    let mut total: i32 = 0;
    let linelen: f32 = model.bbox[1].x - model.bbox[0].x;
    for z in 0..zlen + 0 {
        pos.z = utils::flerp(model.bbox[1].z, model.bbox[0].z, z as f32 / zlen as f32);
        for y in 0..ylen + 0 {
            pos.y = utils::flerp(model.bbox[1].y, model.bbox[0].y, y as f32 / ylen as f32);
            pos.x = model.bbox[0].x; //utils::flerp(model.bbox[0].x, model.bbox[1].x, -0.5 / xlen as f32);

            // scan this line for hits
            let mut hits: Vec<Hit> = Vec::new();

            for triangle in &model.triangles {
                let hit: Option<Intersection> =
                    line_intersects_triangle(pos, pos + Vector3::new(linelen, 0., 0.), &triangle);
                match hit {
                    Some(Intersection::FrontFacing(point))
                    | Some(Intersection::BackFacing(point)) => {
                        hits.push(Hit {
                            index: ((point.x - pos.x) / linelen * xlen as f32) as i32,
                            intersection: hit.unwrap(),
                        });
                    }
                    None => {
                        //
                    }
                }
            }

            // sort the hits by index
            hits.sort_by(|a: &Hit, b: &Hit| a.index.cmp(&b.index));
            // if hits.len() > 0 {
            // println!("hits: {:?}", hits);
            // }

            let mut scanstate: bool = false;
            let mut j: usize = 0;
            for x in 0..xlen + 0 {
                let mut scan: i32 = 0;
                for index in j..hits.len() {
                    let hit: &Hit = &hits[index];
                    if hit.index <= x {
                        match hit.intersection {
                            Intersection::FrontFacing(_) => {
                                scan += 1;
                                j += 1;
                            }
                            Intersection::BackFacing(_) => {
                                scan -= 1;
                                j += 1;
                            }
                        }
                    } else {
                        break;
                    }
                }

                if scanstate == true {
                    if scan < 0 {
                        scanstate = false;
                        // println!("outside at: [{}, {}, {}]", x, y, z);
                    }
                } else {
                    if scan > 0 {
                        scanstate = true;
                        // println!("inside at: [{}, {}, {}]", x, y, z);
                    }
                }

                if scanstate == true {
                    buffer[i] = x as f32;
                    buffer[i + 1] = y as f32;
                    buffer[i + 2] = z as f32;
                    buffer[i + 3] = 1.0;
                    total += 1;
                }
                i += 4;
            }
        }
    }
    total
}

// api
#[no_mangle]
pub extern "cdecl" fn seed_config(vertex_size: f64, vertex_offset: f64, winding: f64) -> () {
    let mut conf: globals::Config = globals::get_config();
    conf.vertex_size = vertex_size as usize;
    conf.vertex_offset = vertex_offset as usize;
    conf.winding = winding != 0.0;
    globals::set_config(conf);
}

#[no_mangle]
pub extern "cdecl" fn seed_result_json() -> *const c_char {
    let conf: globals::Config = globals::get_config();
    let xlen: usize = conf.seed_xlen;
    let ylen: usize = conf.seed_ylen;
    let zlen: usize = conf.seed_zlen;
    let bbox: [nalgebra::OPoint<f32, nalgebra::Const<3>>; 2] = conf.seed_bbox;
    let scale: nalgebra::OPoint<f32, nalgebra::Const<3>> = conf.seed_scale;
    let c_string: CString = CString::new(format!(
        r#"{{"xlen":{},"ylen":{},"zlen":{},"bbox":[[{}, {}, {}], [{}, {}, {}]],"scale":[{}, {}, {}]}}"#,
        xlen, ylen, zlen, bbox[0].x, bbox[0].y, bbox[0].z, bbox[1].x, bbox[1].y, bbox[1].z, scale.x, scale.y, scale.z
    ))
    .unwrap();
    let pointer: *mut i8 = c_string.into_raw();
    pointer
}

#[no_mangle]
pub extern "cdecl" fn seed_buffer(
    ptr: *const c_char,
    size: f64,
    ptr_target: *const c_char,
    tsize: f64,
) -> f64 {
    let c_str: &CStr = unsafe { CStr::from_ptr(ptr) };
    let hex_string: &str = c_str.to_str().unwrap();
    let rawhandle: i64 = i64::from_str_radix(hex_string, 16).unwrap();

    let mut model: Model = Model::new();

    let conf: globals::Config = globals::get_config();

    model.load_from_buffer(
        rawhandle as *const f32,
        size as usize,
        conf.vertex_offset as usize,
        conf.vertex_size as usize,
    );

    let discrete_x: i32 = (model.bbox[1].x - model.bbox[0].x) as i32;
    let discrete_y: i32 = (model.bbox[1].y - model.bbox[0].y) as i32;
    let discrete_z: i32 = (model.bbox[1].z - model.bbox[0].z) as i32;

    let max_alloc: f32 = (tsize * tsize) as f32;

    let total_voxels: i32 = discrete_x * discrete_y * discrete_z;
    let total_alloc: i32 = utils::pmin(total_voxels, max_alloc as i32);
    println!(
        "total_voxels: {}, total_alloc: {}",
        total_voxels, total_alloc
    );

    let compression_ratio: f32 = (max_alloc as f32 / total_voxels as f32).cbrt();

    let mut discrete_vec: nalgebra::Matrix<
        f32,
        nalgebra::Const<3>,
        nalgebra::Const<1>,
        nalgebra::ArrayStorage<f32, 3, 1>,
    > = Vector3::new(discrete_x as f32, discrete_y as f32, discrete_z as f32);
    let len: f32 = (discrete_vec.x * discrete_vec.x
        + discrete_vec.y * discrete_vec.y
        + discrete_vec.z * discrete_vec.z)
        .sqrt();
    discrete_vec = discrete_vec.normalize() * (compression_ratio * len);

    let xlen: i32 = (discrete_vec.x).floor() as i32;
    let ylen: i32 = (discrete_vec.y).floor() as i32;
    let zlen: i32 = (discrete_vec.z).floor() as i32;

    let c_str: &CStr = unsafe { CStr::from_ptr(ptr_target) };
    let hex_string: &str = c_str.to_str().unwrap();
    let target_ptr: *mut f32 = i64::from_str_radix(hex_string, 16).unwrap() as *mut f32;
    let buffer: &mut [f32] =
        unsafe { std::slice::from_raw_parts_mut(target_ptr, max_alloc as usize * 4) };

    let result: i32 = framebuffer_seed_model_scanlines(&model, buffer, xlen, ylen, zlen);

    let mut conf: globals::Config = globals::get_config();
    conf.seed_xlen = xlen as usize;
    conf.seed_ylen = ylen as usize;
    conf.seed_zlen = zlen as usize;
    conf.seed_bbox = model.bbox;
    conf.seed_scale = Point3::new(
        (model.bbox[1].x - model.bbox[0].x) / xlen as f32,
        (model.bbox[1].y - model.bbox[0].y) / ylen as f32,
        (model.bbox[1].z - model.bbox[0].z) / zlen as f32,
    );

    globals::set_config(conf);

    result as f64
}

mod tests {
    use super::*;

    #[test]
    fn test_seed_buffer() {
        let mut model: Model = Model::new();
        model.add_triangle(Triangle::new([
            Point3::new(0., 0., 0.),
            Point3::new(1., 0., 0.),
            Point3::new(0., 1., 0.),
        ]));
        model.add_triangle(Triangle::new([
            Point3::new(0., 0., 0.),
            Point3::new(0., 1., 0.),
            Point3::new(0., 0., 1.),
        ]));
        model.add_triangle(Triangle::new([
            Point3::new(0., 0., 0.),
            Point3::new(0., 0., 1.),
            Point3::new(1., 0., 0.),
        ]));
        model.add_triangle(Triangle::new([
            Point3::new(1., 0., 0.),
            Point3::new(0., 0., 1.),
            Point3::new(0., 1., 0.),
        ]));

        let mut buffer: [f32; 1000] = [0.; 1000];
        let result: i32 = framebuffer_seed_model_scanlines(&model, &mut buffer, 10, 10, 10);
        println!("result: {}", result);
        println!("buffer: {:?}", buffer);
    }
}
