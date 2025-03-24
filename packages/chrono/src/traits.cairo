use super::isoweek::IsoWeek;
use super::months::MonthTrait;
use super::utils::shr;
use super::weekday::Weekday;

/// The common set of methods for date component.
///
/// Methods such as [`year`], [`month`], [`day`] and [`weekday`] can be used to get basic
/// information about the date.
///
/// The `with_*` methods can change the date.
///
/// # Warning
///
/// The `with_*` methods can be convenient to change a single component of a date, but they must be
/// used with some care. Examples to watch out for:
///
/// - [`with_year`] changes the year component of a year-month-day value. Don't use this method if
///   you want the ordinal to stay the same after changing the year, of if you want the week and
///   weekday values to stay the same.
/// - Don't combine two `with_*` methods to change two components of the date. For example to
///   change both the year and month components of a date. This could fail because an intermediate
///   value does not exist, while the final date would be valid.
///
/// For more complex changes to a date, it is best to use the methods on [`NaiveDate`] to create a
/// new value instead of altering an existing date.
///
/// [`year`]: Datelike::year
/// [`month`]: Datelike::month
/// [`day`]: Datelike::day
/// [`weekday`]: Datelike::weekday
/// [`with_year`]: Datelike::with_year
/// [`NaiveDate`]: crate::NaiveDate
pub trait Datelike<T> {
    /// Returns the year number in the [calendar date](./naive/struct.NaiveDate.html#calendar-date).
    const fn year(self: @T) -> u32;

    /// Returns the absolute year number starting from 1 with a boolean flag,
    /// which is false when the year predates the epoch (BCE/BC) and true otherwise (CE/AD).
    #[inline]
    const fn year_ce(
        self: @T,
    ) -> (
        bool, u32,
    ) {
        let year = Self::year(self);
        if year < 1 {
            (false, (1 - year))
        } else {
            (true, year)
        }
    }

    /// Returns the quarter number starting from 1.
    ///
    /// The return value ranges from 1 to 4.
    #[inline]
    fn quarter(self: @T) -> u32 {
        (Self::month(self) - 1) / 3 + 1
    }

    /// Returns the month number starting from 1.
    ///
    /// The return value ranges from 1 to 12.
    fn month(self: @T) -> u32;

    /// Returns the month number starting from 0.
    ///
    /// The return value ranges from 0 to 11.
    fn month0(self: @T) -> u32;

    /// Returns the day of month starting from 1.
    ///
    /// The return value ranges from 1 to 31. (The last day of month differs by months.)
    fn day(self: @T) -> u32;

    /// Returns the day of month starting from 0.
    ///
    /// The return value ranges from 0 to 30. (The last day of month differs by months.)
    fn day0(self: @T) -> u32;

    /// Returns the day of year starting from 1.
    ///
    /// The return value ranges from 1 to 366. (The last day of year differs by years.)
    const fn ordinal(self: @T) -> u32;

    /// Returns the day of year starting from 0.
    ///
    /// The return value ranges from 0 to 365. (The last day of year differs by years.)
    const fn ordinal0(self: @T) -> u32;

    /// Returns the day of week.
    const fn weekday(self: @T) -> Weekday;

    /// Returns the ISO week.
    fn iso_week(self: @T) -> IsoWeek;

