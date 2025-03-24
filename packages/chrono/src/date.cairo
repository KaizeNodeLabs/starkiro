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

use core::fmt::{Debug, Display, Error, Formatter};
use core::num::traits::{Bounded, CheckedAdd, Pow};
use core::ops::RangeInclusiveTrait;
use super::datetime::{DateTime, DateTimeTrait};
use super::days::Days;
use super::format::formatting::write_hundreds;
use super::internals::{Mdf, MdfTrait, YearFlags, YearFlagsTrait};
use super::isoweek::{IsoWeek, IsoWeekTrait};
use super::months::{Months, MonthsTrait};
use super::time::{Time, TimeTrait};
use super::time_delta::{TimeDelta, TimeDeltaTrait};
use super::traits::Datelike;
use super::utils::{div_euclid, rem_euclid, u32_shl, u32_shr};
use super::week::{Week, WeekTrait};
use super::weekday::{Weekday, WeekdayTrait};

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
#[derive(Clone, Copy, PartialEq, Drop, Serde, starknet::Store)]
pub struct Date {
    pub(crate) yof: u32 // (year << 13) | of
}

#[generate_trait]
pub impl DateImpl of DateTrait {
    fn weeks_from(self: @Date, day: Weekday) -> i32 {
        (self.ordinal().try_into().unwrap()
            - self.weekday().days_since(day).try_into().unwrap()
            + 6)
            / 7
    }

    /// Makes a new `NaiveDate` from year, ordinal and flags.
    /// Does not check whether the flags are correct for the provided year.
    fn from_ordinal_and_flags(year: u32, ordinal: u32, flags: YearFlags) -> Option<Date> {
        if year < MIN_YEAR || year > MAX_YEAR {
            return None; // Out-of-range
        }
        if ordinal == 0 || ordinal > 366 {
            return None; // Invalid
        }
        // debug_assert!(YearFlags::from_year(year).0 == flags.0);
        let yof = u32_shl(year, 13) | u32_shl(ordinal, 4) | flags.flags.into();
        match yof & OL_MASK <= MAX_OL {
            true => Some(Self::from_yof(yof)),
            false => None // Does not exist: Ordinal 366 in a common year.
        }
    }

