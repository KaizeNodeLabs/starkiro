//! ISO 8601 calendar date without timezone.
//!
//! The implementation is optimized for determining year, month, day and day of week.
//!
//! Format of `NaiveDate`:
//! `YYYY_YYYY_YYYY_YYYY_YYYO_OOOO_OOOO_LWWW`
//! `Y`: Year
//! `O`: Ordinal
//! `L`: leap year flag (1 = common year, 0 is leap year)
//! `W`: weekday before the first day of the year
//! `LWWW`: will also be referred to as the year flags (`F`)

use core::num::traits::Bounded;
use core::num::traits::CheckedAdd;
use core::fmt::{Display, Formatter, Error, Debug};
use super::Days;
use super::utils::{TWO_POW_3, TWO_POW_4, TWO_POW_13, rem_euclid, div_euclid};
use super::internals::{Mdf, MdfTrait, YearFlags, YearFlagsTrait};
use super::month::{Months, MonthsTrait};
use super::format::formatting::{write_hundreds};

/// ISO 8601 calendar date without timezone.
/// Allows for every [proleptic Gregorian date] from Jan 1, 262145 BCE to Dec 31, 262143 CE.
/// Also supports the conversion from ISO 8601 ordinal and week date.
///
/// # Calendar Date
///
/// The ISO 8601 **calendar date** follows the proleptic Gregorian calendar.
/// It is like a normal civil calendar but note some slight differences:
///
/// * Dates before the Gregorian calendar's inception in 1582 are defined via the extrapolation.
///   Be careful, as historical dates are often noted in the Julian calendar and others
///   and the transition to Gregorian may differ across countries (as late as early 20C).
///
///   (Some example: Both Shakespeare from Britain and Cervantes from Spain seemingly died
///   on the same calendar date---April 23, 1616---but in the different calendar.
///   Britain used the Julian calendar at that time, so Shakespeare's death is later.)
///
/// * ISO 8601 calendars have the year 0, which is 1 BCE (a year before 1 CE).
///   If you need a typical BCE/BC and CE/AD notation for year numbers,
///   use the [`Datelike::year_ce`] method.
///
/// # Week Date
///
/// The ISO 8601 **week date** is a triple of year number, week number
/// and [day of the week](Weekday) with the following rules:
///
/// * A week consists of Monday through Sunday, and is always numbered within some year.
///   The week number ranges from 1 to 52 or 53 depending on the year.
///
/// * The week 1 of given year is defined as the first week containing January 4 of that year,
///   or equivalently, the first week containing four or more days in that year.
///
/// * The year number in the week date may *not* correspond to the actual Gregorian year.
///   For example, January 3, 2016 (Sunday) was on the last (53rd) week of 2015.
///
/// Chrono's date types default to the ISO 8601 [calendar date](#calendar-date), but
/// [`Datelike::iso_week`] and [`Datelike::weekday`] methods can be used to get the corresponding
/// week date.
///
/// # Ordinal Date
///
/// The ISO 8601 **ordinal date** is a pair of year number and day of the year ("ordinal").
/// The ordinal number ranges from 1 to 365 or 366 depending on the year.
/// The year number is the same as that of the [calendar date](#calendar-date).
///
/// This is currently the internal format of Chrono's date types.
///
/// [proleptic Gregorian date]: crate::NaiveDate#calendar-date
#[derive(Clone, Copy, PartialEq, Drop)]
pub struct Date {
    yof: u32 // (year << 13) | of
}

impl DatePartialOrd of PartialOrd<Date> {
    fn lt(lhs: Date, rhs: Date) -> bool {
        lhs.yof < rhs.yof
    }
    fn ge(lhs: Date, rhs: Date) -> bool {
        lhs.yof >= rhs.yof
    }
}

#[generate_trait]
pub impl DateImpl of DateTrait {
    /// Makes a new `NaiveDate` from year, ordinal and flags.
    /// Does not check whether the flags are correct for the provided year.
    fn from_ordinal_and_flags(year: u32, ordinal: u32, flags: YearFlags) -> Option<Date> {
        if year < MIN_YEAR || year > MAX_YEAR {
            return Option::None; // Out-of-range
        }
        if ordinal == 0 || ordinal > 366 {
            return Option::None; // Invalid
        }
        // debug_assert!(YearFlags::from_year(year).0 == flags.0);
        let yof = (year * TWO_POW_13) | (ordinal * TWO_POW_4) | flags.flags.into();
        match yof & OL_MASK <= MAX_OL {
            true => Option::Some(Self::from_yof(yof)),
            false => Option::None // Does not exist: Ordinal 366 in a common year.
        }
    }

