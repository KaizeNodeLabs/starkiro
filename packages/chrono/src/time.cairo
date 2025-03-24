//! ISO 8601 time without timezone.

use core::fmt::{Debug, Display, Error, Formatter};
use super::format::formatting::write_hundreds;
use super::time_delta::{TimeDelta, TimeDeltaTrait};
use super::traits::Timelike;
use super::utils::rem_euclid;

#[derive(Clone, Copy, PartialEq, Drop, Serde, starknet::Store)]
pub struct Time {
    pub(crate) secs: u32,
}

#[generate_trait]
pub impl TimeImpl of TimeTrait {
    /// Makes a new `NaiveTime` from hour, minute and second.
    ///
    /// The millisecond part is allowed to exceed 1,000,000,000 in order to represent a
    /// [leap second](#leap-second-handling), but only when `sec == 59`.
    ///
    /// # Errors
    ///
    /// Returns `None` on invalid hour, minute and/or second.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::NaiveTime;
    ///
    /// let from_hms_opt = NaiveTime::from_hms_opt;
    ///
    /// assert!(from_hms_opt(0, 0, 0).is_some());
    /// assert!(from_hms_opt(23, 59, 59).is_some());
    /// assert!(from_hms_opt(24, 0, 0).is_none());
    /// assert!(from_hms_opt(23, 60, 0).is_none());
    /// assert!(from_hms_opt(23, 59, 60).is_none());
    /// ```
    #[inline]
    fn from_hms_opt(hour: u32, min: u32, sec: u32) -> Option<Time> {
        if (hour >= 24 || min >= 60 || sec >= 60) {
            return None;
        }
        let secs = hour * 3600 + min * 60 + sec;
        Some(Time { secs })
    }

    /// Makes a new `NaiveTime` from the number of seconds since midnight and nanosecond.
    ///
    /// The nanosecond part is allowed to exceed 1,000,000,000 in order to represent a
    /// [leap second](#leap-second-handling), but only when `secs % 60 == 59`.
    ///
    /// # Errors
    ///
    /// Returns `None` on invalid number of seconds and/or nanosecond.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::NaiveTime;
    ///
    /// let from_nsecs_opt = NaiveTime::from_num_seconds_from_midnight_opt;
    ///
    /// assert!(from_nsecs_opt(0, 0).is_some());
    /// assert!(from_nsecs_opt(86399, 999_999_999).is_some());
    /// assert!(from_nsecs_opt(86399, 1_999_999_999).is_some()); // a leap second after 23:59:59
    /// assert!(from_nsecs_opt(86_400, 0).is_none());
    /// assert!(from_nsecs_opt(86399, 2_000_000_000).is_none());
    /// ```
    #[inline]
    fn from_num_seconds_from_midnight_opt(secs: u32) -> Option<Time> {
        if secs >= 86_400 {
            return None;
        }
        Some(Time { secs })
    }

    /// Adds given `TimeDelta` to the current time, and also returns the number of *seconds*
    /// in the integral number of days ignored from the addition.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveTime, TimeDelta};
    ///
    /// let from_hms = |h, m, s| NaiveTime::from_hms_opt(h, m, s).unwrap();
    ///
    /// assert_eq!(
    ///     from_hms(3, 4, 5).overflowing_add_signed(TimeDelta::try_hours(11).unwrap()),
    ///     (from_hms(14, 4, 5), 0)
    /// );
    /// assert_eq!(
    ///     from_hms(3, 4, 5).overflowing_add_signed(TimeDelta::try_hours(23).unwrap()),
    ///     (from_hms(2, 4, 5), 86_400)
    /// );
    /// assert_eq!(
    ///     from_hms(3, 4, 5).overflowing_add_signed(TimeDelta::try_hours(-7).unwrap()),
    ///     (from_hms(20, 4, 5), -86_400)
    /// );
    /// ```
    fn overflowing_add_signed(self: @Time, rhs: TimeDelta) -> (Time, i64) {
        let secs = (*self.secs).into() + rhs.num_seconds();

        let secs_in_day = rem_euclid(secs, 86_400);
        let remaining = secs - secs_in_day;
        (Time { secs: secs_in_day.try_into().unwrap() }, remaining)
    }

