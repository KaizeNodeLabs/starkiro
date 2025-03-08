use core::fmt::{Debug, Display, Error, Formatter};
use core::num::traits::Bounded;
use datetime::date::{Date, DateTrait};
use datetime::time::{Time, TimeTrait};
use datetime::time_delta::{TimeDelta, TimeDeltaTrait};
use datetime::utils::{div_euclid, rem_euclid};
use datetime::weekday::Weekday;

/// ISO 8601 combined date and time without timezone.
///
/// # Example
///
/// `NaiveDateTime` is commonly created from [`NaiveDate`].
///
/// ```
/// use chrono::{NaiveDate, NaiveDateTime};
///
/// let dt: NaiveDateTime =
///     NaiveDate::from_ymd_opt(2016, 7, 8).unwrap().and_hms_opt(9, 10, 11).unwrap();
/// # let _ = dt;
/// ```
///
/// You can use typical [date-like](Datelike) and [time-like](Timelike) methods,
/// provided that relevant traits are in the scope.
///
/// ```
/// # use chrono::{NaiveDate, NaiveDateTime};
/// # let dt: NaiveDateTime = NaiveDate::from_ymd_opt(2016, 7, 8).unwrap().and_hms_opt(9, 10,
/// 11).unwrap();
/// use chrono::{Datelike, Timelike, Weekday};
///
/// assert_eq!(dt.weekday(), Weekday::Fri);
/// assert_eq!(dt.num_seconds_from_midnight(), 33011);
/// ```
#[derive(Copy, PartialEq, Drop)]
pub struct DateTime {
    pub date: Date,
    pub time: Time,
}

#[generate_trait]
pub impl DateTimeImpl of DateTimeTrait {
    /// Makes a new `NaiveDateTime` from date and time components.
    /// Equivalent to [`date.and_time(time)`](./struct.NaiveDate.html#method.and_time)
    /// and many other helper constructors on `NaiveDate`.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, NaiveDateTime, NaiveTime};
    ///
    /// let d = NaiveDate::from_ymd_opt(2015, 6, 3).unwrap();
    /// let t = NaiveTime::from_hms_milli_opt(12, 34, 56, 789).unwrap();
    ///
    /// let dt = NaiveDateTime::new(d, t);
    /// assert_eq!(dt.date(), d);
    /// assert_eq!(dt.time(), t);
    /// ```
    fn new(date: Date, time: Time) -> DateTime {
        DateTime { date, time }
    }

    fn from_ymd_and_hms_opt(
        year: u32, month: u32, day: u32, hour: u32, min: u32, sec: u32,
    ) -> Option<DateTime> {
        DateTrait::from_ymd_opt(year, month, day)?.and_hms_opt(hour, min, sec)
    }

    /// Makes a new `NaiveDateTime` corresponding to a UTC date and time,
    /// from the number of non-leap seconds
    /// since the midnight UTC on January 1, 1970 (aka "UNIX timestamp")
    /// and the number of nanoseconds since the last whole non-leap second.
    ///
    /// For a non-naive version of this function see [`TimeZone::timestamp`].
    ///
    /// The nanosecond part can exceed 1,000,000,000 in order to represent a
    /// [leap second](NaiveTime#leap-second-handling), but only when `secs % 60 == 59`.
    /// (The true "UNIX timestamp" cannot represent a leap second unambiguously.)
    ///
    /// # Panics
    ///
    /// Panics if the number of seconds would be out of range for a `NaiveDateTime` (more than
    /// ca. 262,000 years away from common era), and panics on an invalid nanosecond (2 seconds or
    /// more).
    fn from_timestamp(secs: i64) -> Option<DateTime> {
        let days = div_euclid(secs, 86_400)? + UNIX_EPOCH_DAY;
        let secs = rem_euclid(secs, 86_400);
        if days < Bounded::<i32>::MIN.try_into().unwrap()
            || days > Bounded::<i32>::MAX.try_into().unwrap() {
            return None;
        }
        let date = DateTrait::from_num_days_from_ce_opt(days.try_into().unwrap())?;
        let time = TimeTrait::from_num_seconds_from_midnight_opt(secs.try_into().unwrap())?;
        Some(date.and_time(time))
    }

