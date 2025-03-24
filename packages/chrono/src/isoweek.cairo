//! ISO 8601 week.

use core::fmt::{Debug, Error, Formatter};
use core::ops::RangeInclusiveTrait;
use super::format::formatting::write_hundreds;
use super::internals::{YearFlags, YearFlagsTrait};
use super::utils::{u32_shl, u32_shr};

/// ISO 8601 week.
///
/// This type, combined with [`Weekday`](../enum.Weekday.html),
/// constitutes the ISO 8601 [week date](./struct.NaiveDate.html#week-date).
/// One can retrieve this type from the existing [`Datelike`](../trait.Datelike.html) types
/// via the [`Datelike::iso_week`](../trait.Datelike.html#tymethod.iso_week) method.
#[derive(Clone, Copy, PartialEq, Drop)]
pub struct IsoWeek {
    // Note that this allows for larger year range than `NaiveDate`.
    // This is crucial because we have an edge case for the first and last week supported,
    // which year number might not match the calendar year number.
    ywf: u32 // (year << 10) | (week << 4) | flag
}

#[generate_trait]
pub impl IsoWeekImpl of IsoWeekTrait {
    /// Returns the corresponding `IsoWeek` from the year and the `Of` internal value.
    //
    // Internal use only. We don't expose the public constructor for `IsoWeek` for now
    // because the year range for the week date and the calendar date do not match, and
    // it is confusing to have a date that is out of range in one and not in another.
    // Currently we sidestep this issue by making `IsoWeek` fully dependent of `Datelike`.
    fn from_yof(year: i32, ordinal: u32, year_flags: YearFlags) -> IsoWeek {
        let rawweek = (ordinal + year_flags.isoweek_delta()) / 7;
        let (year, week) = if rawweek < 1 {
            // previous year
            let prevlastweek = YearFlagsTrait::from_year(year - 1).nisoweeks();
            (year - 1, prevlastweek)
        } else {
            let lastweek = year_flags.nisoweeks();
            if rawweek > lastweek {
                // next year
                (year + 1, 1)
            } else {
                (year, rawweek)
            }
        };
        let flags = YearFlagsTrait::from_year(year);
        IsoWeek {
            ywf: u32_shl(year.try_into().unwrap(), 10) | u32_shl(week, 4) | flags.flags.into(),
        }
    }

    /// Returns the year number for this ISO week.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate, Weekday};
    ///
    /// let d = NaiveDate::from_isoywd_opt(2015, 1, Weekday::Mon).unwrap();
    /// assert_eq!(d.iso_week().year(), 2015);
    /// ```
    ///
    /// This year number might not match the calendar year number.
    /// Continuing the example...
    ///
    /// ```
    /// # use chrono::{NaiveDate, Datelike, Weekday};
    /// # let d = NaiveDate::from_isoywd_opt(2015, 1, Weekday::Mon).unwrap();
    /// assert_eq!(d.year(), 2014);
    /// assert_eq!(d, NaiveDate::from_ymd_opt(2014, 12, 29).unwrap());
    /// ```
    #[inline]
    const fn year(self: @IsoWeek) -> u32 {
        u32_shr(*self.ywf, 10)
    }

    /// Returns the ISO week number starting from 1.
    ///
    /// The return value ranges from 1 to 53. (The last week of year differs by years.)
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate, Weekday};
    ///
    /// let d = NaiveDate::from_isoywd_opt(2015, 15, Weekday::Mon).unwrap();
    /// assert_eq!(d.iso_week().week(), 15);
    /// ```
    #[inline]
    const fn week(self: @IsoWeek) -> u32 {
        (u32_shr(*self.ywf, 4) & 0x3f)
    }

    /// Returns the ISO week number starting from 0.
    ///
    /// The return value ranges from 0 to 52. (The last week of year differs by years.)
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate, Weekday};
    ///
    /// let d = NaiveDate::from_isoywd_opt(2015, 15, Weekday::Mon).unwrap();
    /// assert_eq!(d.iso_week().week0(), 14);
    /// ```
    #[inline]
    const fn week0(self: @IsoWeek) -> u32 {
        (u32_shr(*self.ywf, 4) & 0x3f) - 1
    }
}

impl IsoWeekPartialOrd of PartialOrd<IsoWeek> {
    #[inline]
    fn lt(lhs: IsoWeek, rhs: IsoWeek) -> bool {
        lhs.ywf < rhs.ywf
    }
    #[inline]
    fn ge(lhs: IsoWeek, rhs: IsoWeek) -> bool {
        lhs.ywf >= rhs.ywf
    }
}

impl IsoWeekDebug of Debug<IsoWeek> {
    fn fmt(self: @IsoWeek, ref f: Formatter) -> Result<(), Error> {
        let year = self.year();
        let week = self.week();
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
        f.buffer.append(@"-W");
        write_hundreds(ref f, week.try_into().unwrap())
    }
}
