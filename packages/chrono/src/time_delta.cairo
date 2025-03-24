//! Temporal quantification

use core::fmt::{Debug, Display, Error, Formatter};
use core::num::traits::{Bounded, CheckedMul};
use super::utils::abs;

/// The number of milliseconds per second.
pub const MILLIS_PER_SEC: i64 = 1000;
// The number of seconds in a minute.
pub const SECS_PER_MINUTE: i64 = 60;
/// The number of seconds in an hour.
pub const SECS_PER_HOUR: i64 = 3600;
/// The number of (non-leap) seconds in days.
pub const SECS_PER_DAY: i64 = 86_400;
/// The number of (non-leap) seconds in a week.
pub const SECS_PER_WEEK: i64 = 604_800;

/// Time duration with nanosecond precision.
///
/// This also allows for negative durations; see individual methods for details.
///
/// A `TimeDelta` is represented internally as a complement of seconds and
/// nanoseconds. The range is restricted to that of `i64` milliseconds, with the
/// minimum value notably being set to `-i64::MAX` rather than allowing the full
/// range of `i64::MIN`. This is to allow easy flipping of sign, so that for
/// instance `abs()` can be called without any checks.
#[derive(Clone, Copy, PartialEq, Drop)]
pub struct TimeDelta {
    pub(crate) secs: i64,
}

impl I64CheckedMul of CheckedMul<i64> {
    fn checked_mul(self: i64, v: i64) -> Option<i64> {
        let wide_result: i128 = self.into() * v.into();
        Some(wide_result.try_into()?)
    }
}

#[generate_trait]
pub impl TimeDeltaImpl of TimeDeltaTrait {
    /// Makes a new `TimeDelta` with given number of seconds and nanoseconds.
    ///
    /// # Errors
    ///
    /// Returns `None` when the duration is out of bounds, or if `nanos` ≥ 1,000,000,000.
    fn new(secs: i64) -> Option<TimeDelta> {
        if secs < Self::MIN.secs || secs > Self::MAX.secs {
            return None;
        }
        Some(TimeDelta { secs })
    }

    /// Makes a new `TimeDelta` with the given number of weeks.
    ///
    /// Equivalent to `TimeDelta::seconds(weeks * 7 * 24 * 60 * 60)` with
    /// overflow checks.
    ///
    /// # Panics
    ///
    /// Panics when the duration is out of bounds.
    #[inline]
    fn weeks(weeks: i64) -> TimeDelta {
        Self::try_weeks(weeks).expect('TimeDelta::weeks out of bounds')
    }

    /// Makes a new `TimeDelta` with the given number of weeks.
    ///
    /// Equivalent to `TimeDelta::try_seconds(weeks * 7 * 24 * 60 * 60)` with
    /// overflow checks.
    ///
    /// # Errors
    ///
    /// Returns `None` when the `TimeDelta` would be out of bounds.
    #[inline]
    fn try_weeks(weeks: i64) -> Option<TimeDelta> {
        Self::try_seconds(weeks.checked_mul(SECS_PER_WEEK)?)
    }

    /// Makes a new `TimeDelta` with the given number of days.
    ///
    /// Equivalent to `TimeDelta::seconds(days * 24 * 60 * 60)` with overflow
    /// checks.
    ///
    /// # Panics
    ///
    /// Panics when the `TimeDelta` would be out of bounds.
    #[inline]
    fn days(days: i64) -> TimeDelta {
        Self::try_days(days).expect('TimeDelta::days out of bounds')
    }

    /// Makes a new `TimeDelta` with the given number of days.
    ///
    /// Equivalent to `TimeDelta::try_seconds(days * 24 * 60 * 60)` with overflow
    /// checks.
    ///
    /// # Errors
    ///
    /// Returns `None` when the `TimeDelta` would be out of bounds.
    #[inline]
    fn try_days(days: i64) -> Option<TimeDelta> {
        Self::try_seconds(days.checked_mul(SECS_PER_DAY)?)
    }

    /// Makes a new `TimeDelta` with the given number of hours.
    ///
    /// Equivalent to `TimeDelta::seconds(hours * 60 * 60)` with overflow checks.
    ///
    /// # Panics
    ///
    /// Panics when the `TimeDelta` would be out of bounds.
    #[inline]
    fn hours(hours: i64) -> TimeDelta {
        Self::try_hours(hours).expect('TimeDelta::hours out of bounds')
    }