    /// Retrieves a date component.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::NaiveDate;
    ///
    /// let dt = NaiveDate::from_ymd_opt(2016, 7, 8).unwrap().and_hms_opt(9, 10, 11).unwrap();
    /// assert_eq!(dt.date(), NaiveDate::from_ymd_opt(2016, 7, 8).unwrap());
    /// ```
    fn date(self: @DateTime) -> Date {
        *self.date
    }

    /// Retrieves a time component.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, NaiveTime};
    ///
    /// let dt = NaiveDate::from_ymd_opt(2016, 7, 8).unwrap().and_hms_opt(9, 10, 11).unwrap();
    /// assert_eq!(dt.time(), NaiveTime::from_hms_opt(9, 10, 11).unwrap());
    /// ```
    fn time(self: @DateTime) -> Time {
        *self.time
    }

    /// Returns the number of non-leap seconds since January 1, 1970 0:00:00 UTC
    /// (aka "UNIX timestamp").
    ///
    /// The reverse operation of creating a [`DateTime`] from a timestamp can be performed
    /// using [`from_timestamp`](DateTime::from_timestamp) or [`TimeZone::timestamp_opt`].
    ///
    /// ```
    /// use chrono::{DateTime, TimeZone, Utc};
    ///
    /// let dt: DateTime<Utc> = Utc.with_ymd_and_hms(2015, 5, 15, 0, 0, 0).unwrap();
    /// assert_eq!(dt.timestamp(), 1431648000);
    ///
    /// assert_eq!(DateTime::from_timestamp(dt.timestamp(), dt.timestamp_subsec_nanos()).unwrap(),
    /// dt);
    /// ```
    fn timestamp(self: @DateTime) -> i64 {
        let gregorian_day: i64 = self.date.num_days_from_ce().try_into().unwrap();
        let seconds_from_midnight = self.time.num_seconds_from_midnight().try_into().unwrap();
        (gregorian_day - UNIX_EPOCH_DAY) * 86_400 + seconds_from_midnight
    }

    /// Adds given `TimeDelta` to the current date and time.
    ///
    /// As a part of Chrono's [leap second handling](./struct.NaiveTime.html#leap-second-handling),
    /// the addition assumes that **there is no leap second ever**,
    /// except when the `NaiveDateTime` itself represents a leap second
    /// in which case the assumption becomes that **there is exactly a single leap second ever**.
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
    /// let from_ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
    ///
    /// let d = from_ymd(2016, 7, 8);
    /// let hms = |h, m, s| d.and_hms_opt(h, m, s).unwrap();
    /// assert_eq!(hms(3, 5, 7).checked_add_signed(TimeDelta::zero()), Some(hms(3, 5, 7)));
    /// assert_eq!(
    ///     hms(3, 5, 7).checked_add_signed(TimeDelta::try_seconds(1).unwrap()),
    ///     Some(hms(3, 5, 8))
    /// );
    /// assert_eq!(
    ///     hms(3, 5, 7).checked_add_signed(TimeDelta::try_seconds(-1).unwrap()),
    ///     Some(hms(3, 5, 6))
    /// );
    /// assert_eq!(
    ///     hms(3, 5, 7).checked_add_signed(TimeDelta::try_seconds(3600 + 60).unwrap()),
    ///     Some(hms(4, 6, 7))
    /// );
    /// assert_eq!(
    ///     hms(3, 5, 7).checked_add_signed(TimeDelta::try_seconds(86_400).unwrap()),
    ///     Some(from_ymd(2016, 7, 9).and_hms_opt(3, 5, 7).unwrap())
    /// );
    ///
    /// let hmsm = |h, m, s, milli| d.and_hms_milli_opt(h, m, s, milli).unwrap();
    /// assert_eq!(
    ///     hmsm(3, 5, 7, 980).checked_add_signed(TimeDelta::try_milliseconds(450).unwrap()),
    ///     Some(hmsm(3, 5, 8, 430))
    /// );
    /// ```
    ///
    /// Overflow returns `None`.
    ///
    /// ```
    /// # use chrono::{TimeDelta, NaiveDate};
    /// # let hms = |h, m, s| NaiveDate::from_ymd_opt(2016, 7, 8).unwrap().and_hms_opt(h, m,
    /// s).unwrap();
    /// assert_eq!(hms(3, 5, 7).checked_add_signed(TimeDelta::try_days(1_000_000_000).unwrap()),
    /// None);
    /// ```
    ///
    /// Leap seconds are handled,
    /// but the addition assumes that it is the only leap second happened.
    ///
    /// ```
    /// # use chrono::{TimeDelta, NaiveDate};
    /// # let from_ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
    /// # let hmsm = |h, m, s, milli| from_ymd(2016, 7, 8).and_hms_milli_opt(h, m, s,
    /// milli).unwrap();
    /// let leap = hmsm(3, 5, 59, 1_300);
    /// assert_eq!(leap.checked_add_signed(TimeDelta::zero()),
    ///            Some(hmsm(3, 5, 59, 1_300)));
    /// assert_eq!(leap.checked_add_signed(TimeDelta::try_milliseconds(-500).unwrap()),
    ///            Some(hmsm(3, 5, 59, 800)));
    /// assert_eq!(leap.checked_add_signed(TimeDelta::try_milliseconds(500).unwrap()),
    ///            Some(hmsm(3, 5, 59, 1_800)));
    /// assert_eq!(leap.checked_add_signed(TimeDelta::try_milliseconds(800).unwrap()),
    ///            Some(hmsm(3, 6, 0, 100)));
    /// assert_eq!(leap.checked_add_signed(TimeDelta::try_seconds(10).unwrap()),
    ///            Some(hmsm(3, 6, 9, 300)));
    /// assert_eq!(leap.checked_add_signed(TimeDelta::try_seconds(-10).unwrap()),
    ///            Some(hmsm(3, 5, 50, 300)));
    /// assert_eq!(leap.checked_add_signed(TimeDelta::try_days(1).unwrap()),
    ///            Some(from_ymd(2016, 7, 9).and_hms_milli_opt(3, 5, 59, 300).unwrap()));
    /// ```
    fn checked_add_signed(self: @DateTime, rhs: TimeDelta) -> Option<DateTime> {
        let (time, remainder) = self.time.overflowing_add_signed(rhs);
        let remainder = TimeDeltaTrait::try_seconds(remainder)?;
        let date = self.date.checked_add_signed(remainder)?;
        Some(DateTime { date, time })
    }

