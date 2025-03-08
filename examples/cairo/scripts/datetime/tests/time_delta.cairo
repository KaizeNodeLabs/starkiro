use core::num::traits::Bounded;
use datetime::time_delta::TimeDeltaTrait;

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
#[should_panic(expected: 'Option::unwrap failed.')]
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
#[should_panic(expected: 'Option::unwrap failed.')]
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
    // assert!(milliseconds(i64::MAX) > milliseconds(i64::MAX - 1));
// assert!(milliseconds(-i64::MAX) < milliseconds(-i64::MAX + 1));
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
    // assert_eq!(TimeDeltaTrait::seconds(-i64::MAX).abs(), TimeDeltaTrait::seconds(i64::MAX));
}
