use core::num::traits::Bounded;
use datetime::{Days, DaysTrait};
use datetime::month::MonthsTrait;
use datetime::internals::{
    A, AG, B, BA, C, CB, D, DC, E, ED, F, FE, G, GF, YearFlags, YearFlagsTrait,
};
use datetime::date::{Date, DateTrait, MAX_YEAR, MIN_YEAR};

#[test]
fn diff_months() {
    // identity
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 8, 3).unwrap().checked_add_months(MonthsTrait::new(0)),
        Option::Some(DateTrait::from_ymd_opt(2022, 8, 3).unwrap()),
    );

    // add with months exceeding `i32::MAX`
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 8, 3)
            .unwrap()
            .checked_add_months(MonthsTrait::new(Bounded::<i32>::MAX.try_into().unwrap() + 1)),
        Option::None,
    );

    // sub with months exceeding `i32::MIN`
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 8, 3)
            .unwrap()
            .checked_sub_months(
                MonthsTrait::new((-(Bounded::<i32>::MIN + 1)).try_into().unwrap() + 1),
            ),
        Option::None,
    );

    // add overflowing year
    assert_eq!(DateTrait::MAX.checked_add_months(MonthsTrait::new(1)), Option::None);

    // add underflowing year
    assert_eq!(DateTrait::MIN.checked_sub_months(MonthsTrait::new(1)), Option::None);

    // sub crossing year 0 boundary
    // assert_eq!(
    //     NaiveDate::from_ymd_opt(2022, 8, 3).unwrap().checked_sub_months(Months::new(2050 * 12)),
    //     Some(NaiveDate::from_ymd_opt(-28, 8, 3).unwrap()),
    // );

    // add crossing year boundary
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 8, 3).unwrap().checked_add_months(MonthsTrait::new(6)),
        Option::Some(DateTrait::from_ymd_opt(2023, 2, 3).unwrap()),
    );

    // sub crossing year boundary
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 8, 3).unwrap().checked_sub_months(MonthsTrait::new(10)),
        Option::Some(DateTrait::from_ymd_opt(2021, 10, 3).unwrap()),
    );

    // add clamping day, non-leap year
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 1, 29).unwrap().checked_add_months(MonthsTrait::new(1)),
        Option::Some(DateTrait::from_ymd_opt(2022, 2, 28).unwrap()),
    );

    // add to leap day
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 10, 29).unwrap().checked_add_months(MonthsTrait::new(16)),
        Option::Some(DateTrait::from_ymd_opt(2024, 2, 29).unwrap()),
    );

    // add into december
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 10, 31).unwrap().checked_add_months(MonthsTrait::new(2)),
        Option::Some(DateTrait::from_ymd_opt(2022, 12, 31).unwrap()),
    );

    // sub into december
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 10, 31).unwrap().checked_sub_months(MonthsTrait::new(10)),
        Option::Some(DateTrait::from_ymd_opt(2021, 12, 31).unwrap()),
    );

    // add into january
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 8, 3).unwrap().checked_add_months(MonthsTrait::new(5)),
        Option::Some(DateTrait::from_ymd_opt(2023, 1, 3).unwrap()),
    );

    // sub into january
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 8, 3).unwrap().checked_sub_months(MonthsTrait::new(7)),
        Option::Some(DateTrait::from_ymd_opt(2022, 1, 3).unwrap()),
    );
}

#[test]
fn test_date_from_ymd() {
    assert!(DateTrait::from_ymd_opt(2012, 0, 1).is_none());
    assert!(DateTrait::from_ymd_opt(2012, 1, 1).is_some());
    assert!(DateTrait::from_ymd_opt(2012, 2, 29).is_some());
    assert!(DateTrait::from_ymd_opt(2014, 2, 29).is_none());
    assert!(DateTrait::from_ymd_opt(2014, 3, 0).is_none());
    assert!(DateTrait::from_ymd_opt(2014, 3, 1).is_some());
    assert!(DateTrait::from_ymd_opt(2014, 3, 31).is_some());
    assert!(DateTrait::from_ymd_opt(2014, 3, 32).is_none());
    assert!(DateTrait::from_ymd_opt(2014, 12, 31).is_some());
    assert!(DateTrait::from_ymd_opt(2014, 13, 1).is_none());
}