    /// Subtracts given `TimeDelta` from the current date and time.
    ///
    /// As a part of Chrono's [leap second handling](./struct.NaiveTime.html#leap-second-handling),
    /// the subtraction assumes that **there is no leap second ever**,
    /// except when the `NaiveDateTime` itself represents a leap second
    /// in which case the assumption becomes that **there is exactly a single leap second ever**.
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
    /// let from_ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
    ///
    /// let d = from_ymd(2016, 7, 8);
    /// let hms = |h, m, s| d.and_hms_opt(h, m, s).unwrap();
    /// assert_eq!(hms(3, 5, 7).checked_sub_signed(TimeDelta::zero()), Some(hms(3, 5, 7)));
    /// assert_eq!(
    ///     hms(3, 5, 7).checked_sub_signed(TimeDelta::try_seconds(1).unwrap()),
    ///     Some(hms(3, 5, 6))
    /// );
    /// assert_eq!(
    ///     hms(3, 5, 7).checked_sub_signed(TimeDelta::try_seconds(-1).unwrap()),
    ///     Some(hms(3, 5, 8))
    /// );
    /// assert_eq!(
    ///     hms(3, 5, 7).checked_sub_signed(TimeDelta::try_seconds(3600 + 60).unwrap()),
    ///     Some(hms(2, 4, 7))
    /// );
    /// assert_eq!(
    ///     hms(3, 5, 7).checked_sub_signed(TimeDelta::try_seconds(86_400).unwrap()),
    ///     Some(from_ymd(2016, 7, 7).and_hms_opt(3, 5, 7).unwrap())
    /// );
    ///
    /// let hmsm = |h, m, s, milli| d.and_hms_milli_opt(h, m, s, milli).unwrap();
    /// assert_eq!(
    ///     hmsm(3, 5, 7, 450).checked_sub_signed(TimeDelta::try_milliseconds(670).unwrap()),
    ///     Some(hmsm(3, 5, 6, 780))
    /// );
    /// ```
    ///
    /// Overflow returns `None`.
    ///
    /// ```
    /// # use chrono::{TimeDelta, NaiveDate};
    /// # let hms = |h, m, s| NaiveDate::from_ymd_opt(2016, 7, 8).unwrap().and_hms_opt(h, m,
    /// s).unwrap();
    /// assert_eq!(hms(3, 5, 7).checked_sub_signed(TimeDelta::try_days(1_000_000_000).unwrap()),
    /// None);
    /// ```
    ///
    /// Leap seconds are handled,
    /// but the subtraction assumes that it is the only leap second happened.
    ///
    /// ```
    /// # use chrono::{TimeDelta, NaiveDate};
    /// # let from_ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
    /// # let hmsm = |h, m, s, milli| from_ymd(2016, 7, 8).and_hms_milli_opt(h, m, s,
    /// milli).unwrap();
    /// let leap = hmsm(3, 5, 59, 1_300);
    /// assert_eq!(leap.checked_sub_signed(TimeDelta::zero()),
    ///            Some(hmsm(3, 5, 59, 1_300)));
    /// assert_eq!(leap.checked_sub_signed(TimeDelta::try_milliseconds(200).unwrap()),
    ///            Some(hmsm(3, 5, 59, 1_100)));
    /// assert_eq!(leap.checked_sub_signed(TimeDelta::try_milliseconds(500).unwrap()),
    ///            Some(hmsm(3, 5, 59, 800)));
    /// assert_eq!(leap.checked_sub_signed(TimeDelta::try_seconds(60).unwrap()),
    ///            Some(hmsm(3, 5, 0, 300)));
    /// assert_eq!(leap.checked_sub_signed(TimeDelta::try_days(1).unwrap()),
    ///            Some(from_ymd(2016, 7, 7).and_hms_milli_opt(3, 6, 0, 300).unwrap()));
    /// ```
    fn checked_sub_signed(self: @DateTime, rhs: TimeDelta) -> Option<DateTime> {
        let (time, remainder) = self.time.overflowing_sub_signed(rhs);
        let remainder = TimeDeltaTrait::try_seconds(remainder)?;
        let date = self.date.checked_sub_signed(remainder)?;
        Some(DateTime { date, time })
    }

