use core::num::traits::{Bounded, Pow};
use datetime::date::{Date, DateTrait, MAX_YEAR, MIN_YEAR};
use datetime::internals::{
    A, AG, B, BA, C, CB, D, DC, E, ED, F, FE, G, GF, YearFlags, YearFlagsTrait,
};
use datetime::month::MonthsTrait;
use datetime::time_delta::{TimeDelta, TimeDeltaTrait};
use datetime::weekday::{Weekday, WeekdayTrait};
use datetime::{Days, DaysTrait};

// as it is hard to verify year flags in `NaiveDate::MIN` and `NaiveDate::MAX`,
// we use a separate run-time test.
#[test]
fn test_date_bounds() {
    let calculated_min = DateTrait::from_ymd_opt(MIN_YEAR, 1, 1).unwrap();
    let calculated_max = DateTrait::from_ymd_opt(MAX_YEAR, 12, 31).unwrap();
    assert_eq!(DateTrait::MIN, calculated_min);
    assert_eq!(DateTrait::MAX, calculated_max);

    // let's also check that the entire range do not exceed 2^44 seconds
    // (sometimes used for bounding `TimeDelta` against overflow)
    let maxsecs = DateTrait::MAX.signed_duration_since(DateTrait::MIN).num_seconds();
    let maxsecs = maxsecs + 86401; // also take care of DateTime
    assert_lt!(maxsecs, 2_i64.pow(44));
    // const BEFORE_MIN: Date = DateTrait::BEFORE_MIN;
    // assert_eq!(BEFORE_MIN.year_flags(), YearFlagsTrait::from_year(BEFORE_MIN.year()));
    // assert_eq!((BEFORE_MIN.month(), BEFORE_MIN.day()), (12, 31));

    const AFTER_MAX: Date = DateTrait::AFTER_MAX;
    assert_eq!(
        AFTER_MAX.year_flags(), YearFlagsTrait::from_year(AFTER_MAX.year().try_into().unwrap()),
    );
    assert_eq!((AFTER_MAX.month(), AFTER_MAX.day()), (1, 1));
}

#[test]
fn diff_months() {
    // identity
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 8, 3).unwrap().checked_add_months(MonthsTrait::new(0)),
        Some(DateTrait::from_ymd_opt(2022, 8, 3).unwrap()),
    );

    // add with months exceeding `i32::MAX`
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 8, 3)
            .unwrap()
            .checked_add_months(MonthsTrait::new(Bounded::<i32>::MAX.try_into().unwrap() + 1)),
        None,
    );

    // sub with months exceeding `i32::MIN`
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 8, 3)
            .unwrap()
            .checked_sub_months(
                MonthsTrait::new((-(Bounded::<i32>::MIN + 1)).try_into().unwrap() + 1),
            ),
        None,
    );

    // add overflowing year
    assert_eq!(DateTrait::MAX.checked_add_months(MonthsTrait::new(1)), None);

    // add underflowing year
    assert_eq!(DateTrait::MIN.checked_sub_months(MonthsTrait::new(1)), None);

    // sub crossing year 0 boundary
    // assert_eq!(
    //     NaiveDate::from_ymd_opt(2022, 8, 3).unwrap().checked_sub_months(Months::new(2050 * 12)),
    //     Some(NaiveDate::from_ymd_opt(-28, 8, 3).unwrap()),
    // );

    // add crossing year boundary
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 8, 3).unwrap().checked_add_months(MonthsTrait::new(6)),
        Some(DateTrait::from_ymd_opt(2023, 2, 3).unwrap()),
    );

    // sub crossing year boundary
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 8, 3).unwrap().checked_sub_months(MonthsTrait::new(10)),
        Some(DateTrait::from_ymd_opt(2021, 10, 3).unwrap()),
    );

    // add clamping day, non-leap year
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 1, 29).unwrap().checked_add_months(MonthsTrait::new(1)),
        Some(DateTrait::from_ymd_opt(2022, 2, 28).unwrap()),
    );

    // add to leap day
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 10, 29).unwrap().checked_add_months(MonthsTrait::new(16)),
        Some(DateTrait::from_ymd_opt(2024, 2, 29).unwrap()),
    );

    // add into december
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 10, 31).unwrap().checked_add_months(MonthsTrait::new(2)),
        Some(DateTrait::from_ymd_opt(2022, 12, 31).unwrap()),
    );

    // sub into december
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 10, 31).unwrap().checked_sub_months(MonthsTrait::new(10)),
        Some(DateTrait::from_ymd_opt(2021, 12, 31).unwrap()),
    );

    // add into january
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 8, 3).unwrap().checked_add_months(MonthsTrait::new(5)),
        Some(DateTrait::from_ymd_opt(2023, 1, 3).unwrap()),
    );

    // sub into january
    assert_eq!(
        DateTrait::from_ymd_opt(2022, 8, 3).unwrap().checked_sub_months(MonthsTrait::new(7)),
        Some(DateTrait::from_ymd_opt(2022, 1, 3).unwrap()),
    );
}