    /// Makes a new `TimeDelta` with the given number of hours.
    ///
    /// Equivalent to `TimeDelta::try_seconds(hours * 60 * 60)` with overflow checks.
    ///
    /// # Errors
    ///
    /// Returns `None` when the `TimeDelta` would be out of bounds.
    #[inline]
    fn try_hours(hours: i64) -> Option<TimeDelta> {
        Self::try_seconds(hours.checked_mul(SECS_PER_HOUR)?)
    }

    /// Makes a new `TimeDelta` with the given number of minutes.
    ///
    /// Equivalent to `TimeDelta::seconds(minutes * 60)` with overflow checks.
    ///
    /// # Panics
    ///
    /// Panics when the `TimeDelta` would be out of bounds.
    #[inline]
    fn minutes(minutes: i64) -> TimeDelta {
        Self::try_minutes(minutes).expect('TimeDelta::mins out of bounds')
    }

    /// Makes a new `TimeDelta` with the given number of minutes.
    ///
    /// Equivalent to `TimeDelta::try_seconds(minutes * 60)` with overflow checks.
    ///
    /// # Errors
    ///
    /// Returns `None` when the `TimeDelta` would be out of bounds.
    #[inline]
    fn try_minutes(minutes: i64) -> Option<TimeDelta> {
        Self::try_seconds(minutes.checked_mul(SECS_PER_MINUTE)?)
    }

    /// Makes a new `TimeDelta` with the given number of seconds.
    ///
    /// # Panics
    ///
    /// Panics when `seconds` is more than `i64::MAX / 1_000` or less than `-i64::MAX / 1_000`
    /// (in this context, this is the same as `i64::MIN / 1_000` due to rounding).
    #[inline]
    fn seconds(seconds: i64) -> TimeDelta {
        Self::try_seconds(seconds).expect('TimeDelta::secs out of bounds')
    }

    /// Makes a new `TimeDelta` with the given number of seconds.
    ///
    /// # Errors
    ///
    /// Returns `None` when `seconds` is more than `i64::MAX / 1_000` or less than
    /// `-i64::MAX / 1_000` (in this context, this is the same as `i64::MIN / 1_000` due to
    /// rounding).
    #[inline]
    fn try_seconds(seconds: i64) -> Option<TimeDelta> {
        Self::new(seconds)
    }

    /// Returns the total number of whole weeks in the `TimeDelta`.
    #[inline]
    const fn num_weeks(self: TimeDelta) -> i64 {
        self.num_days() / 7
    }

    /// Returns the total number of whole days in the `TimeDelta`.
    #[inline]
    const fn num_days(self: TimeDelta) -> i64 {
        self.num_seconds() / SECS_PER_DAY
    }

    /// Returns the total number of whole hours in the `TimeDelta`.
    #[inline]
    const fn num_hours(self: TimeDelta) -> i64 {
        self.num_seconds() / SECS_PER_HOUR
    }

    /// Returns the total number of whole minutes in the `TimeDelta`.
    #[inline]
    const fn num_minutes(self: TimeDelta) -> i64 {
        self.num_seconds() / SECS_PER_MINUTE
    }

    /// Returns the total number of whole seconds in the `TimeDelta`.
    #[inline]
    const fn num_seconds(self: @TimeDelta) -> i64 {
        *self.secs
    }

    /// Add two `TimeDelta`s, returning `None` if overflow occurred.
    fn checked_add(self: @TimeDelta, rhs: TimeDelta) -> Option<TimeDelta> {
        // No overflow checks here because we stay comfortably within the range of an `i64`.
        // Range checks happen in `TimeDelta::new`.
        Self::new(*self.secs + rhs.secs)
    }

    /// Subtract two `TimeDelta`s, returning `None` if overflow occurred.
    fn checked_sub(self: @TimeDelta, rhs: TimeDelta) -> Option<TimeDelta> {
        // No overflow checks here because we stay comfortably within the range of an `i64`.
        // Range checks happen in `TimeDelta::new`.
        Self::new(*self.secs - rhs.secs)
    }