    /// Subtracts another `NaiveDateTime` from the current date and time.
    /// This does not overflow or underflow at all.
    ///
    /// As a part of Chrono's [leap second handling](./struct.NaiveTime.html#leap-second-handling),
    /// the subtraction assumes that **there is no leap second ever**,
    /// except when any of the `NaiveDateTime`s themselves represents a leap second
    /// in which case the assumption becomes that
    /// **there are exactly one (or two) leap second(s) ever**.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, TimeDelta};
    ///
    /// let from_ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
    ///
    /// let d = from_ymd(2016, 7, 8);
    /// assert_eq!(
    ///     d.and_hms_opt(3, 5, 7).unwrap().signed_duration_since(d.and_hms_opt(2, 4, 6).unwrap()),
    ///     TimeDelta::try_seconds(3600 + 60 + 1).unwrap()
    /// );
    ///
    /// // July 8 is 190th day in the year 2016
    /// let d0 = from_ymd(2016, 1, 1);
    /// assert_eq!(
    ///     d.and_hms_milli_opt(0, 7, 6, 500)
    ///         .unwrap()
    ///         .signed_duration_since(d0.and_hms_opt(0, 0, 0).unwrap()),
    ///     TimeDelta::try_seconds(189 * 86_400 + 7 * 60 + 6).unwrap()
    ///         + TimeDelta::try_milliseconds(500).unwrap()
    /// );
    /// ```
    ///
    /// Leap seconds are handled, but the subtraction assumes that
    /// there were no other leap seconds happened.
    ///
    /// ```
    /// # use chrono::{TimeDelta, NaiveDate};
    /// # let from_ymd = |y, m, d| NaiveDate::from_ymd_opt(y, m, d).unwrap();
    /// let leap = from_ymd(2015, 6, 30).and_hms_milli_opt(23, 59, 59, 1_500).unwrap();
    /// assert_eq!(
    ///     leap.signed_duration_since(from_ymd(2015, 6, 30).and_hms_opt(23, 0, 0).unwrap()),
    ///     TimeDelta::try_seconds(3600).unwrap() + TimeDelta::try_milliseconds(500).unwrap()
    /// );
    /// assert_eq!(
    ///     from_ymd(2015, 7, 1).and_hms_opt(1, 0, 0).unwrap().signed_duration_since(leap),
    ///     TimeDelta::try_seconds(3600).unwrap() - TimeDelta::try_milliseconds(500).unwrap()
    /// );
    /// ```
    fn signed_duration_since(self: @DateTime, rhs: DateTime) -> TimeDelta {
        self
            .date
            .signed_duration_since(rhs.date)
            .checked_add(self.time.signed_duration_since(rhs.time))
            .unwrap()
    }

