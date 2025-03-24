use chrono::prelude::*;

#[test]
fn test_examples() {
    let ymdhms = |y, m, d, h, n, s| {
        DateTrait::from_ymd_opt(y, m, d).unwrap().and_hms_opt(h, n, s).unwrap()
    };

    let dt = ymdhms(2014, 7, 8, 9, 10, 11); // `2014-07-08T09:10:11`
    assert_eq!(format!("{}", dt), "2014-07-08 09:10:11");
    // July 8 is 188th day of the year 2014 (`o` for "ordinal")
    assert_eq!(dt, DateTrait::from_yo_opt(2014, 189).unwrap().and_hms_opt(9, 10, 11).unwrap());
    // July 8 is Tuesday in ISO week 28 of the year 2014.
    assert_eq!(
        dt,
        DateTrait::from_isoywd_opt(2014, 28, Weekday::Tue).unwrap().and_hms_opt(9, 10, 11).unwrap(),
    );

    // assume this returned `2014-11-28T21:45:59`:
    let dt = ymdhms(2014, 11, 28, 21, 45, 59);
    // property accessors
    assert_eq!((dt.year(), dt.month(), dt.day()), (2014, 11, 28));
    assert_eq!((dt.month0(), dt.day0()), (10, 27)); // for unfortunate souls
    assert_eq!((dt.hour(), dt.minute(), dt.second()), (21, 45, 59));
    assert_eq!(dt.weekday(), Weekday::Fri);
    assert_eq!(dt.weekday().number_from_monday(), 5); // Mon=1, ..., Sun=7
    assert_eq!(dt.ordinal(), 332); // the day of year
    assert_eq!(dt.num_days_from_ce(), 735565); // the number of days from and including Jan 1, 1

    // a sample of property manipulations (validates dynamically)
    assert_eq!(dt.with_day(29).unwrap().weekday(), Weekday::Sat); // 2014-11-29 is Saturday
    assert_eq!(dt.with_day(32), None);
    // assert_eq!(dt.with_year(-300).unwrap().num_days_from_ce(), 109606); // November 29, 301 BCE

    // arithmetic operations
    let dt1 = ymdhms(2014, 11, 14, 8, 9, 10);
    let dt2 = ymdhms(2014, 11, 14, 10, 9, 8);
    assert_eq!(dt1.signed_duration_since(dt2), TimeDeltaTrait::seconds(-2 * 3600 + 2));
    assert_eq!(dt2.signed_duration_since(dt1), TimeDeltaTrait::seconds(2 * 3600 - 2));
    assert_eq!(
        ymdhms(1970, 1, 1, 0, 0, 0)
            .checked_add_signed(TimeDeltaTrait::seconds(1_000_000_000))
            .unwrap(),
        ymdhms(2001, 9, 9, 1, 46, 40),
    );
    assert_eq!(
        ymdhms(1970, 1, 1, 0, 0, 0)
            .checked_sub_signed(TimeDeltaTrait::seconds(1_000_000_000))
            .unwrap(),
        ymdhms(1938, 4, 24, 22, 13, 20),
    );

    // Formatting
    let dt: DateTime = Default::default();
    assert_eq!(format!("{}", dt), "1970-01-01 00:00:00");

    // Construct a datetime from epoch:
    let dt = DateTimeTrait::from_timestamp(1_500_000_000).unwrap();
    assert_eq!(format!("{}", dt), "2017-07-14 02:40:00");

    // Get epoch value from a datetime:
    let dt = ymdhms(2017, 7, 14, 2, 40, 0);
    assert_eq!(dt.timestamp(), 1_500_000_000);
}