    /// Makes a new `NaiveDate` from year and packed month-day-flags.
    /// Does not check whether the flags are correct for the provided year.
    fn from_mdf(year: u32, mdf: Mdf) -> Option<Date> {
        if year < MIN_YEAR || year > MAX_YEAR {
            return Option::None; // Out-of-range
        }
        let of_opt = mdf.ordinal_and_flags();
        if of_opt.is_none() {
            return Option::None;
        }
        let yof = (year * TWO_POW_13) | of_opt.unwrap();
        Option::Some(Self::from_yof(yof))
    }

    /// Makes a new `NaiveDate` from the [calendar date](#calendar-date)
    /// (year, month and day).
    ///
    /// # Errors
    ///
    /// Returns `None` if:
    /// - The specified calendar day does not exist (for example 2023-04-31).
    /// - The value for `month` or `day` is invalid.
    /// - `year` is out of range for `NaiveDate`.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::NaiveDate;
    ///
    /// let from_ymd_opt = NaiveDate::from_ymd_opt;
    ///
    /// assert!(from_ymd_opt(2015, 3, 14).is_some());
    /// assert!(from_ymd_opt(2015, 0, 14).is_none());
    /// assert!(from_ymd_opt(2015, 2, 29).is_none());
    /// assert!(from_ymd_opt(-4, 2, 29).is_some()); // 5 BCE is a leap year
    /// assert!(from_ymd_opt(400000, 1, 1).is_none());
    /// assert!(from_ymd_opt(-400000, 1, 1).is_none());
    /// ```
    fn from_ymd_opt(year: u32, month: u32, day: u32) -> Option<Date> {
        let flags = YearFlagsTrait::from_year(year);

        if let Option::Some(mdf) = MdfTrait::new(month, day, flags) {
            Self::from_mdf(year, mdf)
        } else {
            Option::None
        }
    }

    /// Makes a new `NaiveDate` from the [ordinal date](#ordinal-date)
    /// (year and day of the year).
    ///
    /// # Errors
    ///
    /// Returns `None` if:
    /// - The specified ordinal day does not exist (for example 2023-366).
    /// - The value for `ordinal` is invalid (for example: `0`, `400`).
    /// - `year` is out of range for `NaiveDate`.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::NaiveDate;
    ///
    /// let from_yo_opt = NaiveDate::from_yo_opt;
    ///
    /// assert!(from_yo_opt(2015, 100).is_some());
    /// assert!(from_yo_opt(2015, 0).is_none());
    /// assert!(from_yo_opt(2015, 365).is_some());
    /// assert!(from_yo_opt(2015, 366).is_none());
    /// assert!(from_yo_opt(-4, 366).is_some()); // 5 BCE is a leap year
    /// assert!(from_yo_opt(400000, 1).is_none());
    /// assert!(from_yo_opt(-400000, 1).is_none());
    /// ```
    fn from_yo_opt(year: u32, ordinal: u32) -> Option<Date> {
        let flags = YearFlagsTrait::from_year(year);
        Self::from_ordinal_and_flags(year, ordinal, flags)
    }

    /// Returns the packed month-day-flags.
    fn mdf(self: @Date) -> Mdf {
        let ol = (self.yof().try_into().unwrap() & OL_MASK) / TWO_POW_3;
        MdfTrait::from_ol(ol.try_into().unwrap(), self.year_flags())
    }

    /// Makes a new `NaiveDate` with the packed month-day-flags changed.
    ///
    /// Returns `None` when the resulting `NaiveDate` would be invalid.
    fn with_mdf(self: @Date, mdf: Mdf) -> Option<Date> {
        // debug_assert!(self.year_flags().0 == mdf.year_flags().0);
        match mdf.ordinal() {
            Option::Some(ordinal) => {
                Option::Some(
                    Self::from_yof((self.yof() & NOT_ORDINAL_MASK) | (ordinal * TWO_POW_4)),
                )
            },
            Option::None => Option::None // Non-existing date
        }
    }