    /// Subtracts given `TimeDelta` from the current time, and also returns the number of *seconds*
    /// in the integral number of days ignored from the subtraction.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveTime, TimeDelta};
    ///
    /// let from_hms = |h, m, s| NaiveTime::from_hms_opt(h, m, s).unwrap();
    ///
    /// assert_eq!(
    ///     from_hms(3, 4, 5).overflowing_sub_signed(TimeDelta::try_hours(2).unwrap()),
    ///     (from_hms(1, 4, 5), 0)
    /// );
    /// assert_eq!(
    ///     from_hms(3, 4, 5).overflowing_sub_signed(TimeDelta::try_hours(17).unwrap()),
    ///     (from_hms(10, 4, 5), 86_400)
    /// );
    /// assert_eq!(
    ///     from_hms(3, 4, 5).overflowing_sub_signed(TimeDelta::try_hours(-22).unwrap()),
    ///     (from_hms(1, 4, 5), -86_400)
    /// );
    /// ```
    #[inline]
    fn overflowing_sub_signed(self: @Time, rhs: TimeDelta) -> (Time, i64) {
        let (time, rhs) = self.overflowing_add_signed(-rhs);
        (time, -rhs) // safe to negate, rhs is within +/- (2^63 / 1000)
    }

    /// Subtracts another `NaiveTime` from the current time.
    /// Returns a `TimeDelta` within +/- 1 day.
    /// This does not overflow or underflow at all.
    ///
    /// As a part of Chrono's [leap second handling](#leap-second-handling),
    /// the subtraction assumes that **there is no leap second ever**,
    /// except when any of the `NaiveTime`s themselves represents a leap second
    /// in which case the assumption becomes that
    /// **there are exactly one (or two) leap second(s) ever**.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveTime, TimeDelta};
    ///
    /// let from_hmsm = |h, m, s, milli| NaiveTime::from_hms_milli_opt(h, m, s, milli).unwrap();
    /// let since = NaiveTime::signed_duration_since;
    ///
    /// assert_eq!(since(from_hmsm(3, 5, 7, 900), from_hmsm(3, 5, 7, 900)), TimeDelta::zero());
    /// assert_eq!(
    ///     since(from_hmsm(3, 5, 7, 900), from_hmsm(3, 5, 7, 875)),
    ///     TimeDelta::try_milliseconds(25).unwrap()
    /// );
    /// assert_eq!(
    ///     since(from_hmsm(3, 5, 7, 900), from_hmsm(3, 5, 6, 925)),
    ///     TimeDelta::try_milliseconds(975).unwrap()
    /// );
    /// assert_eq!(
    ///     since(from_hmsm(3, 5, 7, 900), from_hmsm(3, 5, 0, 900)),
    ///     TimeDelta::try_seconds(7).unwrap()
    /// );
    /// assert_eq!(
    ///     since(from_hmsm(3, 5, 7, 900), from_hmsm(3, 0, 7, 900)),
    ///     TimeDelta::try_seconds(5 * 60).unwrap()
    /// );
    /// assert_eq!(
    ///     since(from_hmsm(3, 5, 7, 900), from_hmsm(0, 5, 7, 900)),
    ///     TimeDelta::try_seconds(3 * 3600).unwrap()
    /// );
    /// assert_eq!(
    ///     since(from_hmsm(3, 5, 7, 900), from_hmsm(4, 5, 7, 900)),
    ///     TimeDelta::try_seconds(-3600).unwrap()
    /// );
    /// assert_eq!(
    ///     since(from_hmsm(3, 5, 7, 900), from_hmsm(2, 4, 6, 800)),
    ///     TimeDelta::try_seconds(3600 + 60 + 1).unwrap() +
    ///     TimeDelta::try_milliseconds(100).unwrap()
    /// );
    /// ```
    ///
    /// Leap seconds are handled, but the subtraction assumes that
    /// there were no other leap seconds happened.
    ///
    /// ```
    /// # use chrono::{TimeDelta, NaiveTime};
    /// # let from_hmsm = |h, m, s, milli| { NaiveTime::from_hms_milli_opt(h, m, s, milli).unwrap()
    /// };
    /// # let since = NaiveTime::signed_duration_since;
    /// assert_eq!(since(from_hmsm(3, 0, 59, 1_000), from_hmsm(3, 0, 59, 0)),
    ///            TimeDelta::try_seconds(1).unwrap());
    /// assert_eq!(since(from_hmsm(3, 0, 59, 1_500), from_hmsm(3, 0, 59, 0)),
    ///            TimeDelta::try_milliseconds(1500).unwrap());
    /// assert_eq!(since(from_hmsm(3, 0, 59, 1_000), from_hmsm(3, 0, 0, 0)),
    ///            TimeDelta::try_seconds(60).unwrap());
    /// assert_eq!(since(from_hmsm(3, 0, 0, 0), from_hmsm(2, 59, 59, 1_000)),
    ///            TimeDelta::try_seconds(1).unwrap());
    /// assert_eq!(since(from_hmsm(3, 0, 59, 1_000), from_hmsm(2, 59, 59, 1_000)),
    ///            TimeDelta::try_seconds(61).unwrap());
    /// ```
    fn signed_duration_since(self: @Time, rhs: Time) -> TimeDelta {
        //     |    |    :leap|    |    |    |    |    |    |    :leap|    |
        //     |    |    :    |    |    |    |    |    |    |    :    |    |
        // ----+----+-----*---+----+----+----+----+----+----+-------*-+----+----
        //          |   `rhs` |                             |    `self`
        //          |======================================>|       |
        //          |     |  `self.secs - rhs.secs`         |`self.frac`
        //          |====>|   |                             |======>|
        //      `rhs.frac`|========================================>|
        //          |     |   |        `self - rhs`         |       |

        let secs: i64 = (*self.secs).try_into().unwrap() - rhs.secs.try_into().unwrap();

        TimeDeltaTrait::new(secs).expect('must be in range')
    }

