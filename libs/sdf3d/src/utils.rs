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
pub fn flerp(a: f32, b: f32, t: f32) -> f32 {
    a + t * (b - a)
}
