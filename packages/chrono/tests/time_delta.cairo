use chrono::prelude::*;
use core::num::traits::Bounded;

#[test]
fn test_duration() {
    assert!(TimeDeltaTrait::seconds(1) != TimeDeltaTrait::zero());
    assert_eq!(TimeDeltaTrait::seconds(1) + TimeDeltaTrait::seconds(2), TimeDeltaTrait::seconds(3));
    assert_eq!(
        TimeDeltaTrait::seconds(86_399) + TimeDeltaTrait::seconds(4),
        TimeDeltaTrait::days(1) + TimeDeltaTrait::seconds(3),
    );
    assert_eq!(
        TimeDeltaTrait::days(10) - TimeDeltaTrait::seconds(1000), TimeDeltaTrait::seconds(863_000),
    );
    assert_eq!(
        TimeDeltaTrait::days(10) - TimeDeltaTrait::seconds(1_000_000),
        TimeDeltaTrait::seconds(-136_000),
    );
    // assert_eq!(
    //     days(2) + seconds(86_399) + TimeDelta::nanoseconds(1_234_567_890),
    //     days(3) + TimeDelta::nanoseconds(234_567_890),
    // );
    assert_eq!(-TimeDeltaTrait::days(3), TimeDeltaTrait::days(-3));
    assert_eq!(
        -(TimeDeltaTrait::days(3) + TimeDeltaTrait::seconds(70)),
        TimeDeltaTrait::days(-4) + TimeDeltaTrait::seconds(86_400 - 70),
    );

    assert_eq!(
        Default::default() + TimeDeltaTrait::minutes(1) - TimeDeltaTrait::seconds(30),
        TimeDeltaTrait::seconds(30),
    );
}

#[test]
fn test_duration_num_days() {
    assert_eq!(TimeDeltaTrait::zero().num_days(), 0);
    assert_eq!(TimeDeltaTrait::days(1).num_days(), 1);
    assert_eq!(TimeDeltaTrait::days(-1).num_days(), -1);
    assert_eq!(TimeDeltaTrait::seconds(86_399).num_days(), 0);
    assert_eq!(TimeDeltaTrait::seconds(86_401).num_days(), 1);
    assert_eq!(TimeDeltaTrait::seconds(-86_399).num_days(), 0);
    assert_eq!(TimeDeltaTrait::seconds(-86_401).num_days(), -1);
    assert_eq!(
        TimeDeltaTrait::days(Bounded::<i32>::MAX.try_into().unwrap()).num_days(),
        Bounded::<i32>::MAX.try_into().unwrap(),
    );
    assert_eq!(
        TimeDeltaTrait::days(Bounded::<i32>::MIN.try_into().unwrap()).num_days(),
        Bounded::<i32>::MIN.try_into().unwrap(),
    );
}

#[test]
fn test_duration_num_seconds() {
    assert_eq!(TimeDeltaTrait::zero().num_seconds(), 0);
    assert_eq!(TimeDeltaTrait::seconds(1).num_seconds(), 1);
    assert_eq!(TimeDeltaTrait::seconds(-1).num_seconds(), -1);
}

#[test]
fn test_duration_seconds_max_allowed() {
    let duration = TimeDeltaTrait::seconds(Bounded::<i64>::MAX / 1_000);
    assert_eq!(duration.num_seconds(), Bounded::<i64>::MAX / 1_000);
}

#[test]
fn test_duration_seconds_max_overflow() {
    assert!(TimeDeltaTrait::try_seconds(Bounded::<i64>::MAX / 1_000 + 1).is_none());
}

#[test]
#[should_panic(expected: 'TimeDelta::secs out of bounds')]
fn test_duration_seconds_max_overflow_panic() {
    let _ = TimeDeltaTrait::seconds(Bounded::<i64>::MAX / 1_000 + 1);
}

#[test]
fn test_duration_seconds_min_allowed() {
    let duration = TimeDeltaTrait::seconds(
        Bounded::<i64>::MIN / 1_000,
    ); // Same as -i64::MAX / 1_000 due to rounding
    assert_eq!(
        duration.num_seconds(), Bounded::<i64>::MIN / 1_000,
    ); // Same as -i64::MAX / 1_000 due to rounding
}

#[test]
fn test_duration_seconds_min_underflow() {
    assert!(TimeDeltaTrait::try_seconds(-Bounded::<i64>::MAX / 1_000 - 1).is_none());
}

#[test]
#[should_panic(expected: 'TimeDelta::secs out of bounds')]
fn test_duration_seconds_min_underflow_panic() {
    let _ = TimeDeltaTrait::seconds(-Bounded::<i64>::MAX / 1_000 - 1);
}