    /// Returns a triple of the hour, minute and second numbers.
    const fn hms(self: @Time) -> (u32, u32, u32) {
        let sec = *self.secs % 60;
        let mins = *self.secs / 60;
        let min = mins % 60;
        let hour = mins / 60;
        (hour, min, sec)
    }

    /// The earliest possible `NaiveTime`
    const MIN: Time = Time { secs: 0 };
    const MAX: Time = Time { secs: 23 * 3600 + 59 * 60 + 59 };
}

impl TimeTimelikeImpl of Timelike<Time> {
    /// Returns the hour number from 0 to 23.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveTime, Timelike};
    ///
    /// assert_eq!(NaiveTime::from_hms_opt(0, 0, 0).unwrap().hour(), 0);
    /// assert_eq!(NaiveTime::from_hms_nano_opt(23, 56, 4, 12_345_678).unwrap().hour(), 23);
    /// ```
    #[inline]
    const fn hour(self: @Time) -> u32 {
        let (hour, _, _) = self.hms();
        hour
    }

    /// Returns the minute number from 0 to 59.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveTime, Timelike};
    ///
    /// assert_eq!(NaiveTime::from_hms_opt(0, 0, 0).unwrap().minute(), 0);
    /// assert_eq!(NaiveTime::from_hms_nano_opt(23, 56, 4, 12_345_678).unwrap().minute(), 56);
    /// ```
    #[inline]
    const fn minute(self: @Time) -> u32 {
        let (_, min, _) = self.hms();
        min
    }