    /// Multiply a `TimeDelta` with a i32, returning `None` if overflow occurred.
    fn checked_mul(self: @TimeDelta, rhs: i32) -> Option<TimeDelta> {
        // Multiply seconds as i128 to prevent overflow
        let secs: i128 = (*self.secs).into() * rhs.into();
        if secs <= Bounded::<i64>::MIN.into() || secs >= Bounded::<i64>::MAX.into() {
            return None;
        }
        Some(TimeDelta { secs: secs.try_into().unwrap() })
    }

    /// Divide a `TimeDelta` with a i32, returning `None` if dividing by 0.
    fn checked_div(self: @TimeDelta, rhs: i32) -> Option<TimeDelta> {
        if rhs == 0 {
            return None;
        }
        Some(TimeDelta { secs: *self.secs / rhs.into() })
    }

    /// Returns the `TimeDelta` as an absolute (non-negative) value.
    #[inline]
    fn abs(self: @TimeDelta) -> TimeDelta {
        TimeDelta { secs: abs(*self.secs) }
    }

    /// A `TimeDelta` where the stored seconds and nanoseconds are equal to zero.
    #[inline]
    const fn zero() -> TimeDelta {
        TimeDelta { secs: 0 }
    }

    /// Returns `true` if the `TimeDelta` equals `TimeDelta::zero()`.
    #[inline]
    const fn is_zero(self: @TimeDelta) -> bool {
        *self.secs == 0
    }

    /// The minimum possible `TimeDelta`: `-i64::MAX` milliseconds.
    const MIN: TimeDelta = TimeDelta { secs: -Bounded::<i64>::MAX / MILLIS_PER_SEC };

    /// The maximum possible `TimeDelta`: `i64::MAX` milliseconds.
    const MAX: TimeDelta = TimeDelta { secs: Bounded::<i64>::MAX / MILLIS_PER_SEC };
}

impl TimeDeltaDefault of Default<TimeDelta> {
    fn default() -> TimeDelta {
        TimeDeltaTrait::zero()
    }
}

impl TimeDeltaNeg of Neg<TimeDelta> {
    #[inline]
    fn neg(a: TimeDelta) -> TimeDelta {
        TimeDelta { secs: -a.secs }
    }
}

impl TimeDeltaAdd of Add<TimeDelta> {
    fn add(lhs: TimeDelta, rhs: TimeDelta) -> TimeDelta {
        lhs.checked_add(rhs).expect('TimeDelta + TimeDelta overflow')
    }
}

impl TimeDeltaSub of Sub<TimeDelta> {
    fn sub(lhs: TimeDelta, rhs: TimeDelta) -> TimeDelta {
        lhs.checked_sub(rhs).expect('TimeDelta - TimeDelta overflow')
    }
}

impl TimeDeltaPartialOrd of PartialOrd<TimeDelta> {
    #[inline]
    fn lt(lhs: TimeDelta, rhs: TimeDelta) -> bool {
        lhs.secs < rhs.secs
    }
    #[inline]
    fn ge(lhs: TimeDelta, rhs: TimeDelta) -> bool {
        lhs.secs >= rhs.secs
    }
}

impl TimeDeltaDebug of Debug<TimeDelta> {
    /// Format a `TimeDelta` using the [ISO 8601] format
    ///
    /// [ISO 8601]: https://en.wikipedia.org/wiki/ISO_8601#Durations
    fn fmt(self: @TimeDelta, ref f: Formatter) -> Result<(), Error> {
        // technically speaking, negative duration is not valid ISO 8601,
        // but we need to print it anyway.
        let (abs, sign) = if *self.secs < 0 {
            (-*self, '-')
        } else {
            (*self, '')
        };

        if sign == '-' {
            f.buffer.append_byte('-');
        }
        f.buffer.append_byte('P');
        // Plenty of ways to encode an empty string. `P0D` is short and not too strange.
        if abs.secs == 0 {
            return write!(f, "0D");
        }

        write!(f, "T{}", abs.secs)?;

        f.buffer.append_byte('S');
        Result::Ok(())
    }
}

impl TimeDeltaDisplay of Display<TimeDelta> {
    fn fmt(self: @TimeDelta, ref f: Formatter) -> Result<(), Error> {
        Debug::fmt(self, ref f)
    }
}