#[test]
fn test_duration_ord() {
    assert!(TimeDeltaTrait::seconds(1) < TimeDeltaTrait::seconds(2));
    assert!(TimeDeltaTrait::seconds(2) > TimeDeltaTrait::seconds(1));
    assert!(TimeDeltaTrait::seconds(-1) > TimeDeltaTrait::seconds(-2));
    assert!(TimeDeltaTrait::seconds(-2) < TimeDeltaTrait::seconds(-1));
    assert!(TimeDeltaTrait::seconds(-1) < TimeDeltaTrait::seconds(1));
    assert!(TimeDeltaTrait::seconds(1) > TimeDeltaTrait::seconds(-1));
    assert!(TimeDeltaTrait::seconds(0) < TimeDeltaTrait::seconds(1));
    assert!(TimeDeltaTrait::seconds(0) > TimeDeltaTrait::seconds(-1));
    assert!(TimeDeltaTrait::seconds(1_001) < TimeDeltaTrait::seconds(1_002));
    assert!(TimeDeltaTrait::seconds(-1_001) > TimeDeltaTrait::seconds(-1_002));
    assert!(TimeDeltaTrait::seconds(1_234_567_890) < TimeDeltaTrait::seconds(1_234_567_891));
    assert!(TimeDeltaTrait::seconds(-1_234_567_890) > TimeDeltaTrait::seconds(-1_234_567_891));
    assert!(
        TimeDeltaTrait::seconds(
            Bounded::<i64>::MAX / 1_000,
        ) > TimeDeltaTrait::seconds(Bounded::<i64>::MAX / 1_000 - 1),
    );
    assert!(
        TimeDeltaTrait::seconds(
            -Bounded::<i64>::MAX / 1_000,
        ) < TimeDeltaTrait::seconds(-Bounded::<i64>::MAX / 1_000 + 1),
    );
}

#[test]
fn test_duration_checked_ops() {
    assert_eq!(
        TimeDeltaTrait::seconds(Bounded::<i64>::MAX / 1_000)
            .checked_add(TimeDeltaTrait::seconds(0)),
        Some(TimeDeltaTrait::seconds(Bounded::<i64>::MAX / 1_000)),
    );
    assert_eq!(
        TimeDeltaTrait::seconds(Bounded::<i64>::MAX / 1_000 - 2)
            .checked_add(TimeDeltaTrait::seconds(1)),
        Some(TimeDeltaTrait::seconds(Bounded::<i64>::MAX / 1_000 - 2) + TimeDeltaTrait::seconds(1)),
    );
    assert!(
        TimeDeltaTrait::seconds(Bounded::<i64>::MAX / 1_000)
            .checked_add(TimeDeltaTrait::seconds(1))
            .is_none(),
    );

    assert_eq!(
        TimeDeltaTrait::seconds(-Bounded::<i64>::MAX / 1_000)
            .checked_sub(TimeDeltaTrait::seconds(0)),
        Some(TimeDeltaTrait::seconds(-Bounded::<i64>::MAX / 1_000)),
    );
    assert_eq!(
        TimeDeltaTrait::seconds(-Bounded::<i64>::MAX / 1_000 + 2)
            .checked_sub(TimeDeltaTrait::seconds(1)),
        Some(
            TimeDeltaTrait::seconds(-Bounded::<i64>::MAX / 1_000 + 2) - TimeDeltaTrait::seconds(1),
        ),
    );
    assert!(
        TimeDeltaTrait::seconds(-Bounded::<i64>::MAX / 1_000)
            .checked_sub(TimeDeltaTrait::seconds(1))
            .is_none(),
    );

    assert!(TimeDeltaTrait::seconds(Bounded::<i64>::MAX / 1_000).checked_mul(2000).is_none());
    assert!(TimeDeltaTrait::seconds(Bounded::<i64>::MAX / 1_000).checked_mul(2000).is_none());
    assert!(TimeDeltaTrait::seconds(1).checked_div(0).is_none());
}

#[test]
fn test_duration_abs() {
    assert_eq!(TimeDeltaTrait::seconds(1300).abs(), TimeDeltaTrait::seconds(1300));
    assert_eq!(TimeDeltaTrait::seconds(1000).abs(), TimeDeltaTrait::seconds(1000));
    assert_eq!(TimeDeltaTrait::seconds(300).abs(), TimeDeltaTrait::seconds(300));
    assert_eq!(TimeDeltaTrait::seconds(0).abs(), TimeDeltaTrait::seconds(0));
    assert_eq!(TimeDeltaTrait::seconds(-300).abs(), TimeDeltaTrait::seconds(300));
    assert_eq!(TimeDeltaTrait::seconds(-700).abs(), TimeDeltaTrait::seconds(700));
    assert_eq!(TimeDeltaTrait::seconds(-1000).abs(), TimeDeltaTrait::seconds(1000));
    assert_eq!(TimeDeltaTrait::seconds(-1300).abs(), TimeDeltaTrait::seconds(1300));
    assert_eq!(TimeDeltaTrait::seconds(-1700).abs(), TimeDeltaTrait::seconds(1700));
    assert_eq!(
        TimeDeltaTrait::seconds(-Bounded::<i64>::MAX / 1_000).abs(),
        TimeDeltaTrait::seconds(Bounded::<i64>::MAX / 1_000),
    );
}