    /// Makes a new `NaiveDate` for the next calendar date.
    ///
    /// # Errors
    ///
    /// Returns `None` when `self` is the last representable date.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::NaiveDate;
    ///
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2015, 6, 3).unwrap().succ_opt(),
    ///     Some(NaiveDate::from_ymd_opt(2015, 6, 4).unwrap())
    /// );
    /// assert_eq!(NaiveDate::MAX.succ_opt(), None);
    /// ```
    fn succ_opt(self: @Date) -> Option<Date> {
        let new_ol = (self.yof() & OL_MASK) + (1 * TWO_POW_4);
        match new_ol <= MAX_OL {
            true => Option::Some(Self::from_yof(self.yof() & NOT_OL_MASK | new_ol)),
            false => Self::from_yo_opt(self.year() + 1, 1),
        }
    }

    /// Makes a new `NaiveDate` for the previous calendar date.
    ///
    /// # Errors
    ///
    /// Returns `None` when `self` is the first representable date.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::NaiveDate;
    ///
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2015, 6, 3).unwrap().pred_opt(),
    ///     Some(NaiveDate::from_ymd_opt(2015, 6, 2).unwrap())
    /// );
    /// assert_eq!(NaiveDate::MIN.pred_opt(), None);
    /// ```
    fn pred_opt(self: @Date) -> Option<Date> {
        let new_shifted_ordinal = (self.yof() & ORDINAL_MASK) - (1 * TWO_POW_4);
        match new_shifted_ordinal > 0 {
            true => Option::Some(
                Self::from_yof(self.yof() & NOT_ORDINAL_MASK | new_shifted_ordinal),
            ),
            false => {
                if self.year() == 0 {
                    return Option::None;
                }
                Self::from_ymd_opt(self.year() - 1, 12, 31)
            },
        }
    }

    /// Returns `true` if this is a leap year.
    ///
    /// ```
    /// # use chrono::NaiveDate;
    /// assert_eq!(NaiveDate::from_ymd_opt(2000, 1, 1).unwrap().leap_year(), true);
    /// assert_eq!(NaiveDate::from_ymd_opt(2001, 1, 1).unwrap().leap_year(), false);
    /// assert_eq!(NaiveDate::from_ymd_opt(2002, 1, 1).unwrap().leap_year(), false);
    /// assert_eq!(NaiveDate::from_ymd_opt(2003, 1, 1).unwrap().leap_year(), false);
    /// assert_eq!(NaiveDate::from_ymd_opt(2004, 1, 1).unwrap().leap_year(), true);
    /// assert_eq!(NaiveDate::from_ymd_opt(2100, 1, 1).unwrap().leap_year(), false);
    /// ```
    fn leap_year(self: @Date) -> bool {
        self.yof() & LEAP_YEAR_MASK == 0
    }

    // This duplicates `Datelike::year()`, because trait methods can't be const yet.
    fn year(self: @Date) -> u32 {
        self.yof() / TWO_POW_13
    }

    /// Returns the day of year starting from 1.
    // This duplicates `Datelike::ordinal()`, because trait methods can't be const yet.
    fn ordinal(self: @Date) -> u32 {
        ((self.yof() & ORDINAL_MASK) / TWO_POW_4)
    }

    // This duplicates `Datelike::month()`, because trait methods can't be const yet.
    fn month(self: @Date) -> u32 {
        self.mdf().month()
    }

    // This duplicates `Datelike::day()`, because trait methods can't be const yet.
    fn day(self: @Date) -> u32 {
        self.mdf().day()
    }

    fn year_flags(self: @Date) -> YearFlags {
        let flags = self.yof() & YEAR_FLAGS_MASK;
        YearFlags { flags: flags.try_into().unwrap() }
    }

    /// Get the raw year-ordinal-flags `i32`.
    fn yof(self: @Date) -> u32 {
        *self.yof
    }

    /// Create a new `NaiveDate` from a raw year-ordinal-flags `i32`.
    ///
    /// In a valid value an ordinal is never `0`, and neither are the year flags. This method
    /// doesn't do any validation in release builds.
    fn from_yof(yof: u32) -> Date {
        // The following are the invariants our ordinal and flags should uphold for a valid
        // `NaiveDate`.
        // debug_assert!(((yof & OL_MASK) >> 3) > 1);
        // debug_assert!(((yof & OL_MASK) >> 3) <= MAX_OL);
        // debug_assert!((yof & 0b111) != 000);
        Date { yof }
    }

    /// Add a duration in [`Months`] to the date
    ///
    /// Uses the last day of the month if the day does not exist in the resulting month.
    ///
    /// # Errors
    ///
    /// Returns `None` if the resulting date would be out of range.
    ///
    /// # Example
    ///
    /// ```
    /// # use chrono::{NaiveDate, Months};
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2022, 2, 20).unwrap().checked_add_months(Months::new(6)),
    ///     Some(NaiveDate::from_ymd_opt(2022, 8, 20).unwrap())
    /// );
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2022, 7, 31).unwrap().checked_add_months(Months::new(2)),
    ///     Some(NaiveDate::from_ymd_opt(2022, 9, 30).unwrap())
    /// );
    /// ```
    fn checked_add_months(self: @Date, months: Months) -> Option<Date> {
        let months_u32 = months.as_u32();
        if months_u32 == 0 {
            return Option::Some(*self);
        }

        match months_u32 <= Bounded::<i32>::MAX.try_into().unwrap() {
            true => self.diff_months(months_u32.try_into().unwrap()),
            false => Option::None,
        }
    }

    /// Subtract a duration in [`Months`] from the date
    ///
    /// Uses the last day of the month if the day does not exist in the resulting month.
    ///
    /// # Errors
    ///
    /// Returns `None` if the resulting date would be out of range.
    ///
    /// # Example
    ///
    /// ```
    /// # use chrono::{NaiveDate, Months};
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2022, 2, 20).unwrap().checked_sub_months(Months::new(6)),
    ///     Some(NaiveDate::from_ymd_opt(2021, 8, 20).unwrap())
    /// );
    ///
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2014, 1, 1)
    ///         .unwrap()
    ///         .checked_sub_months(Months::new(core::i32::MAX as u32 + 1)),
    ///     None
    /// );
    /// ```
    fn checked_sub_months(self: @Date, months: Months) -> Option<Date> {
        let months_u32 = months.as_u32();
        if months_u32 == 0 {
            return Option::Some(*self);
        }

        match months_u32 <= Bounded::<i32>::MAX.try_into().unwrap() {
            true => self.diff_months(-months_u32.try_into().unwrap()),
            false => Option::None,
        }
    }

    fn diff_months(self: @Date, months: i32) -> Option<Date> {
        let month_i32: i32 = self.month().try_into().unwrap();
        let months_opt = (self.year().try_into().unwrap() * 12 + month_i32 - 1).checked_add(months);
        if months_opt.is_none() {
            return Option::None;
        }
        let months = months_opt.unwrap();
        if months < 0 {
            return Option::None;
        }
        let year: u32 = months.try_into().unwrap() / 12;
        let months_rem_12 = rem_euclid(months, 12);
        let month: u32 = months_rem_12.try_into().unwrap() + 1;

        // Clamp original day in case new month is shorter
        let flags = YearFlagsTrait::from_year(year);
        let feb_days = if flags.ndays() == 366 {
            29
        } else {
            28
        };
        let days: [u32; 12] = [31, feb_days, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        let day_max = *days.span()[(month - 1)];
        let mut day = self.day();
        if day > day_max {
            day = day_max;
        };
        Self::from_ymd_opt(year, month, day)
    }

    /// Add a duration in [`Days`] to the date
    ///
    /// # Errors
    ///
    /// Returns `None` if the resulting date would be out of range.
    ///
    /// # Example
    ///
    /// ```
    /// # use chrono::{NaiveDate, Days};
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2022, 2, 20).unwrap().checked_add_days(Days::new(9)),
    ///     Some(NaiveDate::from_ymd_opt(2022, 3, 1).unwrap())
    /// );
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2022, 7, 31).unwrap().checked_add_days(Days::new(2)),
    ///     Some(NaiveDate::from_ymd_opt(2022, 8, 2).unwrap())
    /// );
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2022, 7,
    ///     31).unwrap().checked_add_days(Days::new(1000000000000)), None
    /// );
    /// ```
    fn checked_add_days(self: @Date, days: Days) -> Option<Date> {
        match days.num <= Bounded::<i32>::MAX.try_into().unwrap() {
            true => self.add_days(days.num.try_into().unwrap()),
            false => Option::None,
        }
    }

    /// Subtract a duration in [`Days`] from the date
    ///
    /// # Errors
    ///
    /// Returns `None` if the resulting date would be out of range.
    ///
    /// # Example
    ///
    /// ```
    /// # use chrono::{NaiveDate, Days};
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2022, 2, 20).unwrap().checked_sub_days(Days::new(6)),
    ///     Some(NaiveDate::from_ymd_opt(2022, 2, 14).unwrap())
    /// );
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2022, 2,
    ///     20).unwrap().checked_sub_days(Days::new(1000000000000)), None
    /// );
    /// ```
    fn checked_sub_days(self: @Date, days: Days) -> Option<Date> {
        match days.num <= Bounded::<i32>::MAX.try_into().unwrap() {
            true => {
                let days_i32 = days.num.try_into().unwrap();
                self.add_days(-days_i32)
            },
            false => Option::None,
        }
    }

    /// Add a duration of `i32` days to the date.
    fn add_days(self: @Date, days: i32) -> Option<Date> {
        // Fast path if the result is within the same year.
        // Also `DateTime::checked_(add|sub)_days` relies on this path, because if the value remains
        // within the year it doesn't do a check if the year is in range.
        // This way `DateTime:checked_(add|sub)_days(Days::new(0))` can be a no-op on dates were the
        // local datetime is beyond `NaiveDate::{MIN, MAX}.
        let ordinal_i32: i32 = self.ordinal().try_into().unwrap();
        if let Option::Some(ordinal) = ordinal_i32.checked_add(days) {
            let leap_year = if self.leap_year() {
                1
            } else {
                0
            };
            if ordinal > 0 && ordinal <= 365 + leap_year {
                let year_and_flags = self.yof() & NOT_ORDINAL_MASK;
                return Option::Some(
                    Self::from_yof(year_and_flags | (ordinal.try_into().unwrap() * TWO_POW_4)),
                );
            }
        }
        // do the full check
        let year = self.year();
        let (mut year_div_400, year_mod_400) = div_mod_floor(year.try_into().unwrap(), 400);
        let cycle = yo_to_cycle(year_mod_400.try_into().unwrap(), self.ordinal());
        let cycle_plus_days = cycle.try_into().unwrap().checked_add(days)?;
        let (cycle_div_400y, cycle_rem) = div_mod_floor(cycle_plus_days, 146_097);
        year_div_400 += cycle_div_400y;

        let (year_mod_400, ordinal) = cycle_to_yo(cycle_rem.try_into().unwrap());
        let flags = YearFlagsTrait::from_year_mod_400(year_mod_400);
        Self::from_ordinal_and_flags(
            year_div_400.try_into().unwrap() * 400 + year_mod_400, ordinal, flags,
        )
    }

    /// Makes a new `NaiveDate` with the year number changed, while keeping the same month and day.
    ///
    /// This method assumes you want to work on the date as a year-month-day value. Don't use it if
    /// you want the ordinal to stay the same after changing the year, of if you want the week and
    /// weekday values to stay the same.
    ///
    /// # Errors
    ///
    /// Returns `None` if:
    /// - The resulting date does not exist (February 29 in a non-leap year).
    /// - The year is out of range for a `NaiveDate`.
    ///
    /// # Examples
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate};
    ///
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().with_year(2016),
    ///     Some(NaiveDate::from_ymd_opt(2016, 9, 8).unwrap())
    /// );
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().with_year(-308),
    ///     Some(NaiveDate::from_ymd_opt(-308, 9, 8).unwrap())
    /// );
    /// ```
    ///
    /// A leap day (February 29) is a case where this method can return `None`.
    ///
    /// ```
    /// # use chrono::{NaiveDate, Datelike};
    /// assert!(NaiveDate::from_ymd_opt(2016, 2, 29).unwrap().with_year(2015).is_none());
    /// assert!(NaiveDate::from_ymd_opt(2016, 2, 29).unwrap().with_year(2020).is_some());
    /// ```
    ///
    /// Don't use `with_year` if you want the ordinal date to stay the same:
    ///
    /// ```
    /// # use chrono::{Datelike, NaiveDate};
    /// assert_ne!(
    ///     NaiveDate::from_yo_opt(2020, 100).unwrap().with_year(2023).unwrap(),
    ///     NaiveDate::from_yo_opt(2023, 100).unwrap() // result is 2023-101
    /// );
    /// ```
    fn with_year(self: @Date, year: u32) -> Option<Date> {
        // we need to operate with `mdf` since we should keep the month and day number as is
        let mdf = self.mdf();

        // adjust the flags as needed
        let flags = YearFlagsTrait::from_year(year);
        let mdf = mdf.with_flags(flags);

        Self::from_mdf(year, mdf)
    }

    /// Makes a new `NaiveDate` with the month number (starting from 1) changed.
    ///
    /// # Errors
    ///
    /// Returns `None` if:
    /// - The resulting date does not exist (for example `month(4)` when day of the month is 31).
    /// - The value for `month` is invalid.
    ///
    /// # Examples
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate};
    ///
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().with_month(10),
    ///     Some(NaiveDate::from_ymd_opt(2015, 10, 8).unwrap())
    /// );
    /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().with_month(13), None); // No month
    /// 13 assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 30).unwrap().with_month(2), None); // No Feb
    /// 30 ```
    ///
    /// Don't combine multiple `Datelike::with_*` methods. The intermediate value may not exist.
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate};
    ///
    /// fn with_year_month(date: NaiveDate, year: i32, month: u32) -> Option<NaiveDate> {
    ///     date.with_year(year)?.with_month(month)
    /// }
    /// let d = NaiveDate::from_ymd_opt(2020, 2, 29).unwrap();
    /// assert!(with_year_month(d, 2019, 1).is_none()); // fails because of invalid intermediate
    /// value
    ///
    /// // Correct version:
    /// fn with_year_month_fixed(date: NaiveDate, year: i32, month: u32) -> Option<NaiveDate> {
    ///     NaiveDate::from_ymd_opt(year, month, date.day())
    /// }
    /// let d = NaiveDate::from_ymd_opt(2020, 2, 29).unwrap();
    /// assert_eq!(with_year_month_fixed(d, 2019, 1), NaiveDate::from_ymd_opt(2019, 1, 29));
    /// ```
    fn with_month(self: @Date, month: u32) -> Option<Date> {
        self.with_mdf(self.mdf().with_month(month)?)
    }

    /// Makes a new `NaiveDate` with the day of month (starting from 1) changed.
    ///
    /// # Errors
    ///
    /// Returns `None` if:
    /// - The resulting date does not exist (for example `day(31)` in April).
    /// - The value for `day` is invalid.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate};
    ///
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().with_day(30),
    ///     Some(NaiveDate::from_ymd_opt(2015, 9, 30).unwrap())
    /// );
    /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().with_day(31), None);
    /// // no September 31
    /// ```
    fn with_day(self: @Date, day: u32) -> Option<Date> {
        self.with_mdf(self.mdf().with_day(day)?)
    }

    /// Makes a new `NaiveDate` with the day of year (starting from 1) changed.
    ///
    /// # Errors
    ///
    /// Returns `None` if:
    /// - The resulting date does not exist (`with_ordinal(366)` in a non-leap year).
    /// - The value for `ordinal` is invalid.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, Datelike};
    ///
    /// assert_eq!(NaiveDate::from_ymd_opt(2015, 1, 1).unwrap().with_ordinal(60),
    ///            Some(NaiveDate::from_ymd_opt(2015, 3, 1).unwrap()));
    /// assert_eq!(NaiveDate::from_ymd_opt(2015, 1, 1).unwrap().with_ordinal(366),
    ///            None); // 2015 had only 365 days
    ///
    /// assert_eq!(NaiveDate::from_ymd_opt(2016, 1, 1).unwrap().with_ordinal(60),
    ///            Some(NaiveDate::from_ymd_opt(2016, 2, 29).unwrap()));
    /// assert_eq!(NaiveDate::from_ymd_opt(2016, 1, 1).unwrap().with_ordinal(366),
    ///            Some(NaiveDate::from_ymd_opt(2016, 12, 31).unwrap()));
    /// ```
    fn with_ordinal(self: @Date, ordinal: u32) -> Option<Date> {
        if ordinal == 0 || ordinal > 366 {
            return Option::None;
        }
        let yof = (self.yof() & NOT_ORDINAL_MASK) | (ordinal * TWO_POW_4);
        match yof & OL_MASK <= MAX_OL {
            true => Option::Some(Self::from_yof(yof)),
            false => Option::None // Does not exist: Ordinal 366 in a common year.
        }
    }

    /// The minimum possible `NaiveDate` (January 1, 262144 BCE).
    const MIN: Date = Date { yof: (MIN_YEAR * TWO_POW_13) | (1 * TWO_POW_4) | 0o12 };
    /// The maximum possible `NaiveDate` (December 31, 262142 CE).
    const MAX: Date = Date { yof: (MAX_YEAR * TWO_POW_13) | (365 * TWO_POW_4) | 0o16 };
}