    /// Returns the year number in the [calendar date](./struct.NaiveDate.html#calendar-date).
    ///
    /// See also the [`NaiveDate::year`](./struct.NaiveDate.html#method.year) method.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate, NaiveDateTime};
    ///
    /// let dt: NaiveDateTime =
    ///     NaiveDate::from_ymd_opt(2015, 9, 25).unwrap().and_hms_opt(12, 34, 56).unwrap();
    /// assert_eq!(dt.year(), 2015);
    /// ```
    fn year(self: @DateTime) -> u32 {
        self.date.year()
    }

    /// Returns the month number starting from 1.
    ///
    /// The return value ranges from 1 to 12.
    ///
    /// See also the [`NaiveDate::month`](./struct.NaiveDate.html#method.month) method.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate, NaiveDateTime};
    ///
    /// let dt: NaiveDateTime =
    ///     NaiveDate::from_ymd_opt(2015, 9, 25).unwrap().and_hms_opt(12, 34, 56).unwrap();
    /// assert_eq!(dt.month(), 9);
    /// ```
    fn month(self: @DateTime) -> u32 {
        self.date.month()
    }

    /// Returns the day of month starting from 1.
    ///
    /// The return value ranges from 1 to 31. (The last day of month differs by months.)
    ///
    /// See also the [`NaiveDate::day`](./struct.NaiveDate.html#method.day) method.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate, NaiveDateTime};
    ///
    /// let dt: NaiveDateTime =
    ///     NaiveDate::from_ymd_opt(2015, 9, 25).unwrap().and_hms_opt(12, 34, 56).unwrap();
    /// assert_eq!(dt.day(), 25);
    /// ```
    fn day(self: @DateTime) -> u32 {
        self.date.day()
    }

    /// Returns the day of year starting from 1.
    ///
    /// The return value ranges from 1 to 366. (The last day of year differs by years.)
    ///
    /// See also the [`NaiveDate::ordinal`](./struct.NaiveDate.html#method.ordinal) method.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate, NaiveDateTime};
    ///
    /// let dt: NaiveDateTime =
    ///     NaiveDate::from_ymd_opt(2015, 9, 25).unwrap().and_hms_opt(12, 34, 56).unwrap();
    /// assert_eq!(dt.ordinal(), 268);
    /// ```
    fn ordinal(self: @DateTime) -> u32 {
        self.date.ordinal()
    }

    /// Returns the day of week.
    ///
    /// See also the [`NaiveDate::weekday`](./struct.NaiveDate.html#method.weekday) method.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate, NaiveDateTime, Weekday};
    ///
    /// let dt: NaiveDateTime =
    ///     NaiveDate::from_ymd_opt(2015, 9, 25).unwrap().and_hms_opt(12, 34, 56).unwrap();
    /// assert_eq!(dt.weekday(), Weekday::Fri);
    /// ```
    fn weekday(self: @DateTime) -> Weekday {
        (*self.date).weekday()
    }

    /// Makes a new `NaiveDateTime` with the year number changed, while keeping the same month and
    /// day.
    ///
    /// See also the [`NaiveDate::with_year`] method.
    ///
    /// # Errors
    ///
    /// Returns `None` if:
    /// - The resulting date does not exist (February 29 in a non-leap year).
    /// - The year is out of range for a `NaiveDate`.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate, NaiveDateTime};
    ///
    /// let dt: NaiveDateTime =
    ///     NaiveDate::from_ymd_opt(2015, 9, 25).unwrap().and_hms_opt(12, 34, 56).unwrap();
    /// assert_eq!(
    ///     dt.with_year(2016),
    ///     Some(NaiveDate::from_ymd_opt(2016, 9, 25).unwrap().and_hms_opt(12, 34, 56).unwrap())
    /// );
    /// assert_eq!(
    ///     dt.with_year(-308),
    ///     Some(NaiveDate::from_ymd_opt(-308, 9, 25).unwrap().and_hms_opt(12, 34, 56).unwrap())
    /// );
    /// ```
    fn with_year(self: @DateTime, year: u32) -> Option<DateTime> {
        Some(DateTime { date: self.date.with_year(year)?, time: *self.time })
    }