#[test]
fn test_duration_mul() {
    assert_eq!(
        TimeDeltaTrait::zero().checked_mul(Bounded::<i32>::MAX).unwrap(), TimeDeltaTrait::zero(),
    );
    assert_eq!(
        TimeDeltaTrait::zero().checked_mul(Bounded::<i32>::MIN).unwrap(), TimeDeltaTrait::zero(),
    );
    assert_eq!(TimeDeltaTrait::seconds(1).checked_mul(0).unwrap(), TimeDeltaTrait::zero());
    assert_eq!(TimeDeltaTrait::seconds(1).checked_mul(1).unwrap(), TimeDeltaTrait::seconds(1));
    assert_eq!(TimeDeltaTrait::seconds(1).checked_mul(60).unwrap(), TimeDeltaTrait::minutes(1));
    assert_eq!(TimeDeltaTrait::seconds(1).checked_mul(-60).unwrap(), -TimeDeltaTrait::minutes(1));
    assert_eq!(-TimeDeltaTrait::seconds(1).checked_mul(60).unwrap(), -TimeDeltaTrait::minutes(1));
    assert_eq!(
        TimeDeltaTrait::seconds(30).checked_mul(3).unwrap(),
        TimeDeltaTrait::minutes(2) - TimeDeltaTrait::seconds(30),
    );
    assert_eq!(
        (TimeDeltaTrait::seconds(1) + TimeDeltaTrait::minutes(1) + TimeDeltaTrait::hours(1))
            .checked_mul(3)
            .unwrap(),
        TimeDeltaTrait::seconds(3) + TimeDeltaTrait::minutes(3) + TimeDeltaTrait::hours(3),
    );
    assert_eq!(TimeDeltaTrait::seconds(90).checked_mul(-2).unwrap(), TimeDeltaTrait::minutes(-3));
    assert_eq!(TimeDeltaTrait::seconds(-90).checked_mul(2).unwrap(), TimeDeltaTrait::minutes(-3));
}

#[test]
fn test_duration_div() {
    assert_eq!(
        TimeDeltaTrait::zero().checked_div(Bounded::<i32>::MAX).unwrap(), TimeDeltaTrait::zero(),
    );
    assert_eq!(
        TimeDeltaTrait::zero().checked_div(Bounded::<i32>::MIN).unwrap(), TimeDeltaTrait::zero(),
    );
    assert_eq!(
        TimeDeltaTrait::seconds(123_456_789).checked_div(1).unwrap(),
        TimeDeltaTrait::seconds(123_456_789),
    );
    assert_eq!(
        TimeDeltaTrait::seconds(123_456_789).checked_div(-1).unwrap(),
        -TimeDeltaTrait::seconds(123_456_789),
    );
    assert_eq!(
        -TimeDeltaTrait::seconds(123_456_789).checked_div(-1).unwrap(),
        TimeDeltaTrait::seconds(123_456_789),
    );
    assert_eq!(
        -TimeDeltaTrait::seconds(123_456_789).checked_div(1).unwrap(),
        -TimeDeltaTrait::seconds(123_456_789),
    );
    assert_eq!(TimeDeltaTrait::minutes(1).checked_div(3).unwrap(), TimeDeltaTrait::seconds(20));
    assert_eq!(TimeDeltaTrait::minutes(4).checked_div(3).unwrap(), TimeDeltaTrait::seconds(80));
    assert_eq!(TimeDeltaTrait::minutes(-1).checked_div(2).unwrap(), TimeDeltaTrait::seconds(-30));
    assert_eq!(TimeDeltaTrait::minutes(1).checked_div(-2).unwrap(), TimeDeltaTrait::seconds(-30));
    assert_eq!(TimeDeltaTrait::minutes(-1).checked_div(-2).unwrap(), TimeDeltaTrait::seconds(30));
    assert_eq!(TimeDeltaTrait::minutes(-4).checked_div(3).unwrap(), TimeDeltaTrait::seconds(-80));
    assert_eq!(TimeDeltaTrait::minutes(-4).checked_div(-3).unwrap(), TimeDeltaTrait::seconds(80));
}

#[test]
fn test_duration_fmt() {
    assert_eq!(format!("{}", TimeDeltaTrait::zero()), "P0D");
    assert_eq!(format!("{}", TimeDeltaTrait::days(42)), "PT3628800S");
    assert_eq!(format!("{}", TimeDeltaTrait::days(-42)), "-PT3628800S");
    assert_eq!(format!("{}", TimeDeltaTrait::seconds(42)), "PT42S");
    assert_eq!(format!("{}", TimeDeltaTrait::seconds(-86_401)), "-PT86401S");
}