/// The `Debug` output of the naive date `d` is the same as
/// [`d.format("%Y-%m-%d")`](crate::format::strftime).
///
/// The string printed can be readily parsed via the `parse` method on `str`.
///
/// # Example
///
/// ```
/// use chrono::NaiveDate;
///
/// assert_eq!(format!("{:?}", NaiveDate::from_ymd_opt(2015, 9, 5).unwrap()), "2015-09-05");
/// assert_eq!(format!("{:?}", NaiveDate::from_ymd_opt(0, 1, 1).unwrap()), "0000-01-01");
/// assert_eq!(format!("{:?}", NaiveDate::from_ymd_opt(9999, 12, 31).unwrap()), "9999-12-31");
/// ```
///
/// ISO 8601 requires an explicit sign for years before 1 BCE or after 9999 CE.
///
/// ```
/// # use chrono::NaiveDate;
/// assert_eq!(format!("{:?}", NaiveDate::from_ymd_opt(-1, 1, 1).unwrap()), "-0001-01-01");
/// assert_eq!(format!("{:?}", NaiveDate::from_ymd_opt(10000, 12, 31).unwrap()), "+10000-12-31");
/// ```
impl DateDebug of Debug<Date> {
    fn fmt(self: @Date, ref f: Formatter) -> Result<(), Error> {
        let year = self.year();
        let mdf = self.mdf();
        if year >= 0 && year <= 9999 {
            write_hundreds(ref f, (year / 100).try_into().unwrap())?;
            write_hundreds(ref f, (year % 100).try_into().unwrap())?;
        } else {
            let sign = if year > 0 {
                '+'
            } else {
                '-'
            };
            f.buffer.append_byte(sign);
            write!(f, "{year}")?;
        }
        f.buffer.append_byte('-');
        write_hundreds(ref f, mdf.month().try_into().unwrap())?;
        f.buffer.append_byte('-');
        write_hundreds(ref f, mdf.day().try_into().unwrap())
    }
}

