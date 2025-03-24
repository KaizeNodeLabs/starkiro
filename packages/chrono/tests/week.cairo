use chrono::prelude::*;
use core::ops::RangeInclusiveTrait;
use super::utils::ymd;

#[test]
fn test_week() {
    let date = ymd(2022, 5, 18);
    let asserts = [
        (Weekday::Mon, ymd(2022, 5, 16), ymd(2022, 5, 22)),
        (Weekday::Tue, ymd(2022, 5, 17), ymd(2022, 5, 23)),
        (Weekday::Wed, ymd(2022, 5, 18), ymd(2022, 5, 24)),
        (Weekday::Thu, ymd(2022, 5, 12), ymd(2022, 5, 18)),
        (Weekday::Fri, ymd(2022, 5, 13), ymd(2022, 5, 19)),
        (Weekday::Sat, ymd(2022, 5, 14), ymd(2022, 5, 20)),
        (Weekday::Sun, ymd(2022, 5, 15), ymd(2022, 5, 21)),
    ];
    for (start, first_day, last_day) in asserts.span() {
        let week = date.week(*start);
        let days = week.days();
        assert_eq!(week.first_day(), *first_day);
        assert_eq!(week.last_day(), *last_day);
        assert!(days.contains(@date));
    }
}

#[test]
fn test_week_min_max() {
    let date_max = DateTrait::MAX;
    assert_le!(date_max.week(Weekday::Mon).first_day(), date_max);
    let date_min = DateTrait::MIN;
    assert_ge!(date_min.week(Weekday::Mon).last_day(), date_min);
}

#[test]
fn test_week_checked_no_panic() {
    let date_max = DateTrait::MAX;
    if let Some(last) = date_max.week(Weekday::Mon).checked_last_day() {
        assert_eq!(last, date_max);
    }
    let date_min = DateTrait::MIN;
    if let Some(first) = date_min.week(Weekday::Mon).checked_first_day() {
        assert_eq!(first, date_min);
    }
    let _ = date_min.week(Weekday::Mon).checked_days();
    let _ = date_max.week(Weekday::Mon).checked_days();
}