    /// Makes a new value with the year number changed, while keeping the same month and day.
    ///
    /// This method assumes you want to work on the date as a year-month-day value. Don't use it if
    /// you want the ordinal to stay the same after changing the year, of if you want the week and
    /// weekday values to stay the same.
    ///
    /// # Errors
    ///
    /// Returns `None` when:
    ///
    /// - The resulting date does not exist (February 29 in a non-leap year).
    /// - The year is out of range for [`NaiveDate`].
    /// - In case of [`DateTime<Tz>`] if the resulting date and time fall within a timezone
    ///   transition such as from DST to standard time.
    ///
    /// [`NaiveDate`]: crate::NaiveDate
    /// [`DateTime<Tz>`]: crate::DateTime
    ///
    /// # Examples
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate};
    ///
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2020, 5, 13).unwrap().with_year(2023).unwrap(),
    ///     NaiveDate::from_ymd_opt(2023, 5, 13).unwrap()
    /// );
    /// // Resulting date 2023-02-29 does not exist:
    /// assert!(NaiveDate::from_ymd_opt(2020, 2, 29).unwrap().with_year(2023).is_none());
    ///
    /// // Don't use `with_year` if you want the ordinal date to stay the same:
    /// assert_ne!(
    ///     NaiveDate::from_yo_opt(2020, 100).unwrap().with_year(2023).unwrap(),
    ///     NaiveDate::from_yo_opt(2023, 100).unwrap() // result is 2023-101
    /// );
    /// ```
    fn with_year(self: @T, year: u32) -> Option<T>;

    /// Makes a new value with the month number (starting from 1) changed.
    ///
    /// # Errors
    ///
    /// Returns `None` when:
    ///
    /// - The resulting date does not exist (for example `month(4)` when day of the month is 31).
    /// - In case of [`DateTime<Tz>`] if the resulting date and time fall within a timezone
    ///   transition such as from DST to standard time.
    /// - The value for `month` is out of range.
    ///
    /// [`DateTime<Tz>`]: crate::DateTime
    ///
    /// # Examples
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate};
    ///
    /// assert_eq!(
    ///     NaiveDate::from_ymd_opt(2023, 5, 12).unwrap().with_month(9).unwrap(),
    ///     NaiveDate::from_ymd_opt(2023, 9, 12).unwrap()
    /// );
    /// // Resulting date 2023-09-31 does not exist:
    /// assert!(NaiveDate::from_ymd_opt(2023, 5, 31).unwrap().with_month(9).is_none());
    /// ```
    ///
    /// Don't combine multiple `Datelike::with_*` methods. The intermediate value may not exist.
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
    fn with_month(self: @T, month: u32) -> Option<T>;

    /// Makes a new value with the month number (starting from 0) changed.
    ///
    /// # Errors
    ///
    /// Returns `None` when:
    ///
    /// - The resulting date does not exist (for example `month0(3)` when day of the month is 31).
    /// - In case of [`DateTime<Tz>`] if the resulting date and time fall within a timezone
    ///   transition such as from DST to standard time.
    /// - The value for `month0` is out of range.
    ///
    /// [`DateTime<Tz>`]: crate::DateTime
    fn with_month0(self: @T, month0: u32) -> Option<T>;

    /// Makes a new value with the day of month (starting from 1) changed.
    ///
    /// # Errors
    ///
    /// Returns `None` when:
    ///
    /// - The resulting date does not exist (for example `day(31)` in April).
    /// - In case of [`DateTime<Tz>`] if the resulting date and time fall within a timezone
    ///   transition such as from DST to standard time.
    /// - The value for `day` is out of range.
    ///
    /// [`DateTime<Tz>`]: crate::DateTime
    fn with_day(self: @T, day: u32) -> Option<T>;

    /// Makes a new value with the day of month (starting from 0) changed.
    ///
    /// # Errors
    ///
    /// Returns `None` when:
    ///
    /// - The resulting date does not exist (for example `day0(30)` in April).
    /// - In case of [`DateTime<Tz>`] if the resulting date and time fall within a timezone
    ///   transition such as from DST to standard time.
    /// - The value for `day0` is out of range.
    ///
    /// [`DateTime<Tz>`]: crate::DateTime
    fn with_day0(self: @T, day0: u32) -> Option<T>;

    /// Makes a new value with the day of year (starting from 1) changed.
    ///
    /// # Errors
    ///
    /// Returns `None` when:
    ///
    /// - The resulting date does not exist (`with_ordinal(366)` in a non-leap year).
    /// - In case of [`DateTime<Tz>`] if the resulting date and time fall within a timezone
    ///   transition such as from DST to standard time.
    /// - The value for `ordinal` is out of range.
    ///
    /// [`DateTime<Tz>`]: crate::DateTime
    fn with_ordinal(self: @T, ordinal: u32) -> Option<T>;

    /// Makes a new value with the day of year (starting from 0) changed.
    ///
    /// # Errors
    ///
    /// Returns `None` when:
    ///
    /// - The resulting date does not exist (`with_ordinal0(365)` in a non-leap year).
    /// - In case of [`DateTime<Tz>`] if the resulting date and time fall within a timezone
    ///   transition such as from DST to standard time.
    /// - The value for `ordinal0` is out of range.
    ///
    /// [`DateTime<Tz>`]: crate::DateTime
    fn with_ordinal0(self: @T, ordinal0: u32) -> Option<T>;

    /// Counts the days in the proleptic Gregorian calendar, with January 1, Year 1 (CE) as day 1.
    ///
    /// # Examples
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate};
    ///
    /// assert_eq!(NaiveDate::from_ymd_opt(1970, 1, 1).unwrap().num_days_from_ce(), 719_163);
    /// assert_eq!(NaiveDate::from_ymd_opt(2, 1, 1).unwrap().num_days_from_ce(), 366);
    /// assert_eq!(NaiveDate::from_ymd_opt(1, 1, 1).unwrap().num_days_from_ce(), 1);
    /// assert_eq!(NaiveDate::from_ymd_opt(0, 1, 1).unwrap().num_days_from_ce(), -365);
    /// ```
    fn num_days_from_ce(
        self: @T,
    ) -> i32 {
        // See test_num_days_from_ce_against_alternative_impl below for a more straightforward
        // implementation.

        // we know this wouldn't overflow since year is limited to 1/2^13 of i32's full range.
        let mut year: i32 = Self::year(self).try_into().unwrap() - 1;
        let mut ndays = 0;
        if year < 0 {
            let excess = 1 + (-year) / 400;
            year += excess * 400;
            ndays -= excess * 146_097;
        }
        let div_100 = year / 100;
        ndays += (shr(year * 1461, 2)) - div_100 + shr(div_100, 2);
        ndays + Self::ordinal(self).try_into().unwrap()
    }

    /// Get the length in days of the month
    fn num_days_in_month(
        self: @T,
    ) -> u8 {
        // The value returned from `self.month()` is guaranteed to be in the
        // range [1,12], which will never result in a `None` value here.
        let month = MonthTrait::from_u32(Self::month(self)).unwrap();
        // `Month::num_days` will only return `None` if the provided year is out
        // of range. Since we are passing it directly from a verified date, we
        // know it is in range, and the result will never be `None`.
        month.num_days(Self::year(self)).unwrap()
    }
}