/// The `Display` output of the naive date `d` is the same as
/// [`d.format("%Y-%m-%d")`](crate::format::strftime).
///
/// The string printed can be readily parsed via the `parse` method on `str`.
///
/// # Example
///
/// ```
/// use chrono::NaiveDate;
///
/// assert_eq!(format!("{}", NaiveDate::from_ymd_opt(2015, 9, 5).unwrap()), "2015-09-05");
/// assert_eq!(format!("{}", NaiveDate::from_ymd_opt(0, 1, 1).unwrap()), "0000-01-01");
/// assert_eq!(format!("{}", NaiveDate::from_ymd_opt(9999, 12, 31).unwrap()), "9999-12-31");
/// ```
///
/// ISO 8601 requires an explicit sign for years before 1 BCE or after 9999 CE.
///
/// ```
/// # use chrono::NaiveDate;
/// assert_eq!(format!("{}", NaiveDate::from_ymd_opt(-1, 1, 1).unwrap()), "-0001-01-01");
/// assert_eq!(format!("{}", NaiveDate::from_ymd_opt(10000, 12, 31).unwrap()), "+10000-12-31");
/// ```
impl DateDisplay of Display<Date> {
    fn fmt(self: @Date, ref f: Formatter) -> Result<(), Error> {
        Debug::fmt(self, ref f)
    }
}

