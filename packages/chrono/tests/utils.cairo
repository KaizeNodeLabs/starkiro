use chrono::prelude::*;

pub fn ymd(y: u32, m: u32, d: u32) -> Date {
    DateTrait::from_ymd_opt(y, m, d).unwrap()
}

pub fn hms(h: u32, m: u32, s: u32) -> Time {
    TimeTrait::from_hms_opt(h, m, s).unwrap()
}

pub fn ymdhms(y: u32, m: u32, d: u32, h: u32, n: u32, s: u32) -> DateTime {
    ymd(y, m, d).and_hms_opt(h, n, s).unwrap()
}
