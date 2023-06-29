#[inline]
pub fn pmin<T: PartialOrd>(a: T, b: T) -> T {
    if a < b {
        a
    } else {
        b
    }
}
#[inline]
pub fn pmax<T: PartialOrd>(a: T, b: T) -> T {
    if a > b {
        a
    } else {
        b
    }
}
#[inline]
pub fn pclamp<T: PartialOrd>(a: T, min: T, max: T) -> T {
    if a < min {
        min
    } else if a > max {
        max
    } else {
        a
    }
}
#[inline]
pub fn flerp(a: f32, b: f32, t: f32) -> f32 {
    a + t * (b - a)
}