    /// Returns the second number from 0 to 59.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveTime, Timelike};
    ///
    /// assert_eq!(NaiveTime::from_hms_opt(0, 0, 0).unwrap().second(), 0);
    /// assert_eq!(NaiveTime::from_hms_nano_opt(23, 56, 4, 12_345_678).unwrap().second(), 4);
    /// ```
    ///
    /// This method never returns 60 even when it is a leap second.
    /// ([Why?](#leap-second-handling))
    /// Use the proper [formatting method](#method.format) to get a human-readable representation.
    ///
    /// ```
    /// # #[cfg(feature = "alloc")] {
    /// # use chrono::{NaiveTime, Timelike};
    /// let leap = NaiveTime::from_hms_milli_opt(23, 59, 59, 1_000).unwrap();
    /// assert_eq!(leap.second(), 59);
    /// assert_eq!(leap.format("%H:%M:%S").to_string(), "23:59:60");
    /// # }
    /// ```
    #[inline]
    const fn second(self: @Time) -> u32 {
        let (_, _, sec) = self.hms();
        sec
    }

    /// Makes a new `NaiveTime` with the hour number changed.
    ///
    /// # Errors
    ///
    /// Returns `None` if the value for `hour` is invalid.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveTime, Timelike};
    ///
    /// let dt = NaiveTime::from_hms_nano_opt(23, 56, 4, 12_345_678).unwrap();
    /// assert_eq!(dt.with_hour(7), Some(NaiveTime::from_hms_nano_opt(7, 56, 4,
    /// 12_345_678).unwrap()));
    /// assert_eq!(dt.with_hour(24), None);
    /// ```
    #[inline]
    fn with_hour(self: @Time, hour: u32) -> Option<Time> {
        if hour >= 24 {
            return None;
        }
        let secs = hour * 3600 + *self.secs % 3600;
        Some(Time { secs })
    }

    /// Makes a new `NaiveTime` with the minute number changed.
    ///
    /// # Errors
    ///
    /// Returns `None` if the value for `minute` is invalid.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveTime, Timelike};
    ///
    /// let dt = NaiveTime::from_hms_nano_opt(23, 56, 4, 12_345_678).unwrap();
    /// assert_eq!(
    ///     dt.with_minute(45),
    ///     Some(NaiveTime::from_hms_nano_opt(23, 45, 4, 12_345_678).unwrap())
    /// );
    /// assert_eq!(dt.with_minute(60), None);
    /// ```
    #[inline]
    fn with_minute(self: @Time, min: u32) -> Option<Time> {
        if min >= 60 {
            return None;
        }
        let secs = *self.secs / 3600 * 3600 + min * 60 + *self.secs % 60;
        Some(Time { secs })
    }

    /// Makes a new `NaiveTime` with the second number changed.
    ///
    /// As with the [`second`](#method.second) method,
    /// the input range is restricted to 0 through 59.
    ///
    /// # Errors
    ///
    /// Returns `None` if the value for `second` is invalid.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveTime, Timelike};
    ///
    /// let dt = NaiveTime::from_hms_nano_opt(23, 56, 4, 12_345_678).unwrap();
    /// assert_eq!(
    ///     dt.with_second(17),
    ///     Some(NaiveTime::from_hms_nano_opt(23, 56, 17, 12_345_678).unwrap())
    /// );
    /// assert_eq!(dt.with_second(60), None);
    /// ```
    #[inline]
    fn with_second(self: @Time, sec: u32) -> Option<Time> {
        if sec >= 60 {
            return None;
        }
        let secs = *self.secs / 60 * 60 + sec;
        Some(Time { secs })
    }

    /// Returns the number of non-leap seconds past the last midnight.
    ///
    /// # Example
    ///
    /// ```
    /// use chrono::{NaiveTime, Timelike};
    ///
    /// assert_eq!(NaiveTime::from_hms_opt(1, 2, 3).unwrap().num_seconds_from_midnight(), 3723);
    /// assert_eq!(
    ///     NaiveTime::from_hms_nano_opt(23, 56, 4,
    ///     12_345_678).unwrap().num_seconds_from_midnight(), 86164
    /// );
    /// assert_eq!(
    ///     NaiveTime::from_hms_milli_opt(23, 59, 59, 1_000).unwrap().num_seconds_from_midnight(),
    ///     86399
    /// );
    /// ```
    #[inline]
    fn num_seconds_from_midnight(self: @Time) -> u32 {
        *self.secs // do not repeat the calculation!
    }
}

