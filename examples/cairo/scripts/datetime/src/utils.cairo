pub const TWO_POW_1: u32 = 2;
pub const TWO_POW_3: u32 = 8;
pub const TWO_POW_4: u32 = 16;
pub const TWO_POW_6: u32 = 64;
pub const TWO_POW_9: u32 = 512;
pub const TWO_POW_13: u32 = 8192;

fn abs(n: i32) -> i32 {
    if n < 0 {
        -n
    } else {
        n
    }
}

pub fn rem_euclid(val: i32, div: i32) -> i32 {
    let val_mod_div = val % div;
    if val_mod_div < 0 {
        val_mod_div + abs(div)
    } else {
        val_mod_div
    }
}

pub fn div_euclid(val: i32, div: i32) -> i32 {
    let r = rem_euclid(val, div);
    (val - r) / div
}