/// The default value for a NaiveDate is 1st of January 1970.
///
/// # Example
///
/// ```rust
/// use chrono::NaiveDate;
///
/// let default_date = NaiveDate::default();
/// assert_eq!(default_date, NaiveDate::from_ymd_opt(1970, 1, 1).unwrap());
/// ```
impl DateDefault of Default<Date> {
    fn default() -> Date {
        DateTrait::from_ymd_opt(1970, 1, 1).unwrap()
    }
}

fn cycle_to_yo(cycle: u32) -> (u32, u32) {
    let mut year_mod_400 = cycle / 365;
    let mut ordinal0 = cycle % 365;
    let delta = (*YEAR_DELTAS.span()[year_mod_400]).into();
    if ordinal0 < delta {
        year_mod_400 -= 1;
        ordinal0 += 365 - (*YEAR_DELTAS.span()[year_mod_400]).into();
    } else {
        ordinal0 -= delta;
    }
    (year_mod_400, ordinal0 + 1)
}

fn yo_to_cycle(year_mod_400: u32, ordinal: u32) -> u32 {
    let year_delta = (*YEAR_DELTAS.span()[year_mod_400]).into();
    year_mod_400 * 365 + year_delta + ordinal - 1
}

fn div_mod_floor(val: i32, div: i32) -> (i32, i32) {
    (div_euclid(val, div), rem_euclid(val, div))
}