fn ymd(y: u32, m: u32, d: u32) -> Date {
    DateTrait::from_ymd_opt(y, m, d).unwrap()
}

const TWO_POW_28: u32 = 268435456;

#[test]
fn test_date_from_yo() {
    assert_eq!(DateTrait::from_yo_opt(2012, 0), Option::None);
    assert_eq!(DateTrait::from_yo_opt(2012, 1), Option::Some(ymd(2012, 1, 1)));
    assert_eq!(DateTrait::from_yo_opt(2012, 2), Option::Some(ymd(2012, 1, 2)));
    assert_eq!(DateTrait::from_yo_opt(2012, 32), Option::Some(ymd(2012, 2, 1)));
    assert_eq!(DateTrait::from_yo_opt(2012, 60), Option::Some(ymd(2012, 2, 29)));
    assert_eq!(DateTrait::from_yo_opt(2012, 61), Option::Some(ymd(2012, 3, 1)));
    assert_eq!(DateTrait::from_yo_opt(2012, 100), Option::Some(ymd(2012, 4, 9)));
    assert_eq!(DateTrait::from_yo_opt(2012, 200), Option::Some(ymd(2012, 7, 18)));
    assert_eq!(DateTrait::from_yo_opt(2012, 300), Option::Some(ymd(2012, 10, 26)));
    assert_eq!(DateTrait::from_yo_opt(2012, 366), Option::Some(ymd(2012, 12, 31)));
    assert_eq!(DateTrait::from_yo_opt(2012, 367), Option::None);
    assert_eq!(DateTrait::from_yo_opt(2012, (1 * TWO_POW_28) | 60), Option::None);

    assert_eq!(DateTrait::from_yo_opt(2014, 0), Option::None);
    assert_eq!(DateTrait::from_yo_opt(2014, 1), Option::Some(ymd(2014, 1, 1)));
    assert_eq!(DateTrait::from_yo_opt(2014, 2), Option::Some(ymd(2014, 1, 2)));
    assert_eq!(DateTrait::from_yo_opt(2014, 32), Option::Some(ymd(2014, 2, 1)));
    assert_eq!(DateTrait::from_yo_opt(2014, 59), Option::Some(ymd(2014, 2, 28)));
    assert_eq!(DateTrait::from_yo_opt(2014, 60), Option::Some(ymd(2014, 3, 1)));
    assert_eq!(DateTrait::from_yo_opt(2014, 100), Option::Some(ymd(2014, 4, 10)));
    assert_eq!(DateTrait::from_yo_opt(2014, 200), Option::Some(ymd(2014, 7, 19)));
    assert_eq!(DateTrait::from_yo_opt(2014, 300), Option::Some(ymd(2014, 10, 27)));
    assert_eq!(DateTrait::from_yo_opt(2014, 365), Option::Some(ymd(2014, 12, 31)));
    assert_eq!(DateTrait::from_yo_opt(2014, 366), Option::None);
}

fn check_date_fields(year: u32, month: u32, day: u32, ordinal: u32) {
    let d1 = DateTrait::from_ymd_opt(year, month, day).unwrap();
    assert_eq!(d1.year(), year);
    assert_eq!(d1.month(), month);
    assert_eq!(d1.day(), day);
    assert_eq!(d1.ordinal(), ordinal);

    let d2 = DateTrait::from_yo_opt(year, ordinal).unwrap();
    assert_eq!(d2.year(), year);
    assert_eq!(d2.month(), month);
    assert_eq!(d2.day(), day);
    assert_eq!(d2.ordinal(), ordinal);

    assert_eq!(d1, d2);
}

#[test]
fn test_date_fields() {
    check_date_fields(2012, 1, 1, 1);
    check_date_fields(2012, 1, 2, 2);
    check_date_fields(2012, 2, 1, 32);
    check_date_fields(2012, 2, 29, 60);
    check_date_fields(2012, 3, 1, 61);
    check_date_fields(2012, 4, 9, 100);
    check_date_fields(2012, 7, 18, 200);
    check_date_fields(2012, 10, 26, 300);
    check_date_fields(2012, 12, 31, 366);

    check_date_fields(2014, 1, 1, 1);
    check_date_fields(2014, 1, 2, 2);
    check_date_fields(2014, 2, 1, 32);
    check_date_fields(2014, 2, 28, 59);
    check_date_fields(2014, 3, 1, 60);
    check_date_fields(2014, 4, 10, 100);
    check_date_fields(2014, 7, 19, 200);
    check_date_fields(2014, 10, 27, 300);
    check_date_fields(2014, 12, 31, 365);
}