    /// Makes a new `NaiveDate` from year and packed month-day-flags.
    /// Does not check whether the flags are correct for the provided year.
    fn from_mdf(year: u32, mdf: Mdf) -> Option<Date> {
        if year < MIN_YEAR || year > MAX_YEAR {
            return None; // Out-of-range
        }
        Some(Self::from_yof(u32_shl(year, 13) | mdf.ordinal_and_flags()?))
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
        let flags = YearFlagsTrait::from_year(year.try_into().unwrap());

        if let Some(mdf) = MdfTrait::new(month, day, flags) {
            Self::from_mdf(year, mdf)
        } else {
            None
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
        let flags = YearFlagsTrait::from_year(year.try_into().unwrap());
        Self::from_ordinal_and_flags(year, ordinal, flags)
    }

    /// Makes a new `NaiveDate` from the [ISO week date](#week-date)
    /// (year, week number and day of the week).
    /// The resulting `NaiveDate` may have a different year from the input year.
    ///
    /// # Errors
    ///
    /// Returns `None` if:
    /// - The specified week does not exist in that year (for example 2023 week 53).
    /// - The value for `week` is invalid (for example: `0`, `60`).
    /// - If the resulting date is out of range for `NaiveDate`.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, Weekday};
    ///
    /// let from_ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
    /// let from_isoywd_opt = NaiveDate::from_isoywd_opt;
    ///
    /// assert_eq!(from_isoywd_opt(2015, 0, Weekday::Sun), None);
    /// assert_eq!(from_isoywd_opt(2015, 10, Weekday::Sun), Some(from_ymd(2015, 3, 8)));
    /// assert_eq!(from_isoywd_opt(2015, 30, Weekday::Mon), Some(from_ymd(2015, 7, 20)));
    /// assert_eq!(from_isoywd_opt(2015, 60, Weekday::Mon), None);
    ///
    /// assert_eq!(from_isoywd_opt(400000, 10, Weekday::Fri), None);
    /// assert_eq!(from_isoywd_opt(-400000, 10, Weekday::Sat), None);
    /// ```
    ///
    /// The year number of ISO week date may differ from that of the calendar date.
    ///
    /// ```
    /// # use chrono::{NaiveDate, Weekday};
    /// # let from_ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
    /// # let from_isoywd_opt = NaiveDate::from_isoywd_opt;
    /// //           Mo Tu We Th Fr Sa Su
    /// // 2014-W52  22 23 24 25 26 27 28    has 4+ days of new year,
    /// // 2015-W01  29 30 31  1  2  3  4 <- so this is the first week
    /// assert_eq!(from_isoywd_opt(2014, 52, Weekday::Sun), Some(from_ymd(2014, 12, 28)));
    /// assert_eq!(from_isoywd_opt(2014, 53, Weekday::Mon), None);
    /// assert_eq!(from_isoywd_opt(2015, 1, Weekday::Mon), Some(from_ymd(2014, 12, 29)));
    ///
    /// // 2015-W52  21 22 23 24 25 26 27    has 4+ days of old year,
    /// // 2015-W53  28 29 30 31  1  2  3 <- so this is the last week
    /// // 2016-W01   4  5  6  7  8  9 10
    /// assert_eq!(from_isoywd_opt(2015, 52, Weekday::Sun), Some(from_ymd(2015, 12, 27)));
    /// assert_eq!(from_isoywd_opt(2015, 53, Weekday::Sun), Some(from_ymd(2016, 1, 3)));
    /// assert_eq!(from_isoywd_opt(2015, 54, Weekday::Mon), None);
    /// assert_eq!(from_isoywd_opt(2016, 1, Weekday::Mon), Some(from_ymd(2016, 1, 4)));
    /// ```
    fn from_isoywd_opt(year: u32, week: u32, weekday: Weekday) -> Option<Date> {
        let flags = YearFlagsTrait::from_year(year.try_into().unwrap());
        let nweeks = flags.nisoweeks();
        if week == 0 || week > nweeks {
            return None;
        }
        // ordinal = week ordinal - delta
        let weekord = week * 7 + weekday.into();
        let delta = flags.isoweek_delta();
        let (year, ordinal, flags) = if weekord <= delta {
            // ordinal < 1, previous year
            let prevflags = YearFlagsTrait::from_year(year.try_into().unwrap() - 1);
            (year - 1, weekord + prevflags.ndays() - delta, prevflags)
        } else {
            let ordinal = weekord - delta;
            let ndays = flags.ndays();
            if ordinal <= ndays {
                // this year
                (year, ordinal, flags)
            } else {
                // ordinal > ndays, next year
                let nextflags = YearFlagsTrait::from_year(year.try_into().unwrap() + 1);
                (year + 1, ordinal - ndays, nextflags)
            }
        };
        Self::from_ordinal_and_flags(year, ordinal, flags)
    }

    /// Makes a new `NaiveDate` from a day's number in the proleptic Gregorian calendar, with
    /// January 1, 1 being day 1.
    ///
    /// # Errors
    ///
    /// Returns `None` if the date is out of range.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::NaiveDate;
    ///
    /// let from_ndays_opt = NaiveDate::from_num_days_from_ce_opt;
    /// let from_ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
    ///
    /// assert_eq!(from_ndays_opt(730_000), Some(from_ymd(1999, 9, 3)));
    /// assert_eq!(from_ndays_opt(1), Some(from_ymd(1, 1, 1)));
    /// assert_eq!(from_ndays_opt(0), Some(from_ymd(0, 12, 31)));
    /// assert_eq!(from_ndays_opt(-1), Some(from_ymd(0, 12, 30)));
    /// assert_eq!(from_ndays_opt(100_000_000), None);
    /// assert_eq!(from_ndays_opt(-100_000_000), None);
    /// ```
    fn from_num_days_from_ce_opt(days: i32) -> Option<Date> {
        let days = days.checked_add(365)?; // make December 31, 1 BCE equal to day 0
        let year_div_400 = div_euclid(days, 146_097)?;
        if year_div_400 < 0 {
            return None;
        }
        let cycle = rem_euclid(days, 146_097);
        let (year_mod_400, ordinal) = cycle_to_yo(cycle.try_into().unwrap());
        let flags = YearFlagsTrait::from_year_mod_400(year_mod_400);
        Self::from_ordinal_and_flags(
            year_div_400.try_into().unwrap() * 400 + year_mod_400, ordinal, flags,
        )
    }

    /// Makes a new `NaiveDate` by counting the number of occurrences of a particular day-of-week
    /// since the beginning of the given month. For instance, if you want the 2nd Friday of March
    /// 2017, you would use `NaiveDate::from_weekday_of_month(2017, 3, Weekday::Fri, 2)`.
    ///
    /// `n` is 1-indexed.
    ///
    /// # Errors
    ///
    /// Returns `None` if:
    /// - The specified day does not exist in that month (for example the 5th Monday of Apr. 2023).
    /// - The value for `month` or `n` is invalid.
    /// - `year` is out of range for `NaiveDate`.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, Weekday};
    /// assert_eq!(
    ///     NaiveDate::from_weekday_of_month_opt(2017, 3, Weekday::Fri, 2),
    ///     NaiveDate::from_ymd_opt(2017, 3, 10)
    /// )
    /// ```
    fn from_weekday_of_month_opt(year: u32, month: u32, weekday: Weekday, n: u8) -> Option<Date> {
        if n == 0 {
            return None;
        }
        let first = Self::from_ymd_opt(year, month, 1)?.weekday();
        let first_to_dow = (7 + weekday.number_from_monday() - first.number_from_monday()) % 7;
        let day = (n.into() - 1) * 7 + first_to_dow + 1;
        Self::from_ymd_opt(year, month, day)
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
            return Some(*self);
        }

        match months_u32 <= Bounded::<i32>::MAX.try_into().unwrap() {
            true => self.diff_months(months_u32.try_into().unwrap()),
            false => None,
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
            return Some(*self);
        }

        match months_u32 <= Bounded::<i32>::MAX.try_into().unwrap() {
            true => self.diff_months(-months_u32.try_into().unwrap()),
            false => None,
        }
    }