/// MAX_YEAR is one year less than the type is capable of representing. Internally we may sometimes
/// use the headroom, notably to handle cases where the offset of a `DateTime` constructed with
/// `NaiveDate::MAX` pushes it beyond the valid, representable range.
// const MAX_YEAR: i32 = (Bounded::<i32>::MAX / 8192) - 1;
pub const MAX_YEAR: u32 = 262142;

/// MIN_YEAR is one year more than the type is capable of representing. Internally we may sometimes
/// use the headroom, notably to handle cases where the offset of a `DateTime` constructed with
/// `NaiveDate::MIN` pushes it beyond the valid, representable range.
// const MIN_YEAR: i32 = (Bounded::<i32>::MIN / 8192) + 1;
pub const MIN_YEAR: u32 = 0;

const ORDINAL_MASK: u32 = 0b1_1111_1111_0000;
const NOT_ORDINAL_MASK: u32 = 0b1111_1111_1111_1111_1110_0000_0000_1111;

const LEAP_YEAR_MASK: u32 = 0b1000;

// OL: ordinal and leap year flag.
// With only these parts of the date an ordinal 366 in a common year would be encoded as
// `((366 << 1) | 1) << 3`, and in a leap year as `((366 << 1) | 0) << 3`, which is less.
// This allows for efficiently checking the ordinal exists depending on whether this is a leap year.
const OL_MASK: u32 = 0b1_1111_1111_1000;
const NOT_OL_MASK: u32 = 0b1111_1111_1111_1111_1110_0000_0000_0111;
const MAX_OL: u32 = 366 * TWO_POW_4;