#[test]
fn test_date_with_fields() {
    let d = DateTrait::from_ymd_opt(2000, 2, 29).unwrap();
    // assert_eq!(d.with_year(-400), Some(NaiveDate::from_ymd_opt(-400, 2, 29).unwrap()));
    // assert_eq!(d.with_year(-100), None);
    assert_eq!(d.with_year(1600), Option::Some(DateTrait::from_ymd_opt(1600, 2, 29).unwrap()));
    assert_eq!(d.with_year(1900), Option::None);
    assert_eq!(d.with_year(2000), Option::Some(DateTrait::from_ymd_opt(2000, 2, 29).unwrap()));
    assert_eq!(d.with_year(2001), Option::None);
    assert_eq!(d.with_year(2004), Option::Some(DateTrait::from_ymd_opt(2004, 2, 29).unwrap()));
    assert_eq!(d.with_year(Bounded::<i32>::MAX.try_into().unwrap()), Option::None);

    let d = DateTrait::from_ymd_opt(2000, 4, 30).unwrap();
    assert_eq!(d.with_month(0), Option::None);
    assert_eq!(d.with_month(1), Option::Some(DateTrait::from_ymd_opt(2000, 1, 30).unwrap()));
    assert_eq!(d.with_month(2), Option::None);
    assert_eq!(d.with_month(3), Option::Some(DateTrait::from_ymd_opt(2000, 3, 30).unwrap()));
    assert_eq!(d.with_month(4), Option::Some(DateTrait::from_ymd_opt(2000, 4, 30).unwrap()));
    assert_eq!(d.with_month(12), Option::Some(DateTrait::from_ymd_opt(2000, 12, 30).unwrap()));
    assert_eq!(d.with_month(13), Option::None);
    assert_eq!(d.with_month(Bounded::<u32>::MAX), Option::None);

    let d = DateTrait::from_ymd_opt(2000, 2, 8).unwrap();
    assert_eq!(d.with_day(0), Option::None);
    assert_eq!(d.with_day(1), Option::Some(DateTrait::from_ymd_opt(2000, 2, 1).unwrap()));
    assert_eq!(d.with_day(29), Option::Some(DateTrait::from_ymd_opt(2000, 2, 29).unwrap()));
    assert_eq!(d.with_day(30), Option::None);
    assert_eq!(d.with_day(Bounded::<u32>::MAX), Option::None);
}

#[test]
fn test_date_with_ordinal() {
    let d = DateTrait::from_ymd_opt(2000, 5, 5).unwrap();
    assert_eq!(d.with_ordinal(0), Option::None);
    assert_eq!(d.with_ordinal(1), Option::Some(DateTrait::from_ymd_opt(2000, 1, 1).unwrap()));
    assert_eq!(d.with_ordinal(60), Option::Some(DateTrait::from_ymd_opt(2000, 2, 29).unwrap()));
    assert_eq!(d.with_ordinal(61), Option::Some(DateTrait::from_ymd_opt(2000, 3, 1).unwrap()));
    assert_eq!(d.with_ordinal(366), Option::Some(DateTrait::from_ymd_opt(2000, 12, 31).unwrap()));
    assert_eq!(d.with_ordinal(367), Option::None);
    assert_eq!(d.with_ordinal((1 * TWO_POW_28) | 60), Option::None);
    let d = DateTrait::from_ymd_opt(1999, 5, 5).unwrap();
    assert_eq!(d.with_ordinal(366), Option::None);
    assert_eq!(d.with_ordinal(Bounded::<u32>::MAX), Option::None);
}

#[test]
fn test_date_succ() {
    assert_eq!(ymd(2014, 5, 6).succ_opt(), Option::Some(ymd(2014, 5, 7)));
    assert_eq!(ymd(2014, 5, 31).succ_opt(), Option::Some(ymd(2014, 6, 1)));
    assert_eq!(ymd(2014, 12, 31).succ_opt(), Option::Some(ymd(2015, 1, 1)));
    assert_eq!(ymd(2016, 2, 28).succ_opt(), Option::Some(ymd(2016, 2, 29)));
    assert_eq!(ymd(DateTrait::MAX.year(), 12, 31).succ_opt(), Option::None);
}

