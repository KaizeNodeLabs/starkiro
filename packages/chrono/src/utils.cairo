use core::num::traits::zero::Zero;
use core::num::traits::{CheckedSub, Pow};

#[inline]
const fn u32_shift_to_power_of_2(shift: u8) -> u32 {
    match shift {
        0 => 2_u32.pow(0),
        1 => 2_u32.pow(1),
        2 => 2_u32.pow(2),
        3 => 2_u32.pow(3),
        4 => 2_u32.pow(4),
        5 => 2_u32.pow(5),
        6 => 2_u32.pow(6),
        7 => 2_u32.pow(7),
        8 => 2_u32.pow(8),
        9 => 2_u32.pow(9),
        10 => 2_u32.pow(10),
        11 => 2_u32.pow(11),
        12 => 2_u32.pow(12),
        13 => 2_u32.pow(13),
        14 => 2_u32.pow(14),
        15 => 2_u32.pow(15),
        16 => 2_u32.pow(16),
        17 => 2_u32.pow(17),
        18 => 2_u32.pow(18),
        19 => 2_u32.pow(19),
        20 => 2_u32.pow(20),
        21 => 2_u32.pow(21),
        22 => 2_u32.pow(22),
        23 => 2_u32.pow(23),
        24 => 2_u32.pow(24),
        25 => 2_u32.pow(25),
        26 => 2_u32.pow(26),
        27 => 2_u32.pow(27),
        28 => 2_u32.pow(28),
        29 => 2_u32.pow(29),
        30 => 2_u32.pow(30),
        31 => 2_u32.pow(31),
        _ => 0_u32,
    }
}

#[inline]
pub(crate) const fn u32_shl(val: u32, shift: u8) -> u32 {
    val * u32_shift_to_power_of_2(shift)
}

#[inline]
pub(crate) const fn u32_shr(val: u32, shift: u8) -> u32 {
    val / u32_shift_to_power_of_2(shift)
}

#[inline]
pub(crate) const fn shl(val: i32, shift: u8) -> i32 {
    val * u32_shift_to_power_of_2(shift).try_into().unwrap()
}

#[inline]
pub(crate) const fn shr(val: i32, shift: u8) -> i32 {
    val / u32_shift_to_power_of_2(shift).try_into().unwrap()
}

pub(crate) fn abs<T, +PartialOrd<T>, +Neg<T>, +Zero<T>, +Copy<T>, +Drop<T>>(n: T) -> T {
    if n < Zero::<T>::zero() {
        -n
    } else {
        n
    }
}

pub fn rem_euclid<T, +Rem<T>, +Add<T>, +PartialOrd<T>, +Neg<T>, +Zero<T>, +Copy<T>, +Drop<T>>(
    val: T, div: T,
) -> T {
    let val_mod_div = val % div;
    if val_mod_div < Zero::<T>::zero() {
        val_mod_div + abs(div)
    } else {
        val_mod_div
    }
}

pub fn div_euclid<
    T,
    +CheckedSub<T>,
    +Div<T>,
    +Rem<T>,
    +Add<T>,
    +PartialOrd<T>,
    +Neg<T>,
    +Zero<T>,
    +Copy<T>,
    +Drop<T>,
>(
    val: T, div: T,
) -> Option<T> {
    let r = rem_euclid(val, div);
    Some((val.checked_sub(r)?) / div)
}