// Weekday of the last day in the preceding year.
// Allows for quick day of week calculation from the 1-based ordinal.
const WEEKDAY_FLAGS_MASK: i32 = 0b111;

const YEAR_FLAGS_MASK: u32 = 0b1111;

const YEAR_DELTAS: [u8; 401] = [
    0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8,
    8, 9, 9, 9, 9, 10, 10, 10, 10, 11, 11, 11, 11, 12, 12, 12, 12, 13, 13, 13, 13, 14, 14, 14, 14,
    15, 15, 15, 15, 16, 16, 16, 16, 17, 17, 17, 17, 18, 18, 18, 18, 19, 19, 19, 19, 20, 20, 20, 20,
    21, 21, 21, 21, 22, 22, 22, 22, 23, 23, 23, 23, 24, 24, 24, 24, 25, 25, 25, // 100
    25, 25, 25,
    25, 25, 26, 26, 26, 26, 27, 27, 27, 27, 28, 28, 28, 28, 29, 29, 29, 29, 30, 30, 30, 30, 31, 31,
    31, 31, 32, 32, 32, 32, 33, 33, 33, 33, 34, 34, 34, 34, 35, 35, 35, 35, 36, 36, 36, 36, 37, 37,
    37, 37, 38, 38, 38, 38, 39, 39, 39, 39, 40, 40, 40, 40, 41, 41, 41, 41, 42, 42, 42, 42, 43, 43,
    43, 43, 44, 44, 44, 44, 45, 45, 45, 45, 46, 46, 46, 46, 47, 47, 47, 47, 48, 48, 48, 48, 49, 49,
    49, // 200
    49, 49, 49, 49, 49, 50, 50, 50, 50, 51, 51, 51, 51, 52, 52, 52, 52, 53, 53, 53, 53,
    54, 54, 54, 54, 55, 55, 55, 55, 56, 56, 56, 56, 57, 57, 57, 57, 58, 58, 58, 58, 59, 59, 59, 59,
    60, 60, 60, 60, 61, 61, 61, 61, 62, 62, 62, 62, 63, 63, 63, 63, 64, 64, 64, 64, 65, 65, 65, 65,
    66, 66, 66, 66, 67, 67, 67, 67, 68, 68, 68, 68, 69, 69, 69, 69, 70, 70, 70, 70, 71, 71, 71, 71,
    72, 72, 72, 72, 73, 73, 73, // 300
    73, 73, 73, 73, 73, 74, 74, 74, 74, 75, 75, 75, 75, 76, 76,
    76, 76, 77, 77, 77, 77, 78, 78, 78, 78, 79, 79, 79, 79, 80, 80, 80, 80, 81, 81, 81, 81, 82, 82,
    82, 82, 83, 83, 83, 83, 84, 84, 84, 84, 85, 85, 85, 85, 86, 86, 86, 86, 87, 87, 87, 87, 88, 88,
    88, 88, 89, 89, 89, 89, 90, 90, 90, 90, 91, 91, 91, 91, 92, 92, 92, 92, 93, 93, 93, 93, 94, 94,
    94, 94, 95, 95, 95, 95, 96, 96, 96, 96, 97, 97, 97, 97 // 400+1
];
