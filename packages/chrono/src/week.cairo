use core::ops::RangeInclusive;
use super::date::{Date, DateTrait};
use super::traits::Datelike;
use super::weekday::{Weekday, WeekdayTrait};

/// A week represented by a [`NaiveDate`] and a [`Weekday`] which is the first
/// day of the week.
#[derive(Copy, PartialEq, Drop, Debug)]
pub struct Week {
    date: Date,
    start: Weekday,
}

#[generate_trait]
pub impl WeekImpl of WeekTrait {
    /// Create a new `NaiveWeek`
    const fn new(date: Date, start: Weekday) -> Week {
        Week { date, start }
    }

    /// Returns a date representing the first day of the week.
    ///
    /// # Panics
    ///
    /// Panics if the first day of the week happens to fall just out of range of `NaiveDate`
    /// (more than ca. 262,000 years away from common era).
    ///
    /// # Examples
    ///
    /// ```
    /// use chrono::{NaiveDate, Weekday};
    ///
    /// let date = NaiveDate::from_ymd_opt(2022, 4, 18).unwrap();
    /// let week = date.week(Weekday::Mon);
    /// assert!(week.first_day() <= date);
    /// ```
    #[inline]
    fn first_day(self: @Week) -> Date {
        self.checked_first_day().unwrap()
    }

    /// Returns a date representing the first day of the week or
    /// `None` if the date is out of `NaiveDate`'s range
    /// (more than ca. 262,000 years away from common era).
    ///
    /// # Examples
    ///
    /// ```
    /// use chrono::{NaiveDate, Weekday};
    ///
    /// let date = NaiveDate::MIN;
    /// let week = date.week(Weekday::Mon);
    /// if let Some(first_day) = week.checked_first_day() {
    ///     assert!(first_day == date);
    /// } else {
    ///     // error handling code
    ///     return;
    /// };
    /// ```
    #[inline]
    fn checked_first_day(self: Week) -> Option<Date> {
        let start = self.start.num_days_from_monday().try_into().unwrap();
        let ref_day = self.date.weekday().num_days_from_monday().try_into().unwrap();
        // Calculate the number of days to subtract from `self.date`.
        // Do not construct an intermediate date beyond `self.date`, because that may be out of
        // range if `date` is close to `NaiveDate::MAX`.
        let days = start - ref_day - if start > ref_day {
            7
        } else {
            0
        };
        self.date.add_days(days)
    }

    /// Returns a date representing the last day of the week.
    ///
    /// # Panics
    ///
    /// Panics if the last day of the week happens to fall just out of range of `NaiveDate`
    /// (more than ca. 262,000 years away from common era).
    ///
    /// # Examples
    ///
    /// ```
    /// use chrono::{NaiveDate, Weekday};
    ///
    /// let date = NaiveDate::from_ymd_opt(2022, 4, 18).unwrap();
    /// let week = date.week(Weekday::Mon);
    /// assert!(week.last_day() >= date);
    /// ```
    #[inline]
    fn last_day(self: @Week) -> Date {
        self.checked_last_day().unwrap()
    }

    /// Returns a date representing the last day of the week or
    /// `None` if the date is out of `NaiveDate`'s range
    /// (more than ca. 262,000 years away from common era).
    ///
    /// # Examples
    ///
    /// ```
    /// use chrono::{NaiveDate, Weekday};
    ///
    /// let date = NaiveDate::MAX;
    /// let week = date.week(Weekday::Mon);
    /// if let Some(last_day) = week.checked_last_day() {
    ///     assert!(last_day == date);
    /// } else {
    ///     // error handling code
    ///     return;
    /// };
    /// ```
    #[inline]
    fn checked_last_day(self: @Week) -> Option<Date> {
        let end = self.start.pred().num_days_from_monday().try_into().unwrap();
        let ref_day = self.date.weekday().num_days_from_monday().try_into().unwrap();
        // Calculate the number of days to add to `self.date`.
        // Do not construct an intermediate date before `self.date` (like with `first_day()`),
        // because that may be out of range if `date` is close to `NaiveDate::MIN`.
        let days = end - ref_day + if end < ref_day {
            7
        } else {
            0
        };
        self.date.add_days(days)
    }

    /// Returns a [`RangeInclusive<T>`] representing the whole week bounded by
    /// [first_day](NaiveWeek::first_day) and [last_day](NaiveWeek::last_day) functions.
    ///
    /// # Panics
    ///
    /// Panics if the either the first or last day of the week happens to fall just out of range of
    /// `NaiveDate` (more than ca. 262,000 years away from common era).
    ///
    /// # Examples
    ///
    /// ```
    /// use chrono::{NaiveDate, Weekday};
    ///
    /// let date = NaiveDate::from_ymd_opt(2022, 4, 18).unwrap();
    /// let week = date.week(Weekday::Mon);
    /// let days = week.days();
    /// assert!(days.contains(&date));
    /// ```
    #[inline]
    fn days(self: @Week) -> RangeInclusive<Date> {
        self.checked_days().unwrap()
    }

    /// Returns an [`Option<RangeInclusive<T>>`] representing the whole week bounded by
    /// [checked_first_day](NaiveWeek::checked_first_day) and
    /// [checked_last_day](NaiveWeek::checked_last_day) functions.
    ///
    /// Returns `None` if either of the boundaries are out of `NaiveDate`'s range
    /// (more than ca. 262,000 years away from common era).
    ///
    ///
    /// # Examples
    ///
    /// ```
    /// use chrono::{NaiveDate, Weekday};
    ///
    /// let date = NaiveDate::MAX;
    /// let week = date.week(Weekday::Mon);
    /// let _days = match week.checked_days() {
    ///     Some(d) => d,
    ///     None => {
    ///         // error handling code
    ///         return;
    ///     }
    /// };
    /// ```
    #[inline]
    fn checked_days(self: @Week) -> Option<RangeInclusive<Date>> {
        match (self.checked_first_day(), self.checked_last_day()) {
            (Some(first), Some(last)) => Some(first..=last),
            (_, _) => None,
        }
    }
}
