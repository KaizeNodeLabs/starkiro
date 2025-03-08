use core::num::traits::Bounded;
use datetime::time::{Time, TimeTrait};
use datetime::time_delta::{TimeDelta, TimeDeltaTrait};

fn hms(h: u32, m: u32, s: u32) -> Time {
    TimeTrait::from_hms_opt(h, m, s).unwrap()
}

#[test]
fn test_time_hms() {
    assert_eq!(hms(3, 5, 7).hour(), 3);
    assert_eq!(hms(3, 5, 7).with_hour(0), Some(hms(0, 5, 7)));
    assert_eq!(hms(3, 5, 7).with_hour(23), Some(hms(23, 5, 7)));
    assert_eq!(hms(3, 5, 7).with_hour(24), None);
    assert_eq!(hms(3, 5, 7).with_hour(Bounded::<u32>::MAX), None);

    assert_eq!(hms(3, 5, 7).minute(), 5);
    assert_eq!(hms(3, 5, 7).with_minute(0), Some(hms(3, 0, 7)));
    assert_eq!(hms(3, 5, 7).with_minute(59), Some(hms(3, 59, 7)));
    assert_eq!(hms(3, 5, 7).with_minute(60), None);
    assert_eq!(hms(3, 5, 7).with_minute(Bounded::<u32>::MAX), None);

    assert_eq!(hms(3, 5, 7).second(), 7);
    assert_eq!(hms(3, 5, 7).with_second(0), Some(hms(3, 5, 0)));
    assert_eq!(hms(3, 5, 7).with_second(59), Some(hms(3, 5, 59)));
    assert_eq!(hms(3, 5, 7).with_second(60), None);
    assert_eq!(hms(3, 5, 7).with_second(Bounded::<u32>::MAX), None);
}

fn check_time_add(lhs: Time, rhs: TimeDelta, sum: Time) {
    let (result, _) = lhs.overflowing_add_signed(rhs);
    assert_eq!(result, sum);
}

#[test]
fn test_time_add() {
    check_time_add(hms(3, 5, 59), TimeDeltaTrait::zero(), hms(3, 5, 59));
    check_time_add(hms(3, 5, 59), TimeDeltaTrait::seconds(1), hms(3, 6, 0));
    check_time_add(hms(3, 5, 59), TimeDeltaTrait::seconds(-1), hms(3, 5, 58));
    check_time_add(hms(3, 5, 59), TimeDeltaTrait::seconds(86399), hms(3, 5, 58)); //overwrap
    check_time_add(hms(3, 5, 59), TimeDeltaTrait::seconds(-86399), hms(3, 6, 0));
    check_time_add(hms(3, 5, 59), TimeDeltaTrait::days(12345), hms(3, 5, 59));
    check_time_add(hms(3, 5, 59), TimeDeltaTrait::days(1), hms(3, 5, 59));
    check_time_add(hms(3, 5, 59), TimeDeltaTrait::days(-1), hms(3, 5, 59));
    check_time_add(hms(0, 0, 0), TimeDeltaTrait::seconds(-1), hms(23, 59, 59));
}

#[test]
fn test_time_overflowing_add() {
    assert_eq!(hms(3, 4, 5).overflowing_add_signed(TimeDeltaTrait::hours(11)), (hms(14, 4, 5), 0));
    assert_eq!(
        hms(3, 4, 5).overflowing_add_signed(TimeDeltaTrait::hours(23)), (hms(2, 4, 5), 86_400),
    );
    assert_eq!(
        hms(3, 4, 5).overflowing_add_signed(TimeDeltaTrait::hours(-7)), (hms(20, 4, 5), -86_400),
    );
    // overflowing_add_signed with leap seconds may be counter-intuitive
// assert_eq!(
//     hmsm(3, 4, 59, 1_678).overflowing_add_signed(TimeDelta::try_days(1).unwrap()),
//     (hmsm(3, 4, 59, 678), 86_400)
// );
// assert_eq!(
//     hmsm(3, 4, 59, 1_678).overflowing_add_signed(TimeDelta::try_days(-1).unwrap()),
//     (hmsm(3, 5, 0, 678), -86_400)
// );
}

fn check_time_sub(lhs: Time, rhs: TimeDelta, diff: Time) {
    let (result, _) = lhs.overflowing_sub_signed(rhs);
    assert_eq!(result, diff);
}

#[test]
fn test_time_sub() {
    check_time_sub(hms(3, 5, 59), TimeDeltaTrait::zero(), hms(3, 5, 59));
    check_time_sub(hms(3, 5, 7), TimeDeltaTrait::seconds(3600 + 60 + 1), hms(2, 4, 6));
}

#[test]
fn test_time_fmt() {
    assert_eq!(format!("{}", hms(23, 59, 59)), "23:59:59");
}