    fn diff_months(self: @Date, months: i32) -> Option<Date> {
        let month_i32: i32 = self.month().try_into().unwrap();
        let months_opt = (self.year().try_into().unwrap() * 12 + month_i32 - 1).checked_add(months);
        if months_opt.is_none() {
            return None;
        }
        let months = months_opt.unwrap();
        if months < 0 {
            return None;
        }
        let year: u32 = months.try_into().unwrap() / 12;
        let months_rem_12 = rem_euclid(months, 12);
        let month: u32 = months_rem_12.try_into().unwrap() + 1;

        // Clamp original day in case new month is shorter
        let flags = YearFlagsTrait::from_year(year.try_into().unwrap());
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
        }
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
            false => None,
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
            false => None,
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
        if let Some(ordinal) = ordinal_i32.checked_add(days) {
            let leap_year = if self.leap_year() {
                1
            } else {
                0
            };
            if ordinal > 0 && ordinal <= 365 + leap_year {
                let year_and_flags = self.yof() & NOT_ORDINAL_MASK;
                return Some(
                    Self::from_yof(year_and_flags | u32_shl(ordinal.try_into().unwrap(), 4)),
                );
            }
        }
        // do the full check
        let year = self.year();
        let (mut year_div_400, year_mod_400) = div_mod_floor(year.try_into().unwrap(), 400);
        let cycle: i32 = yo_to_cycle(year_mod_400.try_into().unwrap(), self.ordinal())
            .try_into()
            .unwrap();
        let cycle_plus_days = cycle.checked_add(days)?;
        let (cycle_div_400y, cycle_rem) = div_mod_floor(cycle_plus_days, 146_097);
        year_div_400 += cycle_div_400y;
        if year_div_400 < 0 {
            return None;
        }