#[test]
fn test_readme_doomsday() {
    // for y in MIN_YEAR..MAX_YEAR + 1 {
    for y in MIN_YEAR..1000 + 1 {
        // even months
        let d4 = DateTrait::from_ymd_opt(y, 4, 4).unwrap();
        let d6 = DateTrait::from_ymd_opt(y, 6, 6).unwrap();
        let d8 = DateTrait::from_ymd_opt(y, 8, 8).unwrap();
        let d10 = DateTrait::from_ymd_opt(y, 10, 10).unwrap();
        let d12 = DateTrait::from_ymd_opt(y, 12, 12).unwrap();

        // nine to five, seven-eleven
        let d59 = DateTrait::from_ymd_opt(y, 5, 9).unwrap();
        let d95 = DateTrait::from_ymd_opt(y, 9, 5).unwrap();
        let d711 = DateTrait::from_ymd_opt(y, 7, 11).unwrap();
        let d117 = DateTrait::from_ymd_opt(y, 11, 7).unwrap();

        // "March 0"
        let d30 = DateTrait::from_ymd_opt(y, 3, 1).unwrap().pred_opt().unwrap();

        let weekday = d30.weekday();
        let other_dates = [d4, d6, d8, d10, d12, d59, d95, d711, d117];
        for d in other_dates.span() {
            assert_eq!((*d).weekday(), weekday);
        }
    }
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

#[test]
fn test_date_from_yo() {
    assert_eq!(DateTrait::from_yo_opt(2012, 0), None);
    assert_eq!(DateTrait::from_yo_opt(2012, 1), Some(ymd(2012, 1, 1)));
    assert_eq!(DateTrait::from_yo_opt(2012, 2), Some(ymd(2012, 1, 2)));
    assert_eq!(DateTrait::from_yo_opt(2012, 32), Some(ymd(2012, 2, 1)));
    assert_eq!(DateTrait::from_yo_opt(2012, 60), Some(ymd(2012, 2, 29)));
    assert_eq!(DateTrait::from_yo_opt(2012, 61), Some(ymd(2012, 3, 1)));
    assert_eq!(DateTrait::from_yo_opt(2012, 100), Some(ymd(2012, 4, 9)));
    assert_eq!(DateTrait::from_yo_opt(2012, 200), Some(ymd(2012, 7, 18)));
    assert_eq!(DateTrait::from_yo_opt(2012, 300), Some(ymd(2012, 10, 26)));
    assert_eq!(DateTrait::from_yo_opt(2012, 366), Some(ymd(2012, 12, 31)));
    assert_eq!(DateTrait::from_yo_opt(2012, 367), None);
    assert_eq!(DateTrait::from_yo_opt(2012, 2_u32.pow(28) | 60), None);

    assert_eq!(DateTrait::from_yo_opt(2014, 0), None);
    assert_eq!(DateTrait::from_yo_opt(2014, 1), Some(ymd(2014, 1, 1)));
    assert_eq!(DateTrait::from_yo_opt(2014, 2), Some(ymd(2014, 1, 2)));
    assert_eq!(DateTrait::from_yo_opt(2014, 32), Some(ymd(2014, 2, 1)));
    assert_eq!(DateTrait::from_yo_opt(2014, 59), Some(ymd(2014, 2, 28)));
    assert_eq!(DateTrait::from_yo_opt(2014, 60), Some(ymd(2014, 3, 1)));
    assert_eq!(DateTrait::from_yo_opt(2014, 100), Some(ymd(2014, 4, 10)));
    assert_eq!(DateTrait::from_yo_opt(2014, 200), Some(ymd(2014, 7, 19)));
    assert_eq!(DateTrait::from_yo_opt(2014, 300), Some(ymd(2014, 10, 27)));
    assert_eq!(DateTrait::from_yo_opt(2014, 365), Some(ymd(2014, 12, 31)));
    assert_eq!(DateTrait::from_yo_opt(2014, 366), None);
}

#[test]
fn test_date_from_isoywd() {
    assert_eq!(DateTrait::from_isoywd_opt(2004, 0, Weekday::Sun), None);
    assert_eq!(DateTrait::from_isoywd_opt(2004, 1, Weekday::Mon), Some(ymd(2003, 12, 29)));
    assert_eq!(DateTrait::from_isoywd_opt(2004, 1, Weekday::Sun), Some(ymd(2004, 1, 4)));
    assert_eq!(DateTrait::from_isoywd_opt(2004, 2, Weekday::Mon), Some(ymd(2004, 1, 5)));
    assert_eq!(DateTrait::from_isoywd_opt(2004, 2, Weekday::Sun), Some(ymd(2004, 1, 11)));
    assert_eq!(DateTrait::from_isoywd_opt(2004, 52, Weekday::Mon), Some(ymd(2004, 12, 20)));
    assert_eq!(DateTrait::from_isoywd_opt(2004, 52, Weekday::Sun), Some(ymd(2004, 12, 26)));
    assert_eq!(DateTrait::from_isoywd_opt(2004, 53, Weekday::Mon), Some(ymd(2004, 12, 27)));
    assert_eq!(DateTrait::from_isoywd_opt(2004, 53, Weekday::Sun), Some(ymd(2005, 1, 2)));
    assert_eq!(DateTrait::from_isoywd_opt(2004, 54, Weekday::Mon), None);

    assert_eq!(DateTrait::from_isoywd_opt(2011, 0, Weekday::Sun), None);
    assert_eq!(DateTrait::from_isoywd_opt(2011, 1, Weekday::Mon), Some(ymd(2011, 1, 3)));
    assert_eq!(DateTrait::from_isoywd_opt(2011, 1, Weekday::Sun), Some(ymd(2011, 1, 9)));
    assert_eq!(DateTrait::from_isoywd_opt(2011, 2, Weekday::Mon), Some(ymd(2011, 1, 10)));
    assert_eq!(DateTrait::from_isoywd_opt(2011, 2, Weekday::Sun), Some(ymd(2011, 1, 16)));

    assert_eq!(DateTrait::from_isoywd_opt(2018, 51, Weekday::Mon), Some(ymd(2018, 12, 17)));
    assert_eq!(DateTrait::from_isoywd_opt(2018, 51, Weekday::Sun), Some(ymd(2018, 12, 23)));
    assert_eq!(DateTrait::from_isoywd_opt(2018, 52, Weekday::Mon), Some(ymd(2018, 12, 24)));
    assert_eq!(DateTrait::from_isoywd_opt(2018, 52, Weekday::Sun), Some(ymd(2018, 12, 30)));
    assert_eq!(DateTrait::from_isoywd_opt(2018, 53, Weekday::Mon), None);
}

#[test]
fn test_date_from_num_days_from_ce() {
    assert_eq!(DateTrait::from_num_days_from_ce_opt(1), Some(ymd(1, 1, 1)));
    assert_eq!(DateTrait::from_num_days_from_ce_opt(2), Some(ymd(1, 1, 2)));
    assert_eq!(DateTrait::from_num_days_from_ce_opt(31), Some(ymd(1, 1, 31)));
    assert_eq!(DateTrait::from_num_days_from_ce_opt(32), Some(ymd(1, 2, 1)));
    assert_eq!(DateTrait::from_num_days_from_ce_opt(59), Some(ymd(1, 2, 28)));
    assert_eq!(DateTrait::from_num_days_from_ce_opt(60), Some(ymd(1, 3, 1)));
    assert_eq!(DateTrait::from_num_days_from_ce_opt(365), Some(ymd(1, 12, 31)));
    assert_eq!(DateTrait::from_num_days_from_ce_opt(365 + 1), Some(ymd(2, 1, 1)));
    assert_eq!(DateTrait::from_num_days_from_ce_opt(365 * 2 + 1), Some(ymd(3, 1, 1)));
    assert_eq!(DateTrait::from_num_days_from_ce_opt(365 * 3 + 1), Some(ymd(4, 1, 1)));
    assert_eq!(DateTrait::from_num_days_from_ce_opt(365 * 4 + 2), Some(ymd(5, 1, 1)));
    assert_eq!(DateTrait::from_num_days_from_ce_opt(146097 + 1), Some(ymd(401, 1, 1)));
    assert_eq!(DateTrait::from_num_days_from_ce_opt(146097 * 5 + 1), Some(ymd(2001, 1, 1)));
    assert_eq!(DateTrait::from_num_days_from_ce_opt(719163), Some(ymd(1970, 1, 1)));
    assert_eq!(DateTrait::from_num_days_from_ce_opt(0), Some(ymd(0, 12, 31))); // 1 BCE
    assert_eq!(DateTrait::from_num_days_from_ce_opt(-365), Some(ymd(0, 1, 1)));
    //assert_eq!(from_ndays_from_ce(-366), Some(ymd(-1, 12, 31))); // 2 BCE

    for i in -3_i32..10001 {
        let days = i * 100;
        assert_eq!(
            DateTrait::from_num_days_from_ce_opt(days).map(|d: Date| d.num_days_from_ce()),
            Some(days),
        );
    }

    assert_eq!(
        DateTrait::from_num_days_from_ce_opt(DateTrait::MIN.num_days_from_ce()),
        Some(DateTrait::MIN),
    );
    assert_eq!(DateTrait::from_num_days_from_ce_opt(DateTrait::MIN.num_days_from_ce() - 1), None);
    assert_eq!(
        DateTrait::from_num_days_from_ce_opt(DateTrait::MAX.num_days_from_ce()),
        Some(DateTrait::MAX),
    );
    assert_eq!(DateTrait::from_num_days_from_ce_opt(DateTrait::MAX.num_days_from_ce() + 1), None);
    assert_eq!(DateTrait::from_num_days_from_ce_opt(Bounded::<i32>::MIN), None);
    assert_eq!(DateTrait::from_num_days_from_ce_opt(Bounded::<i32>::MAX), None);
}

#[test]
fn test_date_from_weekday_of_month_opt() {
    assert_eq!(DateTrait::from_weekday_of_month_opt(2018, 8, Weekday::Tue, 0), None);
    assert_eq!(
        DateTrait::from_weekday_of_month_opt(2018, 8, Weekday::Wed, 1), Some(ymd(2018, 8, 1)),
    );
    assert_eq!(
        DateTrait::from_weekday_of_month_opt(2018, 8, Weekday::Thu, 1), Some(ymd(2018, 8, 2)),
    );
    assert_eq!(
        DateTrait::from_weekday_of_month_opt(2018, 8, Weekday::Sun, 1), Some(ymd(2018, 8, 5)),
    );
    assert_eq!(
        DateTrait::from_weekday_of_month_opt(2018, 8, Weekday::Mon, 1), Some(ymd(2018, 8, 6)),
    );
    assert_eq!(
        DateTrait::from_weekday_of_month_opt(2018, 8, Weekday::Tue, 1), Some(ymd(2018, 8, 7)),
    );
    assert_eq!(
        DateTrait::from_weekday_of_month_opt(2018, 8, Weekday::Wed, 2), Some(ymd(2018, 8, 8)),
    );
    assert_eq!(
        DateTrait::from_weekday_of_month_opt(2018, 8, Weekday::Sun, 2), Some(ymd(2018, 8, 12)),
    );
    assert_eq!(
        DateTrait::from_weekday_of_month_opt(2018, 8, Weekday::Thu, 3), Some(ymd(2018, 8, 16)),
    );
    assert_eq!(
        DateTrait::from_weekday_of_month_opt(2018, 8, Weekday::Thu, 4), Some(ymd(2018, 8, 23)),
    );
    assert_eq!(
        DateTrait::from_weekday_of_month_opt(2018, 8, Weekday::Thu, 5), Some(ymd(2018, 8, 30)),
    );
    assert_eq!(
        DateTrait::from_weekday_of_month_opt(2018, 8, Weekday::Fri, 5), Some(ymd(2018, 8, 31)),
    );
    assert_eq!(DateTrait::from_weekday_of_month_opt(2018, 8, Weekday::Sat, 5), None);
}

#[test]
fn test_date_weekday() {
    assert_eq!(ymd(1582, 10, 15).weekday(), Weekday::Fri);
    // May 20, 1875 = ISO 8601 reference date
    assert_eq!(ymd(1875, 5, 20).weekday(), Weekday::Thu);
    assert_eq!(ymd(2000, 1, 1).weekday(), Weekday::Sat);
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
    assert_eq!(d.with_year(1600), Some(DateTrait::from_ymd_opt(1600, 2, 29).unwrap()));
    assert_eq!(d.with_year(1900), None);
    assert_eq!(d.with_year(2000), Some(DateTrait::from_ymd_opt(2000, 2, 29).unwrap()));
    assert_eq!(d.with_year(2001), None);
    assert_eq!(d.with_year(2004), Some(DateTrait::from_ymd_opt(2004, 2, 29).unwrap()));
    assert_eq!(d.with_year(Bounded::<i32>::MAX.try_into().unwrap()), None);

    let d = DateTrait::from_ymd_opt(2000, 4, 30).unwrap();
    assert_eq!(d.with_month(0), None);
    assert_eq!(d.with_month(1), Some(DateTrait::from_ymd_opt(2000, 1, 30).unwrap()));
    assert_eq!(d.with_month(2), None);
    assert_eq!(d.with_month(3), Some(DateTrait::from_ymd_opt(2000, 3, 30).unwrap()));
    assert_eq!(d.with_month(4), Some(DateTrait::from_ymd_opt(2000, 4, 30).unwrap()));
    assert_eq!(d.with_month(12), Some(DateTrait::from_ymd_opt(2000, 12, 30).unwrap()));
    assert_eq!(d.with_month(13), None);
    assert_eq!(d.with_month(Bounded::<u32>::MAX), None);

    let d = DateTrait::from_ymd_opt(2000, 2, 8).unwrap();
    assert_eq!(d.with_day(0), None);
    assert_eq!(d.with_day(1), Some(DateTrait::from_ymd_opt(2000, 2, 1).unwrap()));
    assert_eq!(d.with_day(29), Some(DateTrait::from_ymd_opt(2000, 2, 29).unwrap()));
    assert_eq!(d.with_day(30), None);
    assert_eq!(d.with_day(Bounded::<u32>::MAX), None);
}

#[test]
fn test_date_with_ordinal() {
    let d = DateTrait::from_ymd_opt(2000, 5, 5).unwrap();
    assert_eq!(d.with_ordinal(0), None);
    assert_eq!(d.with_ordinal(1), Some(DateTrait::from_ymd_opt(2000, 1, 1).unwrap()));
    assert_eq!(d.with_ordinal(60), Some(DateTrait::from_ymd_opt(2000, 2, 29).unwrap()));
    assert_eq!(d.with_ordinal(61), Some(DateTrait::from_ymd_opt(2000, 3, 1).unwrap()));
    assert_eq!(d.with_ordinal(366), Some(DateTrait::from_ymd_opt(2000, 12, 31).unwrap()));
    assert_eq!(d.with_ordinal(367), None);
    assert_eq!(d.with_ordinal(2_u32.pow(28) | 60), None);
    let d = DateTrait::from_ymd_opt(1999, 5, 5).unwrap();
    assert_eq!(d.with_ordinal(366), None);
    assert_eq!(d.with_ordinal(Bounded::<u32>::MAX), None);
}

#[test]
fn test_date_num_days_from_ce() {
    assert_eq!(ymd(1, 1, 1).num_days_from_ce(), 1);

    for year in 1_u32..10001 {
        assert_eq!(
            ymd(year, 1, 1).num_days_from_ce(), ymd(year - 1, 12, 31).num_days_from_ce() + 1,
        );
    };
}

#[test]
fn test_date_succ() {
    assert_eq!(ymd(2014, 5, 6).succ_opt(), Some(ymd(2014, 5, 7)));
    assert_eq!(ymd(2014, 5, 31).succ_opt(), Some(ymd(2014, 6, 1)));
    assert_eq!(ymd(2014, 12, 31).succ_opt(), Some(ymd(2015, 1, 1)));
    assert_eq!(ymd(2016, 2, 28).succ_opt(), Some(ymd(2016, 2, 29)));
    assert_eq!(ymd(DateTrait::MAX.year(), 12, 31).succ_opt(), None);
}

#[test]
fn test_date_pred() {
    assert_eq!(ymd(2016, 3, 1).pred_opt(), Some(ymd(2016, 2, 29)));
    assert_eq!(ymd(2015, 1, 1).pred_opt(), Some(ymd(2014, 12, 31)));
    assert_eq!(ymd(2014, 6, 1).pred_opt(), Some(ymd(2014, 5, 31)));
    assert_eq!(ymd(2014, 5, 7).pred_opt(), Some(ymd(2014, 5, 6)));
    assert_eq!(ymd(DateTrait::MIN.year(), 1, 1).pred_opt(), None);
}

fn check_date_checked_add_signed(lhs: Date, delta: TimeDelta, rhs: Option<Date>) {
    assert_eq!(lhs.checked_add_signed(delta), rhs);
    assert_eq!(lhs.checked_sub_signed(-delta), rhs);
}

#[test]
fn test_date_checked_add_signed() {
    check_date_checked_add_signed(
        ymd(2014, 1, 1), TimeDeltaTrait::zero(), DateTrait::from_ymd_opt(2014, 1, 1),
    );
    check_date_checked_add_signed(
        ymd(2014, 1, 1), TimeDeltaTrait::seconds(86399), DateTrait::from_ymd_opt(2014, 1, 1),
    );
    // always round towards zero
    check_date_checked_add_signed(
        ymd(2014, 1, 1), TimeDeltaTrait::seconds(-86399), DateTrait::from_ymd_opt(2014, 1, 1),
    );
    check_date_checked_add_signed(
        ymd(2014, 1, 1), TimeDeltaTrait::days(1), DateTrait::from_ymd_opt(2014, 1, 2),
    );
    check_date_checked_add_signed(
        ymd(2014, 1, 1), TimeDeltaTrait::days(-1), DateTrait::from_ymd_opt(2013, 12, 31),
    );
    check_date_checked_add_signed(
        ymd(2014, 1, 1), TimeDeltaTrait::days(364), DateTrait::from_ymd_opt(2014, 12, 31),
    );
    check_date_checked_add_signed(
        ymd(2014, 1, 1), TimeDeltaTrait::days(365 * 4 + 1), DateTrait::from_ymd_opt(2018, 1, 1),
    );
    check_date_checked_add_signed(
        ymd(2014, 1, 1), TimeDeltaTrait::days(365 * 400 + 97), DateTrait::from_ymd_opt(2414, 1, 1),
    );

    // check_date_checked_add_signed(
    //     DateTrait::from_ymd_opt(-7, 1, 1),
    //     TimeDeltaTrait::days(365 * 12 + 3),
    //     DateTrait::from_ymd_opt(5, 1, 1),
    // );

    // overflow check
    check_date_checked_add_signed(
        ymd(0, 1, 1),
        TimeDeltaTrait::days(MAX_DAYS_FROM_YEAR_0.try_into().unwrap()),
        DateTrait::from_ymd_opt(MAX_YEAR, 12, 31),
    );
    check_date_checked_add_signed(
        ymd(0, 1, 1), TimeDeltaTrait::days(MAX_DAYS_FROM_YEAR_0.try_into().unwrap() + 1), None,
    );
    check_date_checked_add_signed(ymd(0, 1, 1), TimeDeltaTrait::MAX, None);
    check_date_checked_add_signed(
        ymd(0, 1, 1),
        TimeDeltaTrait::days(MIN_DAYS_FROM_YEAR_0.try_into().unwrap()),
        DateTrait::from_ymd_opt(MIN_YEAR, 1, 1),
    );
    check_date_checked_add_signed(
        ymd(0, 1, 1), TimeDeltaTrait::days(MIN_DAYS_FROM_YEAR_0.try_into().unwrap() - 1), None,
    );
    check_date_checked_add_signed(ymd(0, 1, 1), TimeDeltaTrait::MIN, None);
}

fn check_date_signed_duration_since(lhs: Date, rhs: Date, delta: TimeDelta) {
    assert_eq!(lhs.signed_duration_since(rhs), delta);
    assert_eq!(rhs.signed_duration_since(lhs), -delta);
}

#[test]
fn test_date_signed_duration_since() {
    check_date_signed_duration_since(ymd(2014, 1, 1), ymd(2014, 1, 1), TimeDeltaTrait::zero());
    check_date_signed_duration_since(
        ymd(2014, 1, 2), ymd(2014, 1, 1), TimeDeltaTrait::try_days(1).unwrap(),
    );
    check_date_signed_duration_since(
        ymd(2014, 12, 31), ymd(2014, 1, 1), TimeDeltaTrait::try_days(364).unwrap(),
    );
    check_date_signed_duration_since(
        ymd(2015, 1, 3), ymd(2014, 1, 1), TimeDeltaTrait::try_days(365 + 2).unwrap(),
    );
    check_date_signed_duration_since(
        ymd(2018, 1, 1), ymd(2014, 1, 1), TimeDeltaTrait::try_days(365 * 4 + 1).unwrap(),
    );
    check_date_signed_duration_since(
        ymd(2414, 1, 1), ymd(2014, 1, 1), TimeDeltaTrait::try_days(365 * 400 + 97).unwrap(),
    );

    check_date_signed_duration_since(
        ymd(MAX_YEAR, 12, 31),
        ymd(0, 1, 1),
        TimeDeltaTrait::days(MAX_DAYS_FROM_YEAR_0.try_into().unwrap()),
    );
    check_date_signed_duration_since(
        ymd(MIN_YEAR, 1, 1),
        ymd(0, 1, 1),
        TimeDeltaTrait::days(MIN_DAYS_FROM_YEAR_0.try_into().unwrap()),
    );
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
        None,
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
    for (year, year_flags, _) in YEAR_FLAGS.span() {
        assert_eq!(DateTrait::from_yo_opt(*year, 1).unwrap().year_flags(), *year_flags);
    }
}

#[test]
fn test_weekday_with_yearflags() {
    for (year, year_flags, first_weekday) in YEAR_FLAGS.span() {
        let first_day_of_year = DateTrait::from_yo_opt(*year, 1).unwrap();

        assert_eq!(first_day_of_year.year_flags(), *year_flags);
        assert_eq!(first_day_of_year.weekday(), *first_weekday);

        let mut prev = first_day_of_year.weekday();
        for ordinal in 2_u32..year_flags.ndays() + 1 {
            let date = DateTrait::from_yo_opt(*year, ordinal).unwrap();
            let expected = prev.succ();
            assert_eq!(date.weekday(), expected);
            prev = expected;
        };
    };
}

#[test]
fn test_date_to_mdf_to_date() {
    for (year, year_flags, _) in YEAR_FLAGS.span() {
        for ordinal in 1..year_flags.ndays() {
            let date = DateTrait::from_yo_opt(*year, ordinal).unwrap();
            assert_eq!(date, DateTrait::from_mdf(date.year(), date.mdf()).unwrap());
        }
    }
}

// Used for testing some methods with all combinations of `YearFlags`.
// (year, flags, first weekday of year)
const YEAR_FLAGS: [(u32, YearFlags, Weekday); 14] = [
    (2006, A, Weekday::Sun), (2005, B, Weekday::Sat), (2010, C, Weekday::Fri),
    (2009, D, Weekday::Thu), (2003, E, Weekday::Wed), (2002, F, Weekday::Tue),
    (2001, G, Weekday::Mon), (2012, AG, Weekday::Sun), (2000, BA, Weekday::Sat),
    (2016, CB, Weekday::Fri), (2004, DC, Weekday::Thu), (2020, ED, Weekday::Wed),
    (2008, FE, Weekday::Tue), (2024, GF, Weekday::Mon),
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