impl TimePartialOrd of PartialOrd<Time> {
    fn lt(lhs: Time, rhs: Time) -> bool {
        lhs.secs < rhs.secs
    }
    fn ge(lhs: Time, rhs: Time) -> bool {
        lhs.secs >= rhs.secs
    }
}

/// The `Debug` output of the naive time `t` is the same as
/// [`t.format("%H:%M:%S%.f")`](crate::format::strftime).
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
/// use chrono::NaiveTime;
///
/// assert_eq!(format!("{:?}", NaiveTime::from_hms_opt(23, 56, 4).unwrap()), "23:56:04");
/// assert_eq!(
///     format!("{:?}", NaiveTime::from_hms_milli_opt(23, 56, 4, 12).unwrap()),
///     "23:56:04.012"
/// );
/// assert_eq!(
///     format!("{:?}", NaiveTime::from_hms_micro_opt(23, 56, 4, 1234).unwrap()),
///     "23:56:04.001234"
/// );
/// assert_eq!(
///     format!("{:?}", NaiveTime::from_hms_nano_opt(23, 56, 4, 123456).unwrap()),
///     "23:56:04.000123456"
/// );
/// ```
///
/// Leap seconds may also be used.
///
/// ```
/// # use chrono::NaiveTime;
/// assert_eq!(
///     format!("{:?}", NaiveTime::from_hms_milli_opt(6, 59, 59, 1_500).unwrap()),
///     "06:59:60.500"
/// );
/// ```
impl TimeDebug of Debug<Time> {
    fn fmt(self: @Time, ref f: Formatter) -> Result<(), Error> {
        let (hour, min, sec) = self.hms();

        write_hundreds(ref f, hour.try_into().unwrap())?;
        f.buffer.append_byte(':');
        write_hundreds(ref f, min.try_into().unwrap())?;
        f.buffer.append_byte(':');
        write_hundreds(ref f, sec.try_into().unwrap())
    }
}

/// The `Display` output of the naive time `t` is the same as
/// [`t.format("%H:%M:%S%.f")`](crate::format::strftime).
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
/// use chrono::NaiveTime;
///
/// assert_eq!(format!("{}", NaiveTime::from_hms_opt(23, 56, 4).unwrap()), "23:56:04");
/// assert_eq!(
///     format!("{}", NaiveTime::from_hms_milli_opt(23, 56, 4, 12).unwrap()),
///     "23:56:04.012"
/// );
/// assert_eq!(
///     format!("{}", NaiveTime::from_hms_micro_opt(23, 56, 4, 1234).unwrap()),
///     "23:56:04.001234"
/// );
/// assert_eq!(
///     format!("{}", NaiveTime::from_hms_nano_opt(23, 56, 4, 123456).unwrap()),
///     "23:56:04.000123456"
/// );
/// ```
///
/// Leap seconds may also be used.
///
/// ```
/// # use chrono::NaiveTime;
/// assert_eq!(
///     format!("{}", NaiveTime::from_hms_milli_opt(6, 59, 59, 1_500).unwrap()),
///     "06:59:60.500"
/// );
/// ```
impl TimeDisplay of Display<Time> {
    fn fmt(self: @Time, ref f: Formatter) -> Result<(), Error> {
        Debug::fmt(self, ref f)
    }
}

/// The default value for a NaiveTime is midnight, 00:00:00 exactly.
///
/// # Example
///
/// ```rust
/// use chrono::NaiveTime;
///
/// let default_time = NaiveTime::default();
/// assert_eq!(default_time, NaiveTime::from_hms_opt(0, 0, 0).unwrap());
/// ```
impl TimeDefault of Default<Time> {
    fn default() -> Time {
        TimeTrait::from_hms_opt(0, 0, 0).unwrap()
    }
}