        let (year_mod_400, ordinal) = cycle_to_yo(cycle_rem.try_into().unwrap());
        let flags = YearFlagsTrait::from_year_mod_400(year_mod_400);
        Self::from_ordinal_and_flags(
            year_div_400.try_into().unwrap() * 400 + year_mod_400, ordinal, flags,
        )
    }

    /// Makes a new `NaiveDateTime` from the current date and given `NaiveTime`.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, NaiveDateTime, NaiveTime};
    ///
    /// let d = NaiveDate::from_ymd_opt(2015, 6, 3).unwrap();
    /// let t = NaiveTime::from_hms_milli_opt(12, 34, 56, 789).unwrap();
    ///
    /// let dt: NaiveDateTime = d.and_time(t);
    /// assert_eq!(dt.date(), d);
    /// assert_eq!(dt.time(), t);
    /// ```
    #[inline]
    const fn and_time(self: @Date, time: Time) -> DateTime {
        DateTimeTrait::new(*self, time)
    }

    /// Makes a new `NaiveDateTime` from the current date, hour, minute and second.
    ///
    /// No [leap second](./struct.NaiveTime.html#leap-second-handling) is allowed here;
    /// use `NaiveDate::and_hms_*_opt` methods with a subsecond parameter instead.
    ///
    /// # Errors
    ///
    /// Returns `None` on invalid hour, minute and/or second.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::NaiveDate;
    ///
    /// let d = NaiveDate::from_ymd_opt(2015, 6, 3).unwrap();
    /// assert!(d.and_hms_opt(12, 34, 56).is_some());
    /// assert!(d.and_hms_opt(12, 34, 60).is_none()); // use `and_hms_milli_opt` instead
    /// assert!(d.and_hms_opt(12, 60, 56).is_none());
    /// assert!(d.and_hms_opt(24, 34, 56).is_none());
    /// ```
    #[inline]
    fn and_hms_opt(self: @Date, hour: u32, min: u32, sec: u32) -> Option<DateTime> {
        let time = TimeTrait::from_hms_opt(hour, min, sec)?;
        Some(self.and_time(time))
    }

    /// Returns the packed month-day-flags.
    #[inline]
    fn mdf(self: @Date) -> Mdf {
        let ol = u32_shr((self.yof() & OL_MASK), 3);
        MdfTrait::from_ol(ol.try_into().unwrap(), self.year_flags())
    }

    /// Makes a new `NaiveDate` with the packed month-day-flags changed.
    ///
    /// Returns `None` when the resulting `NaiveDate` would be invalid.
    #[inline]
    fn with_mdf(self: @Date, mdf: Mdf) -> Option<Date> {
        // debug_assert!(self.year_flags().0 == mdf.year_flags().0);
        match mdf.ordinal() {
            Some(ordinal) => {
                Some(Self::from_yof((self.yof() & NOT_ORDINAL_MASK) | u32_shl(ordinal, 4)))
            },
            None => None // Non-existing date
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
    #[inline]
    fn succ_opt(self: @Date) -> Option<Date> {
        let new_ol = (self.yof() & OL_MASK) + u32_shl(1, 4);
        match new_ol <= MAX_OL {
            true => Some(Self::from_yof(self.yof() & NOT_OL_MASK | new_ol)),
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
    #[inline]
    fn pred_opt(self: @Date) -> Option<Date> {
        let new_shifted_ordinal = (self.yof() & ORDINAL_MASK) - u32_shl(1, 4);
        match new_shifted_ordinal > 0 {
            true => Some(Self::from_yof(self.yof() & NOT_ORDINAL_MASK | new_shifted_ordinal)),
            false => {
                if self.year() == 0 {
                    return None;
                }
                Self::from_ymd_opt(self.year() - 1, 12, 31)
            },
        }
    }

    /// Adds the number of whole days in the given `TimeDelta` to the current date.
    ///
    /// # Errors
    ///
    /// Returns `None` if the resulting date would be out of range.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, TimeDelta};
    ///
    /// let d = NaiveDate::from_ymd_opt(2015, 9, 5).unwrap();
    /// assert_eq!(
    ///     d.checked_add_signed(TimeDelta::try_days(40).unwrap()),
    ///     Some(NaiveDate::from_ymd_opt(2015, 10, 15).unwrap())
    /// );
    /// assert_eq!(
    ///     d.checked_add_signed(TimeDelta::try_days(-40).unwrap()),
    ///     Some(NaiveDate::from_ymd_opt(2015, 7, 27).unwrap())
    /// );
    /// assert_eq!(d.checked_add_signed(TimeDelta::try_days(1_000_000_000).unwrap()), None);
    /// assert_eq!(d.checked_add_signed(TimeDelta::try_days(-1_000_000_000).unwrap()), None);
    /// assert_eq!(NaiveDate::MAX.checked_add_signed(TimeDelta::try_days(1).unwrap()), None);
    /// ```
    fn checked_add_signed(self: @Date, rhs: TimeDelta) -> Option<Date> {
        let days = rhs.num_days();
        if days < Bounded::<i32>::MIN.try_into().unwrap()
            || days > Bounded::<i32>::MAX.try_into().unwrap() {
            return None;
        }
        self.add_days(days.try_into().unwrap())
    }

    /// Subtracts the number of whole days in the given `TimeDelta` from the current date.
    ///
    /// # Errors
    ///
    /// Returns `None` if the resulting date would be out of range.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, TimeDelta};
    ///
    /// let d = NaiveDate::from_ymd_opt(2015, 9, 5).unwrap();
    /// assert_eq!(
    ///     d.checked_sub_signed(TimeDelta::try_days(40).unwrap()),
    ///     Some(NaiveDate::from_ymd_opt(2015, 7, 27).unwrap())
    /// );
    /// assert_eq!(
    ///     d.checked_sub_signed(TimeDelta::try_days(-40).unwrap()),
    ///     Some(NaiveDate::from_ymd_opt(2015, 10, 15).unwrap())
    /// );
    /// assert_eq!(d.checked_sub_signed(TimeDelta::try_days(1_000_000_000).unwrap()), None);
    /// assert_eq!(d.checked_sub_signed(TimeDelta::try_days(-1_000_000_000).unwrap()), None);
    /// assert_eq!(NaiveDate::MIN.checked_sub_signed(TimeDelta::try_days(1).unwrap()), None);
    /// ```
    fn checked_sub_signed(self: @Date, rhs: TimeDelta) -> Option<Date> {
        let days = -rhs.num_days();
        if days < Bounded::<i32>::MIN.try_into().unwrap()
            || days > Bounded::<i32>::MAX.try_into().unwrap() {
            return None;
        }
        self.add_days(days.try_into().unwrap())
    }

    /// Subtracts another `NaiveDate` from the current date.
    /// Returns a `TimeDelta` of integral numbers.
    ///
    /// This does not overflow or underflow at all,
    /// as all possible output fits in the range of `TimeDelta`.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, TimeDelta};
    ///
    /// let from_ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
    /// let since = NaiveDate::signed_duration_since;
    ///
    /// assert_eq!(since(from_ymd(2014, 1, 1), from_ymd(2014, 1, 1)), TimeDelta::zero());
    /// assert_eq!(
    ///     since(from_ymd(2014, 1, 1), from_ymd(2013, 12, 31)),
    ///     TimeDelta::try_days(1).unwrap()
    /// );
    /// assert_eq!(since(from_ymd(2014, 1, 1), from_ymd(2014, 1, 2)),
    /// TimeDelta::try_days(-1).unwrap());
    /// assert_eq!(
    ///     since(from_ymd(2014, 1, 1), from_ymd(2013, 9, 23)),
    ///     TimeDelta::try_days(100).unwrap()
    /// );
    /// assert_eq!(
    ///     since(from_ymd(2014, 1, 1), from_ymd(2013, 1, 1)),
    ///     TimeDelta::try_days(365).unwrap()
    /// );
    /// assert_eq!(
    ///     since(from_ymd(2014, 1, 1), from_ymd(2010, 1, 1)),
    ///     TimeDelta::try_days(365 * 4 + 1).unwrap()
    /// );
    /// assert_eq!(
    ///     since(from_ymd(2014, 1, 1), from_ymd(1614, 1, 1)),
    ///     TimeDelta::try_days(365 * 400 + 97).unwrap()
    /// );
    /// ```
    fn signed_duration_since(self: @Date, rhs: Date) -> TimeDelta {
        let year1 = self.year();
        let year2 = rhs.year();
        let (year1_div_400, year1_mod_400) = div_mod_floor(year1.try_into().unwrap(), 400);
        let (year2_div_400, year2_mod_400) = div_mod_floor(year2.try_into().unwrap(), 400);
        let cycle1: i64 = yo_to_cycle(year1_mod_400.try_into().unwrap(), self.ordinal())
            .try_into()
            .unwrap();
        let cycle2: i64 = yo_to_cycle(year2_mod_400.try_into().unwrap(), rhs.ordinal())
            .try_into()
            .unwrap();
        let days = (year1_div_400.try_into().unwrap() - year2_div_400.try_into().unwrap()) * 146_097
            + (cycle1 - cycle2);
        // The range of `TimeDelta` is ca. 585 million years, the range of `NaiveDate` ca. 525.000
        // years.
        TimeDeltaTrait::try_days(days).expect('always in range')
    }

    /// Returns the number of whole years from the given `base` until `self`.
    ///
    /// # Errors
    ///
    /// Returns `None` if `base > self`.
    fn years_since(self: @Date, base: Date) -> Option<u32> {
        let mut years = self.year() - base.year();
        // Comparing tuples is not (yet) possible in const context. Instead we combine month and
        // day into one `u32` for easy comparison.
        if (u32_shl(self.month(), 5) | self.day()) < (u32_shl(base.month(), 5) | base.day()) {
            years -= 1;
        }

        match years >= 0 {
            true => Some(years),
            false => None,
        }
    }

    /// Returns the [`NaiveWeek`] that the date belongs to, starting with the [`Weekday`]
    /// specified.
    #[inline]
    const fn week(self: @Date, start: Weekday) -> Week {
        WeekTrait::new(*self, start)
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
    const fn leap_year(self: @Date) -> bool {
        self.yof() & LEAP_YEAR_MASK == 0
    }

    #[inline]
    const fn year_flags(self: @Date) -> YearFlags {
        let flags = self.yof() & YEAR_FLAGS_MASK;
        YearFlags { flags: flags.try_into().unwrap() }
    }

    /// Create a new `NaiveDate` from a raw year-ordinal-flags `i32`.
    ///
    /// In a valid value an ordinal is never `0`, and neither are the year flags. This method
    /// doesn't do any validation in release builds.
    #[inline]
    const fn from_yof(yof: u32) -> Date {
        // The following are the invariants our ordinal and flags should uphold for a valid
        // `NaiveDate`.
        // debug_assert!(((yof & OL_MASK) >> 3) > 1);
        // debug_assert!(((yof & OL_MASK) >> 3) <= MAX_OL);
        // debug_assert!((yof & 0b111) != 000);
        Date { yof }
    }

    /// Get the raw year-ordinal-flags `i32`.
    #[inline]
    const fn yof(self: @Date) -> u32 {
        *self.yof
    }

    /// The minimum possible `NaiveDate` (January 1, 262144 BCE).
    /// (MIN_YEAR << 13) | (1 << 4) | 0o12 /* D */
    const MIN: Date = Self::from_yof((MIN_YEAR * 2_u32.pow(13)) | (1 * 2_u32.pow(4)) | 0o4);
    /// The maximum possible `NaiveDate` (December 31, 262142 CE).
    /// (MAX_YEAR << 13) | (365 << 4) | 0o16 /* G */
    const MAX: Date = Self::from_yof((MAX_YEAR * 2_u32.pow(13)) | (365 * 2_u32.pow(4)) | 0o16);

    /// One day before the minimum possible `NaiveDate` (December 31, 262145 BCE).
    // pub(crate) const BEFORE_MIN: NaiveDate =
    //     NaiveDate::from_yof(((MIN_YEAR - 1) << 13) | (366 << 4) | 0o07 /* FE */);
    /// One day after the maximum possible `NaiveDate` (January 1, 262143 CE).
    const AFTER_MAX: Date = Self::from_yof(
        ((MAX_YEAR + 1) * 2_u32.pow(13)) | (1 * 2_u32.pow(4)) | 0o17,
    );
}

impl DateDatelikeImpl of Datelike<Date> {
    /// Returns the year number in the [calendar date](#calendar-date).
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate};
    ///
    /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().year(), 2015);
    /// assert_eq!(NaiveDate::from_ymd_opt(-308, 3, 14).unwrap().year(), -308); // 309 BCE
    /// ```
    #[inline]
    const fn year(self: @Date) -> u32 {
        u32_shr(self.yof(), 13)
    }

    /// Returns the month number starting from 1.
    ///
    /// The return value ranges from 1 to 12.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate};
    ///
    /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().month(), 9);
    /// assert_eq!(NaiveDate::from_ymd_opt(-308, 3, 14).unwrap().month(), 3);
    /// ```
    #[inline]
    fn month(self: @Date) -> u32 {
        self.mdf().month()
    }

    /// Returns the month number starting from 0.
    ///
    /// The return value ranges from 0 to 11.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate};
    ///
    /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().month0(), 8);
    /// assert_eq!(NaiveDate::from_ymd_opt(-308, 3, 14).unwrap().month0(), 2);
    /// ```
    #[inline]
    fn month0(self: @Date) -> u32 {
        Self::month(self) - 1
    }

    /// Returns the day of month starting from 1.
    ///
    /// The return value ranges from 1 to 31. (The last day of month differs by months.)
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate};
    ///
    /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().day(), 8);
    /// assert_eq!(NaiveDate::from_ymd_opt(-308, 3, 14).unwrap().day(), 14);
    /// ```
    ///
    /// Combined with [`NaiveDate::pred_opt`](#method.pred_opt),
    /// one can determine the number of days in a particular month.
    /// (Note that this panics when `year` is out of range.)
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate};
    ///
    /// fn ndays_in_month(year: i32, month: u32) -> u32 {
    ///     // the first day of the next month...
    ///     let (y, m) = if month == 12 { (year + 1, 1) } else { (year, month + 1) };
    ///     let d = NaiveDate::from_ymd_opt(y, m, 1).unwrap();
    ///
    ///     // ...is preceded by the last day of the original month
    ///     d.pred_opt().unwrap().day()
    /// }
    ///
    /// assert_eq!(ndays_in_month(2015, 8), 31);
    /// assert_eq!(ndays_in_month(2015, 9), 30);
    /// assert_eq!(ndays_in_month(2015, 12), 31);
    /// assert_eq!(ndays_in_month(2016, 2), 29);
    /// assert_eq!(ndays_in_month(2017, 2), 28);
    /// ```
    #[inline]
    fn day(self: @Date) -> u32 {
        self.mdf().day()
    }

    /// Returns the day of month starting from 0.
    ///
    /// The return value ranges from 0 to 30. (The last day of month differs by months.)
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate};
    ///
    /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().day0(), 7);
    /// assert_eq!(NaiveDate::from_ymd_opt(-308, 3, 14).unwrap().day0(), 13);
    /// ```
    #[inline]
    fn day0(self: @Date) -> u32 {
        Self::day(self) - 1
    }

    /// Returns the day of year starting from 1.
    ///
    /// The return value ranges from 1 to 366. (The last day of year differs by years.)
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate};
    ///
    /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().ordinal(), 251);
    /// assert_eq!(NaiveDate::from_ymd_opt(-308, 3, 14).unwrap().ordinal(), 74);
    /// ```
    ///
    /// Combined with [`NaiveDate::pred_opt`](#method.pred_opt),
    /// one can determine the number of days in a particular year.
    /// (Note that this panics when `year` is out of range.)
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate};
    ///
    /// fn ndays_in_year(year: i32) -> u32 {
    ///     // the first day of the next year...
    ///     let d = NaiveDate::from_ymd_opt(year + 1, 1, 1).unwrap();
    ///
    ///     // ...is preceded by the last day of the original year
    ///     d.pred_opt().unwrap().ordinal()
    /// }
    ///
    /// assert_eq!(ndays_in_year(2015), 365);
    /// assert_eq!(ndays_in_year(2016), 366);
    /// assert_eq!(ndays_in_year(2017), 365);
    /// assert_eq!(ndays_in_year(2000), 366);
    /// assert_eq!(ndays_in_year(2100), 365);
    /// ```
    #[inline]
    const fn ordinal(self: @Date) -> u32 {
        u32_shr(self.yof() & ORDINAL_MASK, 4)
    }

    /// Returns the day of year starting from 0.
    ///
    /// The return value ranges from 0 to 365. (The last day of year differs by years.)
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate};
    ///
    /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().ordinal0(), 250);
    /// assert_eq!(NaiveDate::from_ymd_opt(-308, 3, 14).unwrap().ordinal0(), 73);
    /// ```
    #[inline]
    const fn ordinal0(self: @Date) -> u32 {
        Self::ordinal(self) - 1
    }

    /// Returns the day of week.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate, Weekday};
    ///
    /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().weekday(), Weekday::Tue);
    /// assert_eq!(NaiveDate::from_ymd_opt(-308, 3, 14).unwrap().weekday(), Weekday::Fri);
    /// ```
    #[inline]
    const fn weekday(self: @Date) -> Weekday {
        match ((u32_shr(self.yof() & ORDINAL_MASK, 4)) + (self.yof() & WEEKDAY_FLAGS_MASK)) % 7 {
            0 => Weekday::Mon,
            1 => Weekday::Tue,
            2 => Weekday::Wed,
            3 => Weekday::Thu,
            4 => Weekday::Fri,
            5 => Weekday::Sat,
            _ => Weekday::Sun,
        }
    }

    #[inline]
    fn iso_week(self: @Date) -> IsoWeek {
        IsoWeekTrait::from_yof(self.year().try_into().unwrap(), self.ordinal(), self.year_flags())
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
    #[inline]
    fn with_year(self: @Date, year: u32) -> Option<Date> {
        // we need to operate with `mdf` since we should keep the month and day number as is
        let mdf = self.mdf();

        // adjust the flags as needed
        let flags = YearFlagsTrait::from_year(year.try_into().unwrap());
        let mdf = mdf.with_flags(flags);

        DateTrait::from_mdf(year, mdf)
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
    #[inline]
    fn with_month(self: @Date, month: u32) -> Option<Date> {
        self.with_mdf(self.mdf().with_month(month)?)
    }

    /// Makes a new `NaiveDate` with the month number (starting from 0) changed.
    ///
    /// # Errors
    ///
    /// Returns `None` if:
    /// - The resulting date does not exist (for example `month0(3)` when day of the month is 31).
    /// - The value for `month0` is invalid.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate};
    ///
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().with_month0(9),
    ///     Some(NaiveDate::from_ymd_opt(2015, 10, 8).unwrap())
    /// );
    /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().with_month0(12), None); // No month
    /// 12 assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 30).unwrap().with_month0(1), None); // No Feb
    /// 30 ```
    #[inline]
    fn with_month0(self: @Date, month0: u32) -> Option<Date> {
        let month = month0.checked_add(1)?;
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
    #[inline]
    fn with_day(self: @Date, day: u32) -> Option<Date> {
        self.with_mdf(self.mdf().with_day(day)?)
    }

    /// Makes a new `NaiveDate` with the day of month (starting from 0) changed.
    ///
    /// # Errors
    ///
    /// Returns `None` if:
    /// - The resulting date does not exist (for example `day(30)` in April).
    /// - The value for `day0` is invalid.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate};
    ///
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().with_day0(29),
    ///     Some(NaiveDate::from_ymd_opt(2015, 9, 30).unwrap())
    /// );
    /// assert_eq!(NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().with_day0(30), None);
    /// // no September 31
    /// ```
    #[inline]
    fn with_day0(self: @Date, day0: u32) -> Option<Date> {
        let day = day0.checked_add(1)?;
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
    #[inline]
    fn with_ordinal(self: @Date, ordinal: u32) -> Option<Date> {
        if ordinal == 0 || ordinal > 366 {
            return None;
        }
        let yof = (self.yof() & NOT_ORDINAL_MASK) | u32_shl(ordinal, 4);
        match yof & OL_MASK <= MAX_OL {
            true => Some(DateTrait::from_yof(yof)),
            false => None // Does not exist: Ordinal 366 in a common year.
        }
    }

    /// Makes a new `NaiveDate` with the day of year (starting from 0) changed.
    ///
    /// # Errors
    ///
    /// Returns `None` if:
    /// - The resulting date does not exist (`with_ordinal0(365)` in a non-leap year).
    /// - The value for `ordinal0` is invalid.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, Datelike};
    ///
    /// assert_eq!(NaiveDate::from_ymd_opt(2015, 1, 1).unwrap().with_ordinal0(59),
    ///            Some(NaiveDate::from_ymd_opt(2015, 3, 1).unwrap()));
    /// assert_eq!(NaiveDate::from_ymd_opt(2015, 1, 1).unwrap().with_ordinal0(365),
    ///            None); // 2015 had only 365 days
    ///
    /// assert_eq!(NaiveDate::from_ymd_opt(2016, 1, 1).unwrap().with_ordinal0(59),
    ///            Some(NaiveDate::from_ymd_opt(2016, 2, 29).unwrap()));
    /// assert_eq!(NaiveDate::from_ymd_opt(2016, 1, 1).unwrap().with_ordinal0(365),
    ///            Some(NaiveDate::from_ymd_opt(2016, 12, 31).unwrap()));
    /// ```
    #[inline]
    fn with_ordinal0(self: @Date, ordinal0: u32) -> Option<Date> {
        let ordinal = ordinal0.checked_add(1)?;
        Self::with_ordinal(self, ordinal)
    }
}

impl DatePartialOrd of PartialOrd<Date> {
    #[inline]
    fn lt(lhs: Date, rhs: Date) -> bool {
        lhs.yof < rhs.yof
    }
    #[inline]
    fn ge(lhs: Date, rhs: Date) -> bool {
        lhs.yof >= rhs.yof
    }
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
        if (0..=9999).contains(@year) {
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
    (div_euclid(val, div).unwrap(), rem_euclid(val, div))
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
const MAX_OL: u32 = 366 * 2_u32.pow(4);

// Weekday of the last day in the preceding year.
// Allows for quick day of week calculation from the 1-based ordinal.
const WEEKDAY_FLAGS_MASK: u32 = 0b111;

const YEAR_FLAGS_MASK: u32 = LEAP_YEAR_MASK | WEEKDAY_FLAGS_MASK;

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