    /// Makes a new `NaiveDateTime` with the month number (starting from 1) changed.
    ///
    /// Don't combine multiple `Datelike::with_*` methods. The intermediate value may not exist.
    ///
    /// See also the [`NaiveDate::with_month`] method.
    ///
    /// # Errors
    ///
    /// Returns `None` if:
    /// - The resulting date does not exist (for example `month(4)` when day of the month is 31).
    /// - The value for `month` is invalid.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{Datelike, NaiveDate, NaiveDateTime};
    ///
    /// let dt: NaiveDateTime =
    ///     NaiveDate::from_ymd_opt(2015, 9, 30).unwrap().and_hms_opt(12, 34, 56).unwrap();
    /// assert_eq!(
    ///     dt.with_month(10),
    ///     Some(NaiveDate::from_ymd_opt(2015, 10, 30).unwrap().and_hms_opt(12, 34, 56).unwrap())
    /// );
    /// assert_eq!(dt.with_month(13), None); // No month 13
    /// assert_eq!(dt.with_month(2), None); // No February 30
    /// ```
    fn with_month(self: @DateTime, month: u32) -> Option<DateTime> {
        Some(DateTime { date: self.date.with_month(month)?, time: *self.time })
    }

    /// Makes a new `NaiveDateTime` with the day of month (starting from 1) changed.
    ///
    /// See also the [`NaiveDate::with_day`] method.
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
    /// use chrono::{Datelike, NaiveDate, NaiveDateTime};
    ///
    /// let dt: NaiveDateTime =
    ///     NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().and_hms_opt(12, 34, 56).unwrap();
    /// assert_eq!(
    ///     dt.with_day(30),
    ///     Some(NaiveDate::from_ymd_opt(2015, 9, 30).unwrap().and_hms_opt(12, 34, 56).unwrap())
    /// );
    /// assert_eq!(dt.with_day(31), None); // no September 31
    /// ```
    fn with_day(self: @DateTime, day: u32) -> Option<DateTime> {
        Some(DateTime { date: self.date.with_day(day)?, time: *self.time })
    }

    /// Makes a new `NaiveDateTime` with the day of year (starting from 1) changed.
    ///
    /// See also the [`NaiveDate::with_ordinal`] method.
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
    /// use chrono::{Datelike, NaiveDate, NaiveDateTime};
    ///
    /// let dt: NaiveDateTime =
    ///     NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().and_hms_opt(12, 34, 56).unwrap();
    /// assert_eq!(
    ///     dt.with_ordinal(60),
    ///     Some(NaiveDate::from_ymd_opt(2015, 3, 1).unwrap().and_hms_opt(12, 34, 56).unwrap())
    /// );
    /// assert_eq!(dt.with_ordinal(366), None); // 2015 had only 365 days
    ///
    /// let dt: NaiveDateTime =
    ///     NaiveDate::from_ymd_opt(2016, 9, 8).unwrap().and_hms_opt(12, 34, 56).unwrap();
    /// assert_eq!(
    ///     dt.with_ordinal(60),
    ///     Some(NaiveDate::from_ymd_opt(2016, 2, 29).unwrap().and_hms_opt(12, 34, 56).unwrap())
    /// );
    /// assert_eq!(
    ///     dt.with_ordinal(366),
    ///     Some(NaiveDate::from_ymd_opt(2016, 12, 31).unwrap().and_hms_opt(12, 34, 56).unwrap())
    /// );
    /// ```
    fn with_ordinal(self: @DateTime, ordinal: u32) -> Option<DateTime> {
        Some(DateTime { date: self.date.with_ordinal(ordinal)?, time: *self.time })
    }

    /// Returns the hour number from 0 to 23.
    ///
    /// See also the [`NaiveTime::hour`] method.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, NaiveDateTime, Timelike};
    ///
    /// let dt: NaiveDateTime =
    ///     NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().and_hms_milli_opt(12, 34, 56,
    ///     789).unwrap();
    /// assert_eq!(dt.hour(), 12);
    /// ```
    fn hour(self: @DateTime) -> u32 {
        self.time.hour()
    }

