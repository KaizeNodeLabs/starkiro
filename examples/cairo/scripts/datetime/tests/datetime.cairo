use datetime::date::DateTrait;
use datetime::datetime::{DateTime, DateTimeTrait};
use datetime::time_delta::{TimeDelta, TimeDeltaTrait};
use snforge_std::start_cheat_block_timestamp_global;
use starknet::get_block_timestamp;

fn ymdhms(y: i32, m: u32, d: u32, h: u32, n: u32, s: u32) -> DateTime {
    DateTimeTrait::from_ymd_and_hms_opt(y.try_into().unwrap(), m, d, h, n, s).unwrap()
}

fn check_datetime_add(
    tuple: (i32, u32, u32, u32, u32, u32),
    rhs: TimeDelta,
    result: Option<(i32, u32, u32, u32, u32, u32)>,
) {
    let (y, m, d, h, n, s) = tuple;
    let lhs = ymdhms(y, m, d, h, n, s);
    let sum = result
        .map(
            |tuple: (i32, u32, u32, u32, u32, u32)| {
                let (y, m, d, h, n, s) = tuple;
                ymdhms(y, m, d, h, n, s)
            },
        );
    assert_eq!(lhs.checked_add_signed(rhs), sum);
    assert_eq!(lhs.checked_sub_signed(-rhs), sum);
}

#[test]
fn test_datetime_add() {
    check_datetime_add(
        (2014, 5, 6, 7, 8, 9), TimeDeltaTrait::seconds(3600 + 60 + 1), Some((2014, 5, 6, 8, 9, 10)),
    );
    check_datetime_add(
        (2014, 5, 6, 7, 8, 9),
        TimeDeltaTrait::seconds(-(3600 + 60 + 1)),
        Some((2014, 5, 6, 6, 7, 8)),
    );
    check_datetime_add(
        (2014, 5, 6, 7, 8, 9), TimeDeltaTrait::seconds(86399), Some((2014, 5, 7, 7, 8, 8)),
    );
    check_datetime_add(
        (2014, 5, 6, 7, 8, 9), TimeDeltaTrait::seconds(86_400 * 10), Some((2014, 5, 16, 7, 8, 9)),
    );
    check_datetime_add(
        (2014, 5, 6, 7, 8, 9), TimeDeltaTrait::seconds(-86_400 * 10), Some((2014, 4, 26, 7, 8, 9)),
    );
    check_datetime_add(
        (2014, 5, 6, 7, 8, 9), TimeDeltaTrait::seconds(86_400 * 10), Some((2014, 5, 16, 7, 8, 9)),
    );

    // overflow check
    // assumes that we have correct values for MAX/MIN_DAYS_FROM_YEAR_0 from `naive::date`.
    // (they are private constants, but the equivalence is tested in that module.)
    let max_days_from_year_0 = DateTrait::MAX
        .signed_duration_since(DateTrait::from_ymd_opt(0, 1, 1).unwrap());
    check_datetime_add(
        (0, 1, 1, 0, 0, 0),
        max_days_from_year_0,
        Some((DateTrait::MAX.year().try_into().unwrap(), 12, 31, 0, 0, 0)),
    );
    check_datetime_add(
        (0, 1, 1, 0, 0, 0),
        max_days_from_year_0 + TimeDeltaTrait::seconds(86399),
        Some((DateTrait::MAX.year().try_into().unwrap(), 12, 31, 23, 59, 59)),
    );
    check_datetime_add(
        (0, 1, 1, 0, 0, 0), max_days_from_year_0 + TimeDeltaTrait::seconds(86_400), None,
    );
    check_datetime_add((0, 1, 1, 0, 0, 0), TimeDeltaTrait::MAX, None);
}

#[test]
fn test_datetime_sub() {
    assert_eq!(
        DateTimeTrait::signed_duration_since(
            @ymdhms(2014, 5, 6, 7, 8, 9), ymdhms(2014, 5, 6, 7, 8, 9),
        ),
        TimeDeltaTrait::zero(),
    );
    assert_eq!(
        DateTimeTrait::signed_duration_since(
            @ymdhms(2014, 5, 6, 7, 8, 10), ymdhms(2014, 5, 6, 7, 8, 9),
        ),
        TimeDeltaTrait::seconds(1),
    );
    assert_eq!(
        DateTimeTrait::signed_duration_since(
            @ymdhms(2014, 5, 6, 7, 8, 9), ymdhms(2014, 5, 6, 7, 8, 10),
        ),
        TimeDeltaTrait::seconds(-1),
    );
    assert_eq!(
        DateTimeTrait::signed_duration_since(
            @ymdhms(2014, 5, 7, 7, 8, 9), ymdhms(2014, 5, 6, 7, 8, 10),
        ),
        TimeDeltaTrait::seconds(86399),
    );
    assert_eq!(
        DateTimeTrait::signed_duration_since(
            @ymdhms(2001, 9, 9, 1, 46, 39), ymdhms(1970, 1, 1, 0, 0, 0),
        ),
        TimeDeltaTrait::seconds(999_999_999),
    );
}

#[test]
fn test_datetime_add_sub_invariant() {
    // issue #37
    let base = ymdhms(200, 1, 1, 0, 0, 0);
    let t = -946684799;
    let time = base.checked_add_signed(TimeDeltaTrait::seconds(t)).unwrap();
    assert_eq!(t, time.signed_duration_since(base).num_seconds());
}

#[test]
fn test_datetime_from_timestamp() {
    let dt1 = DateTimeTrait::from_timestamp(get_block_timestamp().try_into().unwrap()).unwrap();
    assert_eq!(format!("{}", dt1), "1970-01-01 00:00:00");
    start_cheat_block_timestamp_global(1707868800);
    let dt2 = DateTimeTrait::from_timestamp(get_block_timestamp().try_into().unwrap()).unwrap();
    assert_eq!(format!("{}", dt2), "2024-02-14 00:00:00");
    assert!(dt1 < dt2);
}
