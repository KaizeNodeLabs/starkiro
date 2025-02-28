use core::num::traits::Bounded;
use datetime::internals::{
    YearFlags, YearFlagsTrait, A, AG, B, BA, C, CB, D, DC, E, ED, F, FE, G, GF, Mdf, MdfTrait,
    MDL_TO_OL,
};

#[test]
fn test_year_flags_ndays_from_year() {
    assert_eq!(YearFlagsTrait::from_year(2014).ndays(), 365);
    assert_eq!(YearFlagsTrait::from_year(2012).ndays(), 366);
    assert_eq!(YearFlagsTrait::from_year(2000).ndays(), 366);
    assert_eq!(YearFlagsTrait::from_year(1900).ndays(), 365);
    assert_eq!(YearFlagsTrait::from_year(1600).ndays(), 366);
    assert_eq!(YearFlagsTrait::from_year(1).ndays(), 365);
    assert_eq!(YearFlagsTrait::from_year(0).ndays(), 366); // 1 BCE (proleptic Gregorian)
    // assert_eq!(YearFlagsTrait::from_year(-1).ndays(), 365); // 2 BCE
// assert_eq!(YearFlagsTrait::from_year(-4).ndays(), 366); // 5 BCE
// assert_eq!(YearFlagsTrait::from_year(-99).ndays(), 365); // 100 BCE
// assert_eq!(YearFlagsTrait::from_year(-100).ndays(), 365); // 101 BCE
// assert_eq!(YearFlagsTrait::from_year(-399).ndays(), 365); // 400 BCE
// assert_eq!(YearFlagsTrait::from_year(-400).ndays(), 366); // 401 BCE
}

const NONLEAP_FLAGS: [YearFlags; 7] = [A, B, C, D, E, F, G];
const LEAP_FLAGS: [YearFlags; 7] = [AG, BA, CB, DC, ED, FE, GF];
const FLAGS: [YearFlags; 14] = [A, B, C, D, E, F, G, AG, BA, CB, DC, ED, FE, GF];

fn is_valid_mdf(mdf: Mdf) -> bool {
    *MDL_TO_OL.span()[mdf.mdf / 8] > 0
}

fn check_mdf_valid(
    expected: bool, flags: YearFlags, month1: u32, day1: u32, month2: u32, day2: u32,
) {
    for month in month1..month2 + 1 {
        //println!("month: {}", month);
        for day in day1..day2 + 1 {
            let mdf_opt = MdfTrait::new(month, day, flags);
            if mdf_opt.is_none() {
                if !expected {
                    continue;
                }
                panic!("Mdf::new({}, {}, {:?}) returned None", month, day, flags);
            }
            let mdf = mdf_opt.unwrap();

            assert!(
                is_valid_mdf(mdf) == expected,
                "month {} day {} = {:?} should be {} for dominical year {:?}",
                month,
                day,
                mdf,
                if expected {
                    'valid'
                } else {
                    'invalid'
                },
                flags,
            );
        };
    };
}