    /// Returns the minute number from 0 to 59.
    ///
    /// See also the [`NaiveTime::minute`] method.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, NaiveDateTime, Timelike};
    ///
    /// let dt: NaiveDateTime =
    ///     NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().and_hms_milli_opt(12, 34, 56,
    ///     789).unwrap();
    /// assert_eq!(dt.minute(), 34);
    /// ```
    fn minute(self: @DateTime) -> u32 {
        self.time.minute()
    }

    /// Returns the second number from 0 to 59.
    ///
    /// See also the [`NaiveTime::second`] method.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, NaiveDateTime, Timelike};
    ///
    /// let dt: NaiveDateTime =
    ///     NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().and_hms_milli_opt(12, 34, 56,
    ///     789).unwrap();
    /// assert_eq!(dt.second(), 56);
    /// ```
    fn second(self: @DateTime) -> u32 {
        self.time.second()
    }

    /// Makes a new `NaiveDateTime` with the hour number changed.
    ///
    /// See also the [`NaiveTime::with_hour`] method.
    ///
    /// # Errors
    ///
    /// Returns `None` if the value for `hour` is invalid.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, NaiveDateTime, Timelike};
    ///
    /// let dt: NaiveDateTime =
    ///     NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().and_hms_milli_opt(12, 34, 56,
    ///     789).unwrap();
    /// assert_eq!(
    ///     dt.with_hour(7),
    ///     Some(
    ///         NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().and_hms_milli_opt(7, 34, 56,
    ///         789).unwrap()
    ///     )
    /// );
    /// assert_eq!(dt.with_hour(24), None);
    /// ```
    fn with_hour(self: @DateTime, hour: u32) -> Option<DateTime> {
        Some(DateTime { date: *self.date, time: self.time.with_hour(hour)? })
    }

    /// Makes a new `NaiveDateTime` with the minute number changed.
    ///
    /// See also the [`NaiveTime::with_minute`] method.
    ///
    /// # Errors
    ///
    /// Returns `None` if the value for `minute` is invalid.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, NaiveDateTime, Timelike};
    ///
    /// let dt: NaiveDateTime =
    ///     NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().and_hms_milli_opt(12, 34, 56,
    ///     789).unwrap();
    /// assert_eq!(
    ///     dt.with_minute(45),
    ///     Some(
    ///         NaiveDate::from_ymd_opt(2015, 9, 8)
    ///             .unwrap()
    ///             .and_hms_milli_opt(12, 45, 56, 789)
    ///             .unwrap()
    ///     )
    /// );
    /// assert_eq!(dt.with_minute(60), None);
    /// ```
    fn with_minute(self: @DateTime, min: u32) -> Option<DateTime> {
        Some(DateTime { date: *self.date, time: self.time.with_minute(min)? })
    }

    /// Makes a new `NaiveDateTime` with the second number changed.
    ///
    /// As with the [`second`](#method.second) method,
    /// the input range is restricted to 0 through 59.
    ///
    /// See also the [`NaiveTime::with_second`] method.
    ///
    /// # Errors
    ///
    /// Returns `None` if the value for `second` is invalid.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveDate, NaiveDateTime, Timelike};
    ///
    /// let dt: NaiveDateTime =
    ///     NaiveDate::from_ymd_opt(2015, 9, 8).unwrap().and_hms_milli_opt(12, 34, 56,
    ///     789).unwrap();
    /// assert_eq!(
    ///     dt.with_second(17),
    ///     Some(
    ///         NaiveDate::from_ymd_opt(2015, 9, 8)
    ///             .unwrap()
    ///             .and_hms_milli_opt(12, 34, 17, 789)
    ///             .unwrap()
    ///     )
    /// );
    /// assert_eq!(dt.with_second(60), None);
    /// ```
    fn with_second(self: @DateTime, sec: u32) -> Option<DateTime> {
        Some(DateTime { date: *self.date, time: self.time.with_second(sec)? })
    }

    /// The minimum possible `NaiveDateTime`.
    const MIN: DateTime = DateTime { date: DateTrait::MIN, time: TimeTrait::MIN };

    /// The maximum possible `NaiveDateTime`.
    const MAX: DateTime = DateTime { date: DateTrait::MAX, time: TimeTrait::MAX };

