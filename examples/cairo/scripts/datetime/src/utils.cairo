use core::num::traits::zero::Zero;
use core::num::traits::{CheckedSub, Pow};

const TWO_POW_0: u32 = 2_u32.pow(0);
const TWO_POW_1: u32 = 2_u32.pow(1);
const TWO_POW_2: u32 = 2_u32.pow(2);
const TWO_POW_3: u32 = 2_u32.pow(3);
const TWO_POW_4: u32 = 2_u32.pow(4);
const TWO_POW_5: u32 = 2_u32.pow(5);
const TWO_POW_6: u32 = 2_u32.pow(6);
const TWO_POW_7: u32 = 2_u32.pow(7);
const TWO_POW_8: u32 = 2_u32.pow(8);
const TWO_POW_9: u32 = 2_u32.pow(9);
const TWO_POW_10: u32 = 2_u32.pow(10);
const TWO_POW_11: u32 = 2_u32.pow(11);
const TWO_POW_12: u32 = 2_u32.pow(12);
const TWO_POW_13: u32 = 2_u32.pow(13);
const TWO_POW_14: u32 = 2_u32.pow(14);
const TWO_POW_15: u32 = 2_u32.pow(15);

fn shift_to_power_of_2(shift: u8) -> u32 {
    match shift {
        0 => TWO_POW_0,
        1 => TWO_POW_1,
        2 => TWO_POW_2,
        3 => TWO_POW_3,
        4 => TWO_POW_4,
        5 => TWO_POW_5,
        6 => TWO_POW_6,
        7 => TWO_POW_7,
        8 => TWO_POW_8,
        9 => TWO_POW_9,
        10 => TWO_POW_10,
        11 => TWO_POW_11,
        12 => TWO_POW_12,
        13 => TWO_POW_13,
        14 => TWO_POW_14,
        15 => TWO_POW_15,
        _ => 0,
    }
}

pub fn ushl(val: u32, shift: u8) -> u32 {
    val * shift_to_power_of_2(shift)
}

pub fn ushr(val: u32, shift: u8) -> u32 {
    val / shift_to_power_of_2(shift)
}

pub fn shl(val: i32, shift: u8) -> i32 {
    val * shift_to_power_of_2(shift).try_into().unwrap()
}

pub fn shr(val: i32, shift: u8) -> i32 {
    val / shift_to_power_of_2(shift).try_into().unwrap()
}

pub fn abs<T, +PartialOrd<T>, +Neg<T>, +Zero<T>, +Copy<T>, +Drop<T>>(n: T) -> T {
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