#[test]
fn test_date_pred() {
    assert_eq!(ymd(2016, 3, 1).pred_opt(), Option::Some(ymd(2016, 2, 29)));
    assert_eq!(ymd(2015, 1, 1).pred_opt(), Option::Some(ymd(2014, 12, 31)));
    assert_eq!(ymd(2014, 6, 1).pred_opt(), Option::Some(ymd(2014, 5, 31)));
    assert_eq!(ymd(2014, 5, 7).pred_opt(), Option::Some(ymd(2014, 5, 6)));
    assert_eq!(ymd(DateTrait::MIN.year(), 1, 1).pred_opt(), Option::None);
}

fn check_date_add_days(lhs: Option<Date>, days: Days, rhs: Option<Date>) {
    assert_eq!(lhs.unwrap().checked_add_days(days), rhs);
}

#[test]
fn test_date_add_days() {
    check_date_add_days(
        DateTrait::from_ymd_opt(2014, 1, 1), DaysTrait::new(0), DateTrait::from_ymd_opt(2014, 1, 1),
    );
    // always round towards zero
    check_date_add_days(
        DateTrait::from_ymd_opt(2014, 1, 1), DaysTrait::new(1), DateTrait::from_ymd_opt(2014, 1, 2),
    );
    check_date_add_days(
        DateTrait::from_ymd_opt(2014, 1, 1),
        DaysTrait::new(364),
        DateTrait::from_ymd_opt(2014, 12, 31),
    );
    check_date_add_days(
        DateTrait::from_ymd_opt(2014, 1, 1),
        DaysTrait::new(365 * 4 + 1),
        DateTrait::from_ymd_opt(2018, 1, 1),
    );
    check_date_add_days(
        DateTrait::from_ymd_opt(2014, 1, 1),
        DaysTrait::new(365 * 400 + 97),
        DateTrait::from_ymd_opt(2414, 1, 1),
    );

    // check_date_add_days(
    //     DateTrait::from_ymd_opt(-7, 1, 1),
    //     DaysTrait::new(365 * 12 + 3),
    //     DateTrait::from_ymd_opt(5, 1, 1),
    // );

    // overflow check
    check_date_add_days(
        DateTrait::from_ymd_opt(0, 1, 1),
        DaysTrait::new(MAX_DAYS_FROM_YEAR_0.try_into().unwrap()),
        DateTrait::from_ymd_opt(MAX_YEAR, 12, 31),
    );
    check_date_add_days(
        DateTrait::from_ymd_opt(0, 1, 1),
        DaysTrait::new(MAX_DAYS_FROM_YEAR_0.try_into().unwrap() + 1),
        Option::None,
    );
}

fn check_date_sub_days(lhs: Option<Date>, days: Days, rhs: Option<Date>) {
    assert_eq!(lhs.unwrap().checked_sub_days(days), rhs);
}

#[test]
fn test_date_sub_days() {
    check_date_sub_days(
        DateTrait::from_ymd_opt(2014, 1, 1), DaysTrait::new(0), DateTrait::from_ymd_opt(2014, 1, 1),
    );
    check_date_sub_days(
        DateTrait::from_ymd_opt(2014, 1, 2), DaysTrait::new(1), DateTrait::from_ymd_opt(2014, 1, 1),
    );
    check_date_sub_days(
        DateTrait::from_ymd_opt(2014, 12, 31),
        DaysTrait::new(364),
        DateTrait::from_ymd_opt(2014, 1, 1),
    );
    check_date_sub_days(
        DateTrait::from_ymd_opt(2015, 1, 3),
        DaysTrait::new(365 + 2),
        DateTrait::from_ymd_opt(2014, 1, 1),
    );
    check_date_sub_days(
        DateTrait::from_ymd_opt(2018, 1, 1),
        DaysTrait::new(365 * 4 + 1),
        DateTrait::from_ymd_opt(2014, 1, 1),
    );
    check_date_sub_days(
        DateTrait::from_ymd_opt(2414, 1, 1),
        DaysTrait::new(365 * 400 + 97),
        DateTrait::from_ymd_opt(2014, 1, 1),
    );
    check_date_sub_days(
        DateTrait::from_ymd_opt(MAX_YEAR, 12, 31),
        DaysTrait::new(MAX_DAYS_FROM_YEAR_0.try_into().unwrap()),
        DateTrait::from_ymd_opt(0, 1, 1),
    );
    let min_days_from_year_0: i32 = MIN_DAYS_FROM_YEAR_0.try_into().unwrap();
    check_date_sub_days(
        DateTrait::from_ymd_opt(0, 1, 1),
        DaysTrait::new((-min_days_from_year_0).try_into().unwrap()),
        DateTrait::from_ymd_opt(MIN_YEAR, 1, 1),
    );
}