/// The common set of methods for time component.
pub trait Timelike<T> {
    /// Returns the hour number from 0 to 23.
    const fn hour(self: @T) -> u32;

    /// Returns the hour number from 1 to 12 with a boolean flag,
    /// which is false for AM and true for PM.
    #[inline]
    fn hour12(
        self: @T,
    ) -> (
        bool, u32,
    ) {
        let hour = Self::hour(self);
        let mut hour12 = hour % 12;
        if hour12 == 0 {
            hour12 = 12;
        }
        (hour >= 12, hour12)
    }

    /// Returns the minute number from 0 to 59.
    const fn minute(self: @T) -> u32;

    /// Returns the second number from 0 to 59.
    const fn second(self: @T) -> u32;

    /// Makes a new value with the hour number changed.
    ///
    /// Returns `None` when the resulting value would be invalid.
    fn with_hour(self: @T, hour: u32) -> Option<T>;

    /// Makes a new value with the minute number changed.
    ///
    /// Returns `None` when the resulting value would be invalid.
    fn with_minute(self: @T, min: u32) -> Option<T>;

    /// Makes a new value with the second number changed.
    ///
    /// Returns `None` when the resulting value would be invalid.
    /// As with the [`second`](#tymethod.second) method,
    /// the input range is restricted to 0 through 59.
    fn with_second(self: @T, sec: u32) -> Option<T>;

    /// Returns the number of non-leap seconds past the last midnight.
    ///
    /// Every value in 00:00:00-23:59:59 maps to an integer in 0-86399.
    ///
    /// This method is not intended to provide the real number of seconds since midnight on a given
    /// day. It does not take things like DST transitions into account.
    #[inline]
    fn num_seconds_from_midnight(
        self: @T,
    ) -> u32 {
        Self::hour(self) * 3600 + Self::minute(self) * 60 + Self::second(self)
    }
}
