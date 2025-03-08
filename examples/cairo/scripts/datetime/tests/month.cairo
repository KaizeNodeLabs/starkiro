use core::num::traits::Bounded;
use datetime::date::DateTrait;
use datetime::datetime::DateTimeTrait;
use datetime::month::{Month, MonthTrait, MonthsTrait};

#[test]
fn test_month_enum_try_from() {
    assert_eq!(1_u8.try_into(), Some(Month::January));
    assert_eq!(2_u8.try_into(), Some(Month::February));
    assert_eq!(12_u8.try_into(), Some(Month::December));
    let month_opt: Option<Month> = 13_u8.try_into();
    assert_eq!(month_opt, None);

    let date = DateTrait::from_ymd_opt(2019, 10, 28).unwrap().and_hms_opt(9, 10, 11).unwrap();
    let month_u8: u8 = date.month().try_into().unwrap();
    assert_eq!(month_u8.try_into(), Some(Month::October));
    let month = Month::January;
    let dt = DateTrait::from_ymd_opt(2019, month.number_from_month(), 28)
        .unwrap()
        .and_hms_opt(9, 10, 11)
        .unwrap();
    assert_eq!((dt.year(), dt.month(), dt.day()), (2019, 1, 28));
}

#[test]
fn test_month_enum_primitive_parse() {
    let jan_opt = MonthTrait::from_u32(1);
    let feb_opt = MonthTrait::from_u64(2);
    let dec_opt = MonthTrait::from_i64(12);
    let no_month = MonthTrait::from_u32(13);
    assert_eq!(jan_opt, Some(Month::January));
    assert_eq!(feb_opt, Some(Month::February));
    assert_eq!(dec_opt, Some(Month::December));
    assert_eq!(no_month, None);

    let date = DateTimeTrait::from_ymd_and_hms_opt(2019, 10, 28, 9, 10, 11).unwrap();
    assert_eq!(MonthTrait::from_u32(date.month()), Some(Month::October));

    let month = Month::January;
    let dt = DateTimeTrait::from_ymd_and_hms_opt(2019, month.number_from_month(), 28, 9, 10, 11)
        .unwrap();
    assert_eq!((dt.year(), dt.month(), dt.day()), (2019, 1, 28));
}

#[test]
fn test_month_enum_succ_pred() {
    assert_eq!(Month::January.succ(), Month::February);
    assert_eq!(Month::December.succ(), Month::January);
    assert_eq!(Month::January.pred(), Month::December);
    assert_eq!(Month::February.pred(), Month::January);
}

#[test]
fn test_month_partial_ord() {
    assert!(Month::January <= Month::January);
    assert!(Month::January < Month::February);
    assert!(Month::January < Month::December);
    assert!(Month::July >= Month::May);
    assert!(Month::September > Month::March);
}

#[test]
fn test_months_as_u32() {
    assert_eq!(MonthsTrait::new(0).as_u32(), 0);
    assert_eq!(MonthsTrait::new(1).as_u32(), 1);
    assert_eq!(MonthsTrait::new(Bounded::<u32>::MAX).as_u32(), Bounded::<u32>::MAX);
}

#[test]
fn test_month_num_days() {
    assert_eq!(Month::January.num_days(2020), Some(31));
    assert_eq!(Month::February.num_days(2020), Some(29));
    assert_eq!(Month::February.num_days(2019), Some(28));
}