#[test]
fn test_mdf_valid() {
    for i in 0_usize..7 {
        let flags = *NONLEAP_FLAGS.span()[i];
        check_mdf_valid(false, flags, 0, 0, 0, 1024);
        check_mdf_valid(false, flags, 0, 0, 16, 0);
        check_mdf_valid(true, flags, 1, 1, 1, 31);
        check_mdf_valid(false, flags, 1, 32, 1, 1024);
        check_mdf_valid(true, flags, 2, 1, 2, 28);
        check_mdf_valid(false, flags, 2, 29, 2, 1024);
        check_mdf_valid(true, flags, 3, 1, 3, 31);
        check_mdf_valid(false, flags, 3, 32, 3, 1024);
        check_mdf_valid(true, flags, 4, 1, 4, 30);
        check_mdf_valid(false, flags, 4, 31, 4, 1024);
        check_mdf_valid(true, flags, 5, 1, 5, 31);
        check_mdf_valid(false, flags, 5, 32, 5, 1024);
        check_mdf_valid(true, flags, 6, 1, 6, 30);
        check_mdf_valid(false, flags, 6, 31, 6, 1024);
        check_mdf_valid(true, flags, 7, 1, 7, 31);
        check_mdf_valid(false, flags, 7, 32, 7, 1024);
        check_mdf_valid(true, flags, 8, 1, 8, 31);
        check_mdf_valid(false, flags, 8, 32, 8, 1024);
        check_mdf_valid(true, flags, 9, 1, 9, 30);
        check_mdf_valid(false, flags, 9, 31, 9, 1024);
        check_mdf_valid(true, flags, 10, 1, 10, 31);
        check_mdf_valid(false, flags, 10, 32, 10, 1024);
        check_mdf_valid(true, flags, 11, 1, 11, 30);
        check_mdf_valid(false, flags, 11, 31, 11, 1024);
        check_mdf_valid(true, flags, 12, 1, 12, 31);
        check_mdf_valid(false, flags, 12, 32, 12, 1024);
        check_mdf_valid(false, flags, 13, 0, 16, 1024);
        check_mdf_valid(false, flags, Bounded::<u32>::MAX - 1, 0, Bounded::<u32>::MAX - 1, 1024);
        check_mdf_valid(false, flags, 0, Bounded::<u32>::MAX - 1, 16, Bounded::<u32>::MAX - 1);
        check_mdf_valid(
            false,
            flags,
            Bounded::<u32>::MAX - 1,
            Bounded::<u32>::MAX - 1,
            Bounded::<u32>::MAX - 1,
            Bounded::<u32>::MAX - 1,
        );
    };
    for i in 0_usize..7 {
        let flags = *LEAP_FLAGS.span()[i];
        check_mdf_valid(false, flags, 0, 0, 0, 1024);
        check_mdf_valid(false, flags, 0, 0, 16, 0);
        check_mdf_valid(true, flags, 1, 1, 1, 31);
        check_mdf_valid(false, flags, 1, 32, 1, 1024);
        check_mdf_valid(true, flags, 2, 1, 2, 29);
        check_mdf_valid(false, flags, 2, 30, 2, 1024);
        check_mdf_valid(true, flags, 3, 1, 3, 31);
        check_mdf_valid(false, flags, 3, 32, 3, 1024);
        check_mdf_valid(true, flags, 4, 1, 4, 30);
        check_mdf_valid(false, flags, 4, 31, 4, 1024);
        check_mdf_valid(true, flags, 5, 1, 5, 31);
        check_mdf_valid(false, flags, 5, 32, 5, 1024);
        check_mdf_valid(true, flags, 6, 1, 6, 30);
        check_mdf_valid(false, flags, 6, 31, 6, 1024);
        check_mdf_valid(true, flags, 7, 1, 7, 31);
        check_mdf_valid(false, flags, 7, 32, 7, 1024);
        check_mdf_valid(true, flags, 8, 1, 8, 31);
        check_mdf_valid(false, flags, 8, 32, 8, 1024);
        check_mdf_valid(true, flags, 9, 1, 9, 30);
        check_mdf_valid(false, flags, 9, 31, 9, 1024);
        check_mdf_valid(true, flags, 10, 1, 10, 31);
        check_mdf_valid(false, flags, 10, 32, 10, 1024);
        check_mdf_valid(true, flags, 11, 1, 11, 30);
        check_mdf_valid(false, flags, 11, 31, 11, 1024);
        check_mdf_valid(true, flags, 12, 1, 12, 31);
        check_mdf_valid(false, flags, 12, 32, 12, 1024);
        check_mdf_valid(false, flags, 13, 0, 16, 1024);
        check_mdf_valid(false, flags, Bounded::<u32>::MAX - 1, 0, Bounded::<u32>::MAX - 1, 1024);
        check_mdf_valid(false, flags, 0, Bounded::<u32>::MAX - 1, 16, Bounded::<u32>::MAX - 1);
        check_mdf_valid(
            false,
            flags,
            Bounded::<u32>::MAX - 1,
            Bounded::<u32>::MAX - 1,
            Bounded::<u32>::MAX - 1,
            Bounded::<u32>::MAX - 1,
        );
    };
}

#[test]
fn test_mdf_fields() {
    for i in 0_usize..14 {
        let flags = *FLAGS.span()[i];
        for month in 1_usize..13 {
            for day in 1_usize..31 {
                let mdf_opt = MdfTrait::new(month, day, flags);
                if mdf_opt.is_none() {
                    continue;
                }
                let mdf = mdf_opt.unwrap();
                if is_valid_mdf(mdf) {
                    assert_eq!(mdf.month(), month);
                    assert_eq!(mdf.day(), day);
                }
            };
        };
    };
}

fn check_mdf_with_fields(flags: YearFlags, month: u32, day: u32) {
    let mdf = MdfTrait::new(month, day, flags).unwrap();
    for month in 0_usize..17 {
        let mdf_opt = mdf.with_month(month);
        if mdf_opt.is_none() {
            if month > 12 {
                continue;
            }
            panic!("failed to create Mdf with month {}", month);
        }
        let mdf = mdf_opt.unwrap();

        if is_valid_mdf(mdf) {
            assert_eq!(mdf.month(), month);
            assert_eq!(mdf.day(), day);
        }
    };
    for day in 0_usize..1025 {
        let mdf_opt = mdf.with_day(day);
        if mdf_opt.is_none() {
            if day > 31 {
                continue;
            }
            // TODO panic!("failed to create Mdf with month {}", month),
            panic!("failed to create Mdf with day {}", day);
        }
        let mdf = mdf_opt.unwrap();

        if is_valid_mdf(mdf) {
            assert_eq!(mdf.month(), month);
            assert_eq!(mdf.day(), day);
        }
    };
}

#[test]
fn test_mdf_with_fields() {
    for i in 0_usize..7 {
        let flags = *NONLEAP_FLAGS.span()[i];
        check_mdf_with_fields(flags, 1, 1);
        check_mdf_with_fields(flags, 1, 31);
        check_mdf_with_fields(flags, 2, 1);
        check_mdf_with_fields(flags, 2, 28);
        check_mdf_with_fields(flags, 2, 29);
        check_mdf_with_fields(flags, 12, 31);
    };
    for i in 0_usize..7 {
        let flags = *LEAP_FLAGS.span()[i];
        check_mdf_with_fields(flags, 1, 1);
        check_mdf_with_fields(flags, 1, 31);
        check_mdf_with_fields(flags, 2, 1);
        check_mdf_with_fields(flags, 2, 29);
        check_mdf_with_fields(flags, 2, 30);
        check_mdf_with_fields(flags, 12, 31);
    };
}

#[test]
fn test_mdf_new_range() {
    let flags = YearFlagsTrait::from_year(2023);
    assert!(MdfTrait::new(13, 1, flags).is_none());
    assert!(MdfTrait::new(1, 32, flags).is_none());
}