#[test]
fn test_date_fmt() {
    assert_eq!(format!("{:?}", DateTrait::from_ymd_opt(2012, 3, 4).unwrap()), "2012-03-04");
    assert_eq!(format!("{:?}", DateTrait::from_ymd_opt(0, 3, 4).unwrap()), "0000-03-04");
    // assert_eq!(format!("{:?}", DateTrait::from_ymd_opt(-307, 3, 4).unwrap()), "-0307-03-04");
    assert_eq!(format!("{:?}", DateTrait::from_ymd_opt(12345, 3, 4).unwrap()), "+12345-03-04");
    // assert_eq!(DateTrait::from_ymd_opt(2012, 3, 4).unwrap().to_string(), "2012-03-04");
// assert_eq!(DateTrait::from_ymd_opt(0, 3, 4).unwrap().to_string(), "0000-03-04");
// assert_eq!(DateTrait::from_ymd_opt(-307, 3, 4).unwrap().to_string(), "-0307-03-04");
// assert_eq!(DateTrait::from_ymd_opt(12345, 3, 4).unwrap().to_string(), "+12345-03-04");
// the format specifier should have no effect on `NaiveTime`
// assert_eq!(format!("{:+30?}", NaiveDate::from_ymd_opt(1234, 5, 6).unwrap()), "1234-05-06");
// assert_eq!(format!("{:30?}", NaiveDate::from_ymd_opt(12345, 6, 7).unwrap()), "+12345-06-07");
}


#[test]
fn test_leap_year() {
    for year in 0..MAX_YEAR + 1 {
        let date = DateTrait::from_ymd_opt(year, 1, 1).unwrap();
        let is_leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
        assert_eq!(date.leap_year(), is_leap);
        assert_eq!(date.leap_year(), date.with_ordinal(366).is_some());
    }
}

#[test]
fn test_date_yearflags() {
    for (year, year_flags) in YEAR_FLAGS.span() {
        assert_eq!(DateTrait::from_yo_opt(*year, 1).unwrap().year_flags(), *year_flags);
    }
}

#[test]
fn test_date_to_mdf_to_date() {
    for (year, year_flags) in YEAR_FLAGS.span() {
        for ordinal in 1..year_flags.ndays() {
            let date = DateTrait::from_yo_opt(*year, ordinal).unwrap();
            assert_eq!(date, DateTrait::from_mdf(date.year(), date.mdf()).unwrap());
        }
    }
}

// Used for testing some methods with all combinations of `YearFlags`.
// (year, flags, first weekday of year)
const YEAR_FLAGS: [(u32, YearFlags); 14] = [
    (2006, A), (2005, B), (2010, C), (2009, D), (2003, E), (2002, F), (2001, G), (2012, AG),
    (2000, BA), (2016, CB), (2004, DC), (2020, ED), (2008, FE), (2024, GF),
];

//   MAX_YEAR-12-31 minus 0000-01-01
// = (MAX_YEAR-12-31 minus 0000-12-31) + (0000-12-31 - 0000-01-01)
// = MAX_YEAR * 365 + (# of leap years from 0001 to MAX_YEAR) + 365
// = (MAX_YEAR + 1) * 365 + (# of leap years from 0001 to MAX_YEAR)
const MAX_DAYS_FROM_YEAR_0: u32 = (MAX_YEAR + 1) * 365
    + MAX_YEAR / 4
    - MAX_YEAR / 100
    + MAX_YEAR / 400;

//   MIN_YEAR-01-01 minus 0000-01-01
// = MIN_YEAR * 365 + (# of leap years from MIN_YEAR to 0000)
const MIN_DAYS_FROM_YEAR_0: u32 = MIN_YEAR * 365 + MIN_YEAR / 4 - MIN_YEAR / 100 + MIN_YEAR / 400;
