use chrono::prelude::*;
use super::utils::ymd;

// #[test]
// fn test_iso_week_extremes() {
//     let minweek = DateTrait::MIN.iso_week();
//     let maxweek = DateTrait::MAX.iso_week();

//     assert_eq!(minweek.year(), MIN_YEAR);
//     assert_eq!(minweek.week(), 1);
//     assert_eq!(minweek.week0(), 0);
//     // #[cfg(feature = "alloc")]
//     // assert_eq!(format!("{:?}", minweek), NaiveDate::MIN.format("%G-W%V").to_string());

//     assert_eq!(maxweek.year(), MAX_YEAR + 1);
//     assert_eq!(maxweek.week(), 1);
//     assert_eq!(maxweek.week0(), 0);
//     // #[cfg(feature = "alloc")]
//     //assert_eq!(format!("{:?}", maxweek), NaiveDate::MAX.format("%G-W%V").to_string());
// }

#[test]
fn test_iso_week_equivalence_for_first_week() {
    let monday = ymd(2024, 12, 30);
    let friday = ymd(2025, 1, 3);

    assert_eq!(monday.iso_week(), friday.iso_week());
}

#[test]
fn test_iso_week_equivalence_for_last_week() {
    let monday = ymd(2026, 12, 28);
    let friday = ymd(2027, 1, 1);

    assert_eq!(monday.iso_week(), friday.iso_week());
}

#[test]
fn test_iso_week_ordering_for_first_week() {
    let monday = ymd(2024, 12, 30);
    let friday = ymd(2025, 1, 3);

    assert!(monday.iso_week() >= friday.iso_week());
    assert!(monday.iso_week() <= friday.iso_week());
}

#[test]
fn test_iso_week_ordering_for_last_week() {
    let monday = ymd(2026, 12, 28);
    let friday = ymd(2027, 1, 1);

    assert!(monday.iso_week() >= friday.iso_week());
    assert!(monday.iso_week() <= friday.iso_week());
}
