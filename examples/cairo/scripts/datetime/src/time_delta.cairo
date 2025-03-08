use core::fmt::{Debug, Display, Error, Formatter};
use core::num::traits::Bounded;
use datetime::utils::abs;

#[derive(Clone, Copy, PartialEq, Drop)]
pub struct TimeDelta {
    secs: i64,
}

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

fn checked_mul(lhs: i64, rhs: i64) -> Option<i64> {
    // TODO needs proper check
    Some(lhs * rhs)
}

#[generate_trait]
pub impl TimeDeltaImpl of TimeDeltaTrait {
    fn new(secs: i64) -> Option<TimeDelta> {
        if secs < Self::MIN.secs || secs > Self::MAX.secs {
            return None;
        }
        Some(TimeDelta { secs })
    }

    fn weeks(weeks: i64) -> TimeDelta {
        Self::try_weeks(weeks).unwrap()
    }

    fn try_weeks(weeks: i64) -> Option<TimeDelta> {
        Self::try_seconds(checked_mul(weeks, SECS_PER_WEEK)?)
    }

    fn days(days: i64) -> TimeDelta {
        Self::try_days(days).unwrap()
    }

    fn try_days(days: i64) -> Option<TimeDelta> {
        Self::try_seconds(checked_mul(days, SECS_PER_DAY)?)
    }

    fn hours(hours: i64) -> TimeDelta {
        Self::try_hours(hours).unwrap()
    }

    fn try_hours(hours: i64) -> Option<TimeDelta> {
        Self::try_seconds(checked_mul(hours, SECS_PER_HOUR)?)
    }

    fn minutes(minutes: i64) -> TimeDelta {
        Self::try_minutes(minutes).unwrap()
    }

    fn try_minutes(minutes: i64) -> Option<TimeDelta> {
        Self::try_seconds(checked_mul(minutes, SECS_PER_MINUTE)?)
    }

    fn seconds(seconds: i64) -> TimeDelta {
        Self::try_seconds(seconds).unwrap()
    }

    fn try_seconds(seconds: i64) -> Option<TimeDelta> {
        Self::new(seconds)
    }

    fn num_weeks(self: TimeDelta) -> i64 {
        self.num_days() / 7
    }

    fn num_days(self: TimeDelta) -> i64 {
        self.num_seconds() / SECS_PER_DAY
    }

    fn num_hours(self: TimeDelta) -> i64 {
        self.num_seconds() / SECS_PER_HOUR
    }

    fn num_minutes(self: TimeDelta) -> i64 {
        self.num_seconds() / SECS_PER_MINUTE
    }

    fn num_seconds(self: @TimeDelta) -> i64 {
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

    /// Returns the `TimeDelta` as an absolute (non-negative) value.
    fn abs(self: @TimeDelta) -> TimeDelta {
        TimeDelta { secs: abs(*self.secs) }
    }

    fn zero() -> TimeDelta {
        TimeDelta { secs: 0 }
    }

    const MIN: TimeDelta = TimeDelta { secs: -Bounded::<i64>::MAX / MILLIS_PER_SEC };

    const MAX: TimeDelta = TimeDelta { secs: Bounded::<i64>::MAX / MILLIS_PER_SEC };
}

impl TimeDeltaDefault of Default<TimeDelta> {
    fn default() -> TimeDelta {
        TimeDeltaTrait::zero()
    }
}

impl TimeDeltaNeg of Neg<TimeDelta> {
    fn neg(a: TimeDelta) -> TimeDelta {
        TimeDelta { secs: -a.secs }
    }
}

impl TimeDeltaAdd of Add<TimeDelta> {
    fn add(lhs: TimeDelta, rhs: TimeDelta) -> TimeDelta {
        lhs.checked_add(rhs).unwrap()
    }
}

impl TimeDeltaSub of Sub<TimeDelta> {
    fn sub(lhs: TimeDelta, rhs: TimeDelta) -> TimeDelta {
        lhs.checked_sub(rhs).unwrap()
    }
}

impl TimeDeltaPartialOrd of PartialOrd<TimeDelta> {
    fn lt(lhs: TimeDelta, rhs: TimeDelta) -> bool {
        lhs.secs < rhs.secs
    }
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