    /// The datetime of the Unix Epoch, 1970-01-01 00:00:00.
    ///
    /// Note that while this may look like the UNIX epoch, it is missing the
    /// time zone. The actual UNIX epoch cannot be expressed by this type,
    /// however it is available as [`DateTime::UNIX_EPOCH`].
    const UNIX_EPOCH: DateTime = DateTime { date: Date { yof: 16138266 }, time: Time { secs: 0 } };
}

impl DateTimePartialOrd of PartialOrd<DateTime> {
    fn lt(lhs: DateTime, rhs: DateTime) -> bool {
        if lhs.date == rhs.date {
            return lhs.time < rhs.time;
        }
        lhs.date < rhs.date
    }
    fn ge(lhs: DateTime, rhs: DateTime) -> bool {
        if lhs.date == rhs.date {
            return lhs.time >= rhs.time;
        }
        lhs.date >= rhs.date
        // lhs.date >= rhs.date && lhs.time >= rhs.time
    }
}

/// The `Debug` output of the naive date and time `dt` is the same as
/// [`dt.format("%Y-%m-%dT%H:%M:%S%.f")`](crate::format::strftime).
///
/// The string printed can be readily parsed via the `parse` method on `str`.
///
/// It should be noted that, for leap seconds not on the minute boundary,
/// it may print a representation not distinguishable from non-leap seconds.
/// This doesn't matter in practice, since such leap seconds never happened.
/// (By the time of the first leap second on 1972-06-30,
/// every time zone offset around the world has standardized to the 5-minute alignment.)
///
/// # Example
///
/// ```
/// use chrono::NaiveDate;
///
/// let dt = NaiveDate::from_ymd_opt(2016, 11, 15).unwrap().and_hms_opt(7, 39, 24).unwrap();
/// assert_eq!(format!("{:?}", dt), "2016-11-15T07:39:24");
/// ```
///
/// Leap seconds may also be used.
///
/// ```
/// # use chrono::NaiveDate;
/// let dt =
///     NaiveDate::from_ymd_opt(2015, 6, 30).unwrap().and_hms_milli_opt(23, 59, 59, 1_500).unwrap();
/// assert_eq!(format!("{:?}", dt), "2015-06-30T23:59:60.500");
/// ```
impl DateTimeDebug of Debug<DateTime> {
    fn fmt(self: @DateTime, ref f: Formatter) -> Result<(), Error> {
        Display::fmt(self.date, ref f)?;
        f.buffer.append_byte('T');
        Display::fmt(self.time, ref f)
    }
}

/// The `Display` output of the naive date and time `dt` is the same as
/// [`dt.format("%Y-%m-%d %H:%M:%S%.f")`](crate::format::strftime).
///
/// It should be noted that, for leap seconds not on the minute boundary,
/// it may print a representation not distinguishable from non-leap seconds.
/// This doesn't matter in practice, since such leap seconds never happened.
/// (By the time of the first leap second on 1972-06-30,
/// every time zone offset around the world has standardized to the 5-minute alignment.)
///
/// # Example
///
/// ```
/// use chrono::NaiveDate;
///
/// let dt = NaiveDate::from_ymd_opt(2016, 11, 15).unwrap().and_hms_opt(7, 39, 24).unwrap();
/// assert_eq!(format!("{}", dt), "2016-11-15 07:39:24");
/// ```
///
/// Leap seconds may also be used.
///
/// ```
/// # use chrono::NaiveDate;
/// let dt =
///     NaiveDate::from_ymd_opt(2015, 6, 30).unwrap().and_hms_milli_opt(23, 59, 59, 1_500).unwrap();
/// assert_eq!(format!("{}", dt), "2015-06-30 23:59:60.500");
/// ```
impl DateTimeDisplay of Display<DateTime> {
    fn fmt(self: @DateTime, ref f: Formatter) -> Result<(), Error> {
        Display::fmt(self.date, ref f)?;
        f.buffer.append_byte(' ');
        Display::fmt(self.time, ref f)
    }
}

/// The default value for a NaiveDateTime is 1st of January 1970 at 00:00:00.
///
/// Note that while this may look like the UNIX epoch, it is missing the
/// time zone. The actual UNIX epoch cannot be expressed by this type,
/// however it is available as [`DateTime::UNIX_EPOCH`].
impl DateTimeDefault of Default<DateTime> {
    fn default() -> DateTime {
        DateTimeTrait::UNIX_EPOCH
    }
}

const UNIX_EPOCH_DAY: i64 = 719_163;
